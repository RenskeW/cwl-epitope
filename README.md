# CWL workflow for epitope prediction

## What does this workflow do?
- Label and input feature generation for epitope prediction model
- Train and test epitope prediction model, which is based on OPUS-TASS and multitask-PPI-prediction model.

### Overview of workflow components:
- `ro_full_wf/`: a RO of a (test) workflow run
- `tools/`: CommandLineTool descriptions for each step in the workflow.
- `tests/`: Tests and test data for part of the steps.
- `requirements.txt`: Installed software on which original workflow run was enacted
- `niaa_wf.cwl`: Epitope prediction workflow in CWL
- `niaa_abstract.cwl`: Abstract workflow, originally only contained abstract Operations for the steps.
- `niaa_wf_job.yml`: Input parameter file for `niaa_wf.cwl`
- `niaa_real_graph.svg`: Graph of `niaa_wf.cwl`
- `niaa_abstract_graph.svg`: Graph of `niaa_abstract.cwl`

## What (software) does it need to run?
- A CWL engine, e.g. cwltool (at this moment the only CWL runner with an implementation of CWLProv)
- Underlying software for the CWL CommandLineTools (possibly specified in SoftwareRequirement)
- Optional: Docker, Singularity or Podman (the software containers that are supported by cwltool)

## How do you install it?
- Clone this repository
- Install cwltool and other required software (e.g. graphviz + software that is part of the workflow itself)

## How do you use it?
- Workflow description: `niaa_wf.cwl`
- Parameter file: `niaa_wf_job.yml`
- Run the workflow: `cwltool niaa_wf.cwl niaa_wf_job.yml`
- To run + generate a research object: `cwltool --provenance ./ro niaa_wf.cwl niaa_wf_job.yml`
- To run and cache intermediate output (rerun will use cached results): `cwltool --cachedir ./cache niaa_wf.cwl niaa_wf_job.yml`
- Workflow plan (yellow steps = implemented, dashed = not implemented yet): `niaa_abstract_graph.svg` (generated from `niaa_abstract.cwl`)
- Generate a workflow graph: `cwltool --print-dot <workflow>.cwl | dot -Tsvg > <graph>.svg`

## Attribution and contact details
- OPUS-TASS repository: https://github.com/thuxugang/opus_tass
- IBIVU multi-task PPI prediction model: https://github.com/ibivu/multi-task-PPI

## License
- Apache-2.0

## Help and support
- CWL user guide: https://www.commonwl.org/user_guide/
- CWL tool repository: https://github.com/common-workflow-library/bio-cwl-tools
- Ask CWL-related questions: https://matrix.to/#/#common-workflow-language_common-workflow-language:gitter.im
- cwltool repository: https://github.com/common-workflow-language/cwltool
- official CWL example repository: https://github.com/common-workflow-library/cwl-patterns
- custom cwl-example repository: https://github.com/RenskeW/cwl-examples

## Common errors and troubleshooting
Sometimes tool descriptions work when run as separate files but give an error when connected in a workflow. Possible solutions:
- Error: "anonymous file object missing 'basename' and 'contents'? fields" --> When using default values for file inputs in the CWL tool description, change `path` into `location`. `path` is technically correct but gives an error when the tool is run as a step in a workflow. 
- Error: no input ports found for step ... / step ... has no output X". When step gives an error when connected in a workflow even though the tool run by itself works properly, comment the `DockerRequirement` and `SoftwareRequirement` fields, save the CommandLineTool description, save the workflow document. The errors should disappear. Now you can uncomment the `DockerRequirement` and `SoftwareRequirement` fields again and save the CommandLineTool document. Repeat if error resurfaces.
- Error: I'm sorry, I couldn't load this CWL file, try again with --debug for more information.
The error was: cwltool requires Node.js engine to evaluate and validate Javascript expressions, but couldn't find it.  Tried nodejs, node, docker run node:slim --> **Solution**: run workflow with `--singularity`  
