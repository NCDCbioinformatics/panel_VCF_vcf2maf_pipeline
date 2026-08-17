# panel_VCF_vcf2maf_pipeline

VCF preprocessing, genome-build handling, and VCF-to-MAF conversion component
of the CURE-NGS panel harmonization framework.

> **Supported deployment:** reviewers and new users should install the unified
> [CURE-NGS Docker/OCI distribution](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework).
> This repository preserves the historical component source and releases. It is
> expected to show **No packages published** because the single container
> package is built and published from the umbrella repository.

## Role in the unified project

| Item | Value |
| --- | --- |
| Historical responsibility | Panel VCF sanitation, assembly harmonization, and vcf2maf execution |
| Supported commands | `cure-ngs inspect-vcf`, `normalize-vcf`, and `vcf-to-maf` |
| Latest audited component release | `NCDC_batch_vcf2maf_V.1.3.3_github` |
| Canonical installation | `NCDCbioinformatics/cure-ngs-panel-harmonization-framework` |

## Install the supported Docker distribution

1. Install [Docker Desktop](https://docs.docker.com/desktop/) on Windows/macOS
   or [Docker Engine](https://docs.docker.com/engine/install/) on Linux.
2. Confirm that Docker is running with `docker version`.
3. Build the current audited source:

```bash
git clone https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework.git
cd cure-ngs-panel-harmonization-framework
docker build --file docker/Dockerfile --tag cure-ngs-harmonizer:0.1.0 .
```

After release `0.1.0` appears in the umbrella repository's **Packages** panel,
the source build can be replaced with:

```bash
docker pull ghcr.io/ncdcbioinformatics/cure-ngs-harmonizer:0.1.0
```

If GitHub still says `No packages published`, use the source-build command.

## Verify and run this capability

Run the network-free six-component reviewer test:

```bash
bash scripts/run_reviewer_demo.sh
```

For a real GRCh37 VCF-to-MAF run, mount input, output, hg19 FASTA/FAI, and a
VEP 116 GRCh37 cache:

```bash
mkdir -p output
chmod 0777 output  # Linux: writable by the image's non-root UID 10001
docker run --rm \
  --volume "$PWD/input:/data/input:ro" \
  --volume "$PWD/output:/data/output" \
  --volume "$PWD/references:/references:ro" \
  cure-ngs-harmonizer:0.1.0 vcf-to-maf \
  /data/input/sample.vcf /data/output/sample.maf \
  --source-assembly GRCh37 \
  --source-reference /references/grch37/hg19.fa \
  --target-assembly GRCh37 \
  --cache-version 116 --vep-data /references/vep \
  --vcf-tumor-id TUMOR --tumor-id sample-tumor
```

Prepare the FASTA, cache, and optional liftover assets by following the
[reference-data guide](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/REFERENCE_DATA.md).

## Historical standalone workflows

- `scripts/batch_vcf2maf_liftover_V.1.0.9.sh`: sequential legacy batch runner
- `scripts/batch_vcf2maf_liftover_parallel_V.1.1.7.sh`: legacy parallel runner
- `scripts/NCDC_batch_vcf2maf_V.1.3.3.sh`: latest component snapshot

These scripts require the operator to provide bcftools, Perl, vcf2maf, and
reference paths. They remain available for provenance; the containerized
umbrella CLI is the supported reproducible interface.

## Documentation and test data

- [Project structure](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/PROJECT_STRUCTURE.md)
- [Complete command reference](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/COMMAND_REFERENCE.md#vcf-or-gvcf-route)
- [Synthetic and attributed public VCF fixtures](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/tree/main/examples)
- [Reviewer reproduction checklist](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/REVIEWER_REPRODUCTION.md)

License: MIT. No CURE-NGS patient-level data are distributed here.
