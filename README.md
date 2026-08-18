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
| Supported commands | `cure-ngs inspect-vcf`, `normalize-vcf`, `vcf-to-maf`, and `batch-vcf-to-maf` |
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
docker build --file docker/Dockerfile --tag cure-ngs-harmonizer:0.2.0 .
```

The released full and core images can be downloaded without a GitHub login:

```bash
docker pull ghcr.io/ncdcbioinformatics/cure-ngs-harmonizer:0.2.0
docker pull ghcr.io/ncdcbioinformatics/cure-ngs-harmonizer:0.2.0-core
```

The full image contains VEP, Picard, and vcf2maf. The core image is the smaller
network-free reviewer and preprocessing environment.

## Verify and run this capability

Run the network-free six-component reviewer test:

```bash
bash scripts/run_reviewer_demo.sh
```

For a heterogeneous directory, keep the large FASTAs, indexes, VEP cache, and
liftover chains outside the image. Copy the portable configuration template,
edit its relative paths, and validate the complete bundle first:

```bash
cp references/reference-config.example.json references/reference-config.json

docker run --rm \
  --volume "$PWD/references:/references:ro" \
  ghcr.io/ncdcbioinformatics/cure-ngs-harmonizer:0.2.0 \
  doctor-bundle --reference-config /references/reference-config.json

mkdir -p output
chmod 0777 output  # Linux: writable by the image's non-root UID 10001
docker run --rm --read-only --tmpfs /tmp:size=2g,mode=1777 \
  --volume "$PWD/input:/data/input:ro" \
  --volume "$PWD/output:/data/output" \
  --volume "$PWD/references:/references:ro" \
  ghcr.io/ncdcbioinformatics/cure-ngs-harmonizer:0.2.0 \
  batch-vcf-to-maf /data/input /data/output \
  --reference-config /references/reference-config.json \
  --jobs 4 --forks 1
```

GRCh37/hg19 remains the default target. A GRCh38 input is detected and lifted
with the configured GRCh38-to-GRCh37 chain; a GRCh37 input bypasses liftover.
The configured FASTAs and chains are **ordered fallback alternatives**, not
sequences merged into one reference. This preserves the retry behavior of
`NCDC_batch_vcf2maf_V.1.3.3` without hard-coded workstation paths.

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
- [Restored V1.3.3 batch workflow and reference-bundle layout](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/V1.3.3_BATCH_WORKFLOW.md)
- [Synthetic and attributed public VCF fixtures](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/tree/main/examples)
- [Reviewer reproduction checklist](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/REVIEWER_REPRODUCTION.md)

License: MIT. No CURE-NGS patient-level data are distributed here.
