#!/usr/bin/env bash
set -euo pipefail

# src/scripts/write_to_github.sh
#
# Expects the following ENV values to exist
#   $SOURCE          - Comma-delimited path pattern(s), e.g. "myfolder/*.yaml"
#   $DESTINATION     - Destination folder in the repo, e.g. "configs" or "." for root
#   $REPOSITORY_URL  - GitHub repo as owner/name, e.g. "myorg/myrepo"
#   $BRANCH          - Target branch, e.g. "main"
#   $COMMITMESSAGE   - Commit message (may reference env vars, e.g. "$CIRCLE_BUILD_URL")
#   GITHUB_TOKEN     - GitHub personal access token (must be set before running)

GITHUB_API="https://api.github.com"

# Populated by github_api() on every call so callers can inspect the HTTP status.
GITHUB_API_STATUS=""

# -----------------------------------------------------------------------------
# github_api
#   Authenticated GitHub API call.
#
#   Prints the response BODY to stdout and records the HTTP status in the global
#   GITHUB_API_STATUS. Returns non-zero on a >=400 status WITHOUT discarding the
#   body, so callers can read GitHub's error message (this is what `--fail` was
#   hiding before).
#
# Arguments:
#   $1 - HTTP method (GET, POST, PATCH)
#   $2 - API path (e.g. /repos/owner/name/git/refs/heads/main)
#   $3 - (Optional) JSON request body
# -----------------------------------------------------------------------------
github_api() {
    local method="$1"
    local path="$2"
    local body="${3:-}"

    local out
    out=$(curl --silent --show-error \
        --write-out '\n%{http_code}' \
        --request "$method" \
        --header "Authorization: Bearer ${GITHUB_TOKEN}" \
        --header "Accept: application/vnd.github+json" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        --header "Content-Type: application/json" \
        ${body:+--data "$body"} \
        "${GITHUB_API}${path}")

    # Last line is the status code (from --write-out); the rest is the body.
    GITHUB_API_STATUS="${out##*$'\n'}"
    out="${out%$'\n'*}"

    printf '%s' "$out"
    [[ "$GITHUB_API_STATUS" -lt 400 ]]
}

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
# create_blob
#   Uploads a single file's content to GitHub as a blob. Content-addressed and
#   independent of branch state, so this only needs to run once per file.
#
# Arguments:
#   $1 - Local file path
#
# Output:
#   The blob SHA returned by GitHub.
# -----------------------------------------------------------------------------
create_blob() {
    local file="$1"
    local content body response
    content=$(base64 < "$file" | tr -d '\n')

    body=$(jq -n --arg content "$content" '{content: $content, encoding: "base64"}')

    response=$(github_api POST "/repos/${GITHUB_REPO}/git/blobs" "$body") || {
        echo "Error: failed to create blob for ${file} (HTTP ${GITHUB_API_STATUS})" >&2
        echo "$response" >&2
        exit 1
    }

    echo "$response" | jq -r '.sha'
}

# -----------------------------------------------------------------------------
# build_tree_entries
#   Creates a blob for each source file and emits the tree-entries JSON array.
#   Runs ONCE; the resulting array is reused across ref-update retries.
#
# Arguments:
#   $1 - Newline-delimited list of source file paths
#   $2 - Destination folder in the repo
#
# Output:
#   A JSON array of tree entries.
# -----------------------------------------------------------------------------
build_tree_entries() {
    local source_files="$1"
    local dest_folder="$2"
    local entries=""

    while IFS= read -r source_file; do
        [[ -z "$source_file" ]] && continue

        local filename dest_path blob_sha entry
        filename=$(basename "$source_file")

        if [[ "$dest_folder" == "." ]]; then
            dest_path="$filename"
        else
            dest_path="${dest_folder}/${filename}"
        fi

        echo "  Uploading: ${source_file} -> ${dest_path}" >&2
        blob_sha=$(create_blob "$source_file")

        entry=$(jq -n \
            --arg path "$dest_path" \
            --arg sha "$blob_sha" \
            '{path: $path, mode: "100644", type: "blob", sha: $sha}')
        entries+="${entry}"$'\n'
    done <<< "$source_files"

    # Slurp the newline-delimited objects into a single JSON array.
    printf '%s' "$entries" | jq -s '.'
}

# -----------------------------------------------------------------------------
# commit_and_push
#   Retryable tree -> commit -> ref-update sequence.
#
#   Each attempt re-reads the LIVE branch tip, rebuilds the tree onto it,
#   creates a commit parented on it, and fast-forwards the ref. If the ref moved
#   between read and update ("Update is not a fast forward"), it rebuilds on the
#   new tip and retries. If the resulting tree matches the base tree, it's a
#   no-op and we skip the commit + ref update entirely.
#
# Arguments:
#   $1 - Tree entries JSON array (from build_tree_entries)
#   $2 - Commit message
#
# Output:
#   The new commit SHA on success (empty on a skipped no-op).
# -----------------------------------------------------------------------------
commit_and_push() {
    local tree_entries="$1"
    local commit_message="$2"
    local attempt=1
    local max_attempts=5

    while (( attempt <= max_attempts )); do
        echo "Commit attempt ${attempt}/${max_attempts}..." >&2

        # 1 — current branch tip
        local ref_response base_commit_sha
        ref_response=$(github_api GET "/repos/${GITHUB_REPO}/git/refs/heads/${GITHUB_BRANCH}") || {
            echo "Error: failed to read ref (HTTP ${GITHUB_API_STATUS})" >&2
            echo "$ref_response" >&2
            return 1
        }
        base_commit_sha=$(echo "$ref_response" | jq -r '.object.sha')
        echo "  Base commit (live ref): ${base_commit_sha}" >&2

        # 2 — tree of that commit
        local commit_response base_tree_sha
        commit_response=$(github_api GET "/repos/${GITHUB_REPO}/git/commits/${base_commit_sha}") || {
            echo "Error: failed to read base commit (HTTP ${GITHUB_API_STATUS})" >&2
            echo "$commit_response" >&2
            return 1
        }
        base_tree_sha=$(echo "$commit_response" | jq -r '.tree.sha')

        # 3 — build new tree on top of the live base tree
        local tree_body tree_response new_tree_sha
        tree_body=$(jq -n \
            --arg base "$base_tree_sha" \
            --argjson tree "$tree_entries" \
            '{base_tree: $base, tree: $tree}')
        tree_response=$(github_api POST "/repos/${GITHUB_REPO}/git/trees" "$tree_body") || {
            echo "Error: failed to create tree (HTTP ${GITHUB_API_STATUS})" >&2
            echo "$tree_response" >&2
            return 1
        }
        new_tree_sha=$(echo "$tree_response" | jq -r '.sha')
        echo "  Base tree: ${base_tree_sha}" >&2
        echo "  New tree:  ${new_tree_sha}" >&2

        # 4 — no-op short circuit (routine: pushed files identical to repo)
        if [[ "$new_tree_sha" == "$base_tree_sha" ]]; then
            echo "  No changes: new tree matches base tree. Skipping commit + ref update." >&2
            return 0
        fi

        # 5 — commit parented on the live tip
        local commit_body new_commit_response new_commit_sha
        commit_body=$(jq -n \
            --arg msg "$commit_message" \
            --arg tree "$new_tree_sha" \
            --arg parent "$base_commit_sha" \
            '{message: $msg, tree: $tree, parents: [$parent]}')
        new_commit_response=$(github_api POST "/repos/${GITHUB_REPO}/git/commits" "$commit_body") || {
            echo "Error: failed to create commit (HTTP ${GITHUB_API_STATUS})" >&2
            echo "$new_commit_response" >&2
            return 1
        }
        new_commit_sha=$(echo "$new_commit_response" | jq -r '.sha')
        echo "  New commit: ${new_commit_sha}" >&2

        # 6 — fast-forward the ref
        local patch_body patch_response
        patch_body=$(jq -n --arg sha "$new_commit_sha" '{sha: $sha}')
        patch_response=$(github_api PATCH \
            "/repos/${GITHUB_REPO}/git/refs/heads/${GITHUB_BRANCH}" \
            "$patch_body") || true

        if [[ "$GITHUB_API_STATUS" -lt 400 ]]; then
            echo "  Ref updated to ${new_commit_sha} on attempt ${attempt}" >&2
            echo "$new_commit_sha"
            return 0
        fi

        # Ref update failed — retry only on a genuine non-fast-forward.
        if echo "$patch_response" | grep -qi "not a fast forward"; then
            echo "  Ref moved (non-fast-forward). Re-reading tip and rebuilding..." >&2
            sleep "$attempt"          # linear backoff: 1s, 2s, 3s, ...
            (( attempt++ ))
            continue
        fi

        echo "Error: ref update failed with HTTP ${GITHUB_API_STATUS}:" >&2
        echo "$patch_response" >&2
        return 1
    done

    echo "Error: ref update kept failing as non-fast-forward after ${max_attempts} attempts." >&2
    echo "       Something is moving '${GITHUB_BRANCH}' faster than this job can fast-forward onto it." >&2
    return 1
}

# -----------------------------------------------------------------------------
# commit_files_to_github
#   Resolves source files, uploads them once as blobs, then commits + pushes
#   with retry.
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

    echo "Resolving source files..." >&2
    local source_files
    source_files=$(list_files "$source_pattern") || return 1
    local source_files_count
    source_files_count=$(echo "$source_files" | grep -c . || true)
    echo "  Found ${source_files_count} file(s)" >&2

    echo "Uploading file blobs..." >&2
    local tree_entries
    tree_entries=$(build_tree_entries "$source_files" "$dest_folder")

    local new_commit_sha
    new_commit_sha=$(commit_and_push "$tree_entries" "$commit_message") || return 1

    echo "" >&2
    if [[ -n "$new_commit_sha" ]]; then
        echo "Done! Committed ${source_files_count} file(s) to ${GITHUB_REPO}@${GITHUB_BRANCH}" >&2
        echo "Commit SHA: ${new_commit_sha}" >&2
    else
        echo "Done! No changes to commit for ${GITHUB_REPO}@${GITHUB_BRANCH}" >&2
    fi
}

# -----------------------------------------------------------------------------
# Main
#
# Environment (must be set before running):
#   SOURCE, DESTINATION, REPOSITORY_URL, BRANCH, COMMITMESSAGE, GITHUB_TOKEN
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

    # Expand env-var references in the message (e.g. $CIRCLE_BUILD_URL) WITHOUT
    # the command-execution risk of `eval`. envsubst only substitutes variables;
    # it will not run $(...) or backticks. Falls back to eval if unavailable.
    local commit_message
    if command -v envsubst >/dev/null 2>&1; then
        commit_message=$(printf '%s' "$COMMITMESSAGE" | envsubst)
    else
        commit_message=$(eval echo "$COMMITMESSAGE")
    fi

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