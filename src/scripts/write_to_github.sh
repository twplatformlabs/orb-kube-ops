#!/usr/bin/env bash
set -euo pipefail

# src/scripts/write_to_github.sh
#
# Expects the following ENV values to exist
#   $SOURCE          - Comma-delimited path pattern(s), e.g. "myfolder/*.yaml"
#   $DESTINATION     - Destination folder in the repo, e.g. "configs" or "." for root
#   $REPOSITORY_URL  - GitHub repo as owner/name, e.g. "myorg/myrepo"
#   $BRANCH          - Target branch, e.g. "main"
#   $COMMITMESSAGE  - Commit message, e.g. "chore: update configs"
#   GITHUB_TOKEN     - GitHub personal access token (must be set before running)

GITHUB_API="https://api.github.com"

# -----------------------------------------------------------------------------
# list_files
#   Lists all files matching one or more comma-delimited path patterns.
#
# Arguments:
#   $1 - Comma-delimited list of path patterns (wildcards supported)
#
# Returns:
#   0 if at least one file was found, 1 otherwise.
# -----------------------------------------------------------------------------
list_files() {
    local input="$1"
    local found=0
    local pattern dir glob results

    IFS=',' read -ra patterns <<< "$input"

    for pattern in "${patterns[@]}"; do
        # Trim leading/trailing whitespace
        pattern="${pattern#"${pattern%%[![:space:]]*}"}"
        pattern="${pattern%"${pattern##*[![:space:]]}"}"

        dir=$(dirname "$pattern")
        glob=$(basename "$pattern")

        if [[ ! -d "$dir" ]]; then
            echo "Warning: directory not found: $dir" >&2
            continue
        fi

        results=$(find "$dir" -maxdepth 1 -type f -name "$glob" | sort)

        if [[ -z "$results" ]]; then
            echo "Warning: no files found matching: $pattern" >&2
            continue
        fi

        echo "$results"
        ((found++)) || true
    done

    if [[ $found -eq 0 ]]; then
        echo "No files found for any of the provided patterns." >&2
        return 1
    fi
}

# -----------------------------------------------------------------------------
# github_api
#   Wrapper for authenticated GitHub API calls.
#
# Arguments:
#   $1 - HTTP method (GET, POST, PATCH)
#   $2 - API path (e.g. /repos/owner/name/git/refs/heads/main)
#   $3 - (Optional) JSON request body
# -----------------------------------------------------------------------------
github_api() {
    local method="$1" path="$2" body="${3:-}"
    local out http
    out=$(curl --silent --show-error \
        --write-out '\n%{http_code}' \
        --request "$method" \
        --header "Authorization: Bearer ${GITHUB_TOKEN}" \
        --header "Accept: application/vnd.github+json" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        --header "Content-Type: application/json" \
        ${body:+--data "$body"} \
        "${GITHUB_API}${path}")
    http="${out##*$'\n'}"     # last line = status code
    out="${out%$'\n'*}"       # everything before = body
    if [[ "$http" -ge 400 ]]; then
        echo "GitHub API ${method} ${path} -> HTTP ${http}" >&2
        echo "$out" >&2
        return 1
    fi
    echo "$out"
}
# github_api() {
#     local method="$1"
#     local path="$2"
#     local body="${3:-}"

#     local response
#     response=$(curl --silent --fail-with-body --show-error \
#         --request "$method" \
#         --header "Authorization: Bearer ${GITHUB_TOKEN}" \
#         --header "Accept: application/vnd.github+json" \
#         --header "X-GitHub-Api-Version: 2022-11-28" \
#         --header "Content-Type: application/json" \
#         ${body:+--data "$body"} \
#         "${GITHUB_API}${path}")

#     echo "$response"
# }

# -----------------------------------------------------------------------------
# create_blob
#   Uploads a single file's content to GitHub as a blob.
#
# Arguments:
#   $1 - Local file path
#
# Output:
#   The blob SHA returned by GitHub.
# -----------------------------------------------------------------------------
create_blob() {
    local file="$1"
    local content
    content=$(base64 < "$file" | tr -d '\n')

    local response
    response=$(github_api POST "/repos/${GITHUB_REPO}/git/blobs" \
        "{\"content\": \"${content}\", \"encoding\": \"base64\"}")

    echo "$response" | jq -r '.sha'
}

# -----------------------------------------------------------------------------
# commit_files_to_github
#   Creates a single GitHub commit containing all source→destination file pairs.
#
# Arguments:
#   $1 - Source pattern(s), comma-delimited
#   $2 - Destination folder in the GitHub repo
#   $3 - Commit message
# -----------------------------------------------------------------------------
commit_files_to_github() {
    local source_pattern="$1"
    local dest_folder="$2"
    local commit_message="$3"

    # Step 1 — Generate source file list
    echo "Resolving source files..." >&2
    local source_files
    source_files=$(list_files "$source_pattern") || return 1
    local source_files_count
    source_files_count=$(echo "$source_files" | wc -l | tr -d ' ')
    echo "  Found ${source_files_count} file(s)" >&2

    # Step 2 — Get the SHA of the latest commit on the target branch
    echo "Fetching latest commit SHA from '${GITHUB_BRANCH}'..." >&2
    local ref_response
    ref_response=$(github_api GET "/repos/${GITHUB_REPO}/git/refs/heads/${GITHUB_BRANCH}")
    local base_commit_sha
    base_commit_sha=$(echo "$ref_response" | jq -r '.object.sha')
    echo "  Base commit: ${base_commit_sha}" >&2

    # Step 3 — Get the tree SHA from the base commit
    local commit_response
    commit_response=$(github_api GET "/repos/${GITHUB_REPO}/git/commits/${base_commit_sha}")
    local base_tree_sha
    base_tree_sha=$(echo "$commit_response" | jq -r '.tree.sha')
    echo "  Base tree:   ${base_tree_sha}" >&2

    # Step 4 — Create a blob for each file and build the tree entries JSON
    echo "Uploading file blobs..." >&2
    local tree_entries="["
    local first=true

    while IFS= read -r source_file; do
        local filename
        filename=$(basename "$source_file")

        local dest_path
        if [[ "$dest_folder" == "." ]]; then
            dest_path="$filename"
        else
            dest_path="${dest_folder}/${filename}"
        fi

        echo "  Uploading: ${source_file} -> ${dest_path}" >&2
        local blob_sha
        blob_sha=$(create_blob "$source_file")

        if [[ "$first" == true ]]; then
            first=false
        else
            tree_entries+=","
        fi

        tree_entries+="{\"path\": \"${dest_path}\", \"mode\": \"100644\", \"type\": \"blob\", \"sha\": \"${blob_sha}\"}"
    done <<< "$source_files"

    tree_entries+="]"

    # Step 5 — Create a new tree
    echo "Creating tree..." >&2
    local tree_response
    tree_response=$(github_api POST "/repos/${GITHUB_REPO}/git/trees" \
        "{\"base_tree\": \"${base_tree_sha}\", \"tree\": ${tree_entries}}")
    local new_tree_sha
    new_tree_sha=$(echo "$tree_response" | jq -r '.sha')
    echo "  New tree: ${new_tree_sha}" >&2

    # Step 6 — Create the commit
    echo "Creating commit..." >&2
    local commit_body
    commit_body=$(printf '{"message": "%s", "tree": "%s", "parents": ["%s"]}' \
        "$commit_message" "$new_tree_sha" "$base_commit_sha")
    local new_commit_response
    new_commit_response=$(github_api POST "/repos/${GITHUB_REPO}/git/commits" "$commit_body")
    local new_commit_sha
    new_commit_sha=$(echo "$new_commit_response" | jq -r '.sha')
    echo "  New commit: ${new_commit_sha}" >&2

    # Step 7 — Update the branch ref to point to the new commit
    echo "Updating branch ref..." >&2
    github_api PATCH "/repos/${GITHUB_REPO}/git/refs/heads/${GITHUB_BRANCH}" \
        "{\"sha\": \"${new_commit_sha}\"}" > /dev/null

    echo "" >&2
    echo "Done! Committed ${source_files_count} file(s) to ${GITHUB_REPO}@${GITHUB_BRANCH}" >&2
    echo "Commit SHA: ${new_commit_sha}" >&2
}

# -----------------------------------------------------------------------------
# Main
#
# Parameters (all positional, all required except commit_message):
#   $1 - Source pattern(s), comma-delimited (e.g. "myfolder/*.yaml")
#   $2 - Destination folder in the GitHub repo (e.g. "configs" or "." for root)
#   $3 - GitHub repo in "owner/name" format (e.g. "myorg/myrepo")
#   $4 - GitHub branch (e.g. "main")
#   $5 - Commit message (e.g. "chore: update configs")
#
# Environment (must be set before running):
#   GITHUB_TOKEN - GitHub personal access token
# -----------------------------------------------------------------------------
main() {
    local errors=0

    if [[ -z "${SOURCE:-}" ]]; then
        echo "Error: SOURCE is not set. Comma-delimited path pattern(s), e.g. \"myfolder/*.yaml\"" >&2
        ((errors++)) || true
    fi
    if [[ -z "${DESTINATION:-}" ]]; then
        echo "Error: DESTINATION is not set. Destination folder in the repo, e.g. \"configs\" or \".\" for root" >&2
        ((errors++)) || true
    fi
    if [[ -z "${REPOSITORY_URL:-}" ]]; then
        echo "Error: REPOSITORY_URL is not set. GitHub repo as owner/name, e.g. \"myorg/myrepo\"" >&2
        ((errors++)) || true
    fi
    if [[ -z "${BRANCH:-}" ]]; then
        echo "Error: BRANCH is not set. Target branch, e.g. \"main\"" >&2
        ((errors++)) || true
    fi
    if [[ -z "${COMMITMESSAGE:-}" ]]; then
        echo "Error: COMMITMESSAGE is not set. Commit message, e.g. \"chore: update configs\"" >&2
        ((errors++)) || true
    fi
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        echo "Error: GITHUB_TOKEN is not set. GitHub personal access token." >&2
        ((errors++)) || true
    fi

    if [[ $errors -gt 0 ]]; then
        exit 1
    fi

    local source_pattern="$SOURCE"
    local dest_folder="$DESTINATION"
    GITHUB_REPO="$REPOSITORY_URL"
    GITHUB_BRANCH="$BRANCH"
    local commit_message
    commit_message=$(eval echo "$COMMITMESSAGE")

    echo "Source: ${source_pattern}" >&2
    echo "Destination: ${dest_folder}" >&2
    echo "GitHub repo: ${GITHUB_REPO}" >&2
    echo "GitHub branch: ${GITHUB_BRANCH}" >&2
    echo "Commit message: ${commit_message}" >&2

    echo "CIRCLE_JOB: ${CIRCLE_JOB:-NOT SET}" >&2
    echo "CIRCLE_BUILD_URL: ${CIRCLE_BUILD_URL:-NOT SET}" >&2
    
    commit_files_to_github "$source_pattern" "$dest_folder" "$commit_message"
}

main "$@"