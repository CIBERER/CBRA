---
title: Testing
subtitle: Test subworkflows
weight: 6
---

The keywords "MUST", "MUST NOT", "SHOULD", etc. are to be interpreted as described in [RFC 2119](https://tools.ietf.org/html/rfc2119).


## All output channels must be tested

All output channels SHOULD be included in the nf-test snapshot file, or at a minimum, the files MUST be verified to exist.

## Tags

Tags MUST be specified for any dependent modules to ensure changes to upstream modules re-trigger tests for the subworkflow.

```groovy
tag "subworkflows"
tag "subworkflows_nfcore"
tag "<subworkflow-name>"
tag "<tool>" // Add each tool as a separate tag
tag "<tool>/<subtool>" // Add each subtool as a separate tag
```

## `assertAll()`

The `assertAll()` function MUST be used to specify an assertion, and at least one success assertion and versions MUST be included in the snapshot.

For topic-based modules, declare `topics "versions"` in the nf-test workflow test and include
`topics.versions` alongside `workflow.out` in the snapshot. Do not assume `workflow.out.versions`
exists. See [nf-test topic assertions](https://www.nf-test.com/docs/testcases/nextflow_workflow/#topic-channels).

## Assert each type of input and output

A test and assertions SHOULD be written for each type of input and output.

Use [different assertion types](/docs/contributing/nf-test/assertions) if a straightforward `workflow.out` snapshot is not feasible.

:::tip
Always check the snapshot to ensure that all outputs are correct!
For exmaple, make sure there are no md5sums representing empty files.
:::

## Test names

Test names SHOULD describe the test dataset and configuration.
For example:

```groovy
test("homo_sapiens - [fastq1, fastq2] - bam")
test("sarscov2 - [ cram, crai ] - fasta - fai")
test("Should search for zipped protein hits against a DIAMOND db and return a tab separated output file of hits")
```

## Input data

Test inputs SHOULD use their original reproducible source locations rather than local copies created during reference generation or validation. Recover the original source location recorded in the implementation plan or fixture provenance when available.

For data from nf-core, reference the original remote path through the repository test-data parameter, such as modules_testdata_base_path:
```groovy
file(params.modules_testdata_base_path + 'genomics/sarscov2/illumina/bam/test.paired_end.sorted.bam', checkIfExists: true)
```

Use a local path only when no reproducible original source location is available, or when the file is an intentionally local derived prerequisite or repository-owned fixture.

## Configuration

Subworkflow nf-tests SHOULD use a single `nextflow.config` to supply `ext.args` to a subworkflow.
Define them in the `when` block of a test under the `params` scope.

```groovy {4-7} title="main.nf.test"
config './nextflow.config'

when {
  params {
    moduleA_args = '--extra_opt1 --extra_opt2'
    moduleB_args = '--extra_optX'
  }
  workflow {
    """
    input[0] = [
      [ id:'test1', single_end:false ], // meta map
      file(params.modules_testdata_base_path + 'genomics/prokaryotes/bacteroides_fragilis/genome/genome.fna.gz', checkIfExists: true)
    ]
    """
  }
}
```

```groovy {3,6} title="nextflow.config"
process {
  withName: 'MODULEA' {
    ext.args = params.moduleA_args
  }
  withName: 'MODULEB' {
    ext.args = params.moduleB_args
  }
}
```

Do not add other settings to this file.

:::tip
Supply the config only to the tests that use `params`, otherwise define `params` for every test including the stub test.
:::

