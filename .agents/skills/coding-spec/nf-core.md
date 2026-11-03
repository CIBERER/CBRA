Before changing an nf-core component, load the specifications relevant to its type and the
aspects being changed. For a module, start with General, Naming conventions, and Input/output
options; also load Documentation, Module parameters, Resource requirements, Software requirements,
and Testing when the change affects those concerns. For a subworkflow, start with General, Naming
conventions, and Input/output options; also load Subworkflow parameters, Documentation, and Testing
when applicable.

## Module specifications

The following specifications define standards for developing nf-core modules:

- **[General](./modules/general.md):** Foundation for module development including input/output handling, `ext.args`, multi-tool piping, compression, version emission, and script templating.
- **[Naming conventions](./modules/naming-conventions.md):** Standards for naming module files, processes, parameters, functions, channels, and outputs.
- **[Input/output options](./modules/input-output-options.md):** Guidelines for defining input channels, output emissions, and handling optional inputs and outputs.
- **[Documentation](./modules/documentation.md):** Requirements for `meta.yml` files including tool descriptions, keywords, and ontology integration.
- **[Module parameters](./modules/module-parameters.md):** Guidelines for parameter usage ensuring modules remain flexible and reusable across different pipeline contexts.
- **[Resource requirements](./modules/resource-requirements.md):** Standards for specifying computational resources through process labels and the `task` directive.
- **[Software requirements](./modules/software-requirements.md):** Guidelines for declaring software dependencies using Conda, Docker, and Singularity through BioContainers.
- **[Testing](./modules/testing.md):** Requirements for nf-test including snapshot testing, stub tests, and CI configuration.

## Subworkflow specifications

The following specifications define standards for developing nf-core subworkflows:

- **[General](./subworkflows/general.md):** Foundation for subworkflow development including minimum subworkflow size and version reporting through topics.
- **[Naming conventions](./subworkflows/naming-conventions.md):** Standards for naming subworkflow files, parameters, functions, channels, and input/output structures.
- **[Input/output options](./subworkflows/input-output-options.md):** Guidelines for defining required input and output channels, and handling optional inputs.
- **[Subworkflow parameters](./subworkflows/subworkflow-parameters.md):** Guidelines for parameter usage ensuring subworkflows remain flexible and reusable across different pipeline contexts.
- **[Documentation](./subworkflows/documentation.md):** Requirements for documenting channel structures in code comments and `meta.yml` files.
- **[Testing](./subworkflows/testing.md):** Requirements for nf-test including scope of testing, tags for dependent modules, assertions, and CI configuration.
