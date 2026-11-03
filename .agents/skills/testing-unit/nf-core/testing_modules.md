---
title: Testing
subtitle: Test modules
markdownPlugin: addNumbersToHeadings
shortTitle: Testing
weight: 8
---

The keywords "MUST", "MUST NOT", "SHOULD", etc. are to be interpreted as described in [RFC 2119](https://tools.ietf.org/html/rfc2119).

## Snapshots

Use only one snapshot per module test, which SHOULD contain all assertions present in this test.
Having multiple snapshots per test will make the snapshot file less readable.

The snapshot SHOULD include all output channels for each test, or at a minimum, it MUST contain some verification that the file exists.

By default, the `then` block of a test should contain this:

```groovy
assert snapshot(process.out).match()
```

This includes the named `versions_<tool>` outputs. Tests that select individual outputs MUST
include those version outputs rather than assume `process.out.versions` exists.

When the snapshot is unstable, use another way to test the output files.
See [nf-test assertions](/docs/contributing/nf-test/assertions) for examples on how to do this.

## GPU tests

Modules that support both CPU and GPU modes SHOULD include a separate GPU test file (`main.gpu.nf.test`).
GPU-only modules MAY use a single test file.

GPU tests MUST be tagged with `"gpu"` or `"gpu_highmem"` so the GPU CI workflow discovers and runs them on GPU-enabled runners.
GPU tests SHOULD include a `nextflow.gpu.config` that sets `accelerator = 1` on the process.
GPU tests SHOULD use the same assertions as the CPU tests to verify that GPU and CPU modes produce equivalent results, and SHOULD include both a real test and a stub test.

For runner instance types, the GPU concurrency caveat under Singularity, and a worked example, see the [GPU-capable modules](/docs/developing/components/gpu-modules) guide.

## Stub tests

A stub test MUST be included for the module.

## Tags

Tags MUST be specified for any dependent modules to ensure changes to upstream modules will re-trigger tests for the current module.

```groovy
tag "modules"
tag "modules_nfcore"
tag "<tool>"
tag "<tool>/<subtool>" // Only if there is a subtool
tag "<dependent-tool>/<dependent-subtool>" // Only if there is a tool this module depends on
```

## `assertAll()`

Use the `assertAll()` function to specify an assertion, and there MUST be a minimum of one success assertion and versions in the snapshot.

## Assert each type of input and output

Include a test and assertions for each type of input and output.

Use [different assertion types](/docs/contributing/nf-test/assertions) if a straightforward `process.out` snapshot is not feasible.

:::tip
Always check the snapshot to ensure that all outputs are correct!
For example, make sure there are no md5sums representing empty files (with the exception of stub tests!).
:::

## Test names

Test names SHOULD describe the test dataset and configuration used. some examples below:

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


## Configuration of ext.args in tests

Module nf-tests SHOULD use a single `nextflow.config` to supply `ext.args` to a module.
Give `module_args` a default in the config's `params` scope, and apply the config to each test individually rather than once at the top of the file, so a test can override the default in its own `params` block when it needs to:

```groovy {1-3,7} title="nextflow.config"
params {
  module_args = ''
}

process {
  withName: 'MODULE' {
    ext.args = params.module_args
  }
}
```

No other settings should go into this file.

```groovy {2,4-6,19} title="main.nf.test"
test("my_tool - custom args") {
  config './nextflow.config'
  when {
    params {
      module_args = '--extra_opt1 --extra_opt2'
    }
    process {
      """
      input[0] = [
        [ id:'test1', single_end:false ], // meta map
        file(params.modules_testdata_base_path + 'genomics/prokaryotes/bacteroides_fragilis/genome/genome.fna.gz', checkIfExists: true)
      ]
      """
    }
  }
}

test("my_tool - stub") {
  config './nextflow.config'
  options '-stub'
  when {
    process {
      """
      input[0] = [
        [ id:'test1', single_end:false ], // meta map
        file(params.modules_testdata_base_path + 'genomics/prokaryotes/bacteroides_fragilis/genome/genome.fna.gz', checkIfExists: true)
      ]
      """
    }
  }
}
```

Because `module_args` already has a default in the config, tests that don't need custom args (like the stub test above) don't need to repeat `module_args = ''` — they inherit the default as soon as they apply `config './nextflow.config'`.

:::info
Modules in pipelines are frequently configured with dynamic inputs. Test parameters do not support this. For example,

```groovy {3-4} title="nextflow.config"
process {
  withName: 'MODULE' {
    ext.args = { "--sample ${meta.id}" }
    ext.prefix = { "${meta.id}_prefix" }
  }
}
```

would be implemented as follows:

```groovy {2,4-6} title="main.nf.test"
test("my_tool - dynamic args") {
  config './nextflow.config'
  when {
    params {
      module_args = '--sample test1' // `meta.id` is replaced with the value it would take once dynamically resolved
    }
    process {
      """
      input[0] = [
        [ id:'test1', single_end:false ], // meta map
        file(params.modules_testdata_base_path + 'genomics/prokaryotes/bacteroides_fragilis/genome/genome.fna.gz', checkIfExists: true)
      ]
      """
    }
  }
}
```

```groovy {1-3,6} title="nextflow.config"
params {
  module_args = ''
}
process {
  withName: 'MODULE' {
    ext.args = params.module_args
    ext.prefix = { "${meta.id}_prefix" } // Dynamic prefix configuration remains in the config
  }
}
```

:::

