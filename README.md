<div align="center">
	<p>
		<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/thoughtworks_flamingo_wave.png?sanitize=true" width=200 />
    <br />
		<img alt="DPS Title" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/dps_lab_title.png" width=350/>
	</p>
  <h3>orb-kube-ops</h3>
  <h5>a workflow orb for typical kubernetes operational pipelines</h5>
  <a href="https://app.circleci.com/pipelines/github/ThoughtWorks-DPS/orb-kube-ops"><img src="https://circleci.com/gh/ThoughtWorks-DPS/orb-kube-ops.svg?style=shield"></a> <a href="https://circleci.com/orbs/registry/orb/ThoughtWorks-DPS/orb-kube-ops"><img src="https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/ThoughtWorks-DPS/orb-kube-ops"></a><a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</div>
<br />

Works in conjunction with the twdps/circleci-kube-ops executor.  

The twdps/circleci-kube-ops executor is configured to support most common kubernetes operational tasks. This orb work in conjunction with that executor and enables users of the executor to override packages versions at run time with the goal of allowing pipelines to either delay upgrades to fit their schedule or adopt newer versions before they are available in the executor.  

See [orb registry](https://circleci.com/orbs/registry/orb/twdps/kube-ops) for usage examples and release history.
