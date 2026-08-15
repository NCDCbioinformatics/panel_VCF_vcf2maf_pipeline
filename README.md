# panel_VCF_vcf2maf_pipeline

Batch utilities for converting panel VCF inputs into MAF outputs with `vcf2maf`.

> **Reviewer and new-user deployment:** use the supported, version-pinned
> [CURE-NGS Docker/OCI distribution](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework#reviewer-quick-start).
> It replaces workstation-specific paths with explicit bind mounts and command
> options, and includes automated tests spanning all six component functions.

## Reproducible installation and test data

- [Clean-machine installation](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/INSTALLATION.md)
- [GRCh37 FASTA, VEP 116 cache, liftover chain, GTF, and HGNC setup](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/REFERENCE_DATA.md)
- [VCF-to-MAF command examples](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/COMMAND_REFERENCE.md#vcf-or-gvcf-route)
- [Network-free reviewer walkthrough](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/blob/main/docs/REVIEWER_REPRODUCTION.md)
- [Synthetic and attributed public VCF fixtures](https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework/tree/main/examples)

The latest audited historical release is
`NCDC_batch_vcf2maf_V.1.3.3_github`. Its tag, commit, asset size, and SHA-256
are locked in the umbrella repository. The scripts below remain available for
provenance and expert use; the consolidated container is the supported route
for external reproduction.

## Repository role

This repository is a component of the CURE-NGS panel harmonization framework described in the manuscript "Multi-Institutional Harmonization Framework for Heterogeneous Panel-Based NGS in Precision Oncology."

Umbrella repository: https://github.com/NCDCbioinformatics/cure-ngs-panel-harmonization-framework

## Available workflows

- `scripts/batch_vcf2maf_liftover_V.1.0.9.sh`: sequential batch runner for `.vcf` and `.vcf.gz`
- `scripts/batch_vcf2maf_liftover_parallel_V.1.1.7.sh`: legacy parallel workflow
- `scripts/NCDC_batch_vcf2maf_V.1.3.3.sh`: latest internal batch workflow snapshot

## Quick start

```bash
export INPUT_DIR=/path/to/input_vcf
export OUTPUT_DIR=/path/to/output_maf
export VCF2MAF_DIR=/path/to/mskcc-vcf2maf
export REF_FASTA=/path/to/hg19.fa
bash scripts/batch_vcf2maf_liftover_V.1.0.9.sh
```

## Requirements

- Linux or WSL
- Bash
- `bcftools`
- `perl`
- `gunzip`
- Local `vcf2maf` checkout
- GRCh37 reference FASTA

## Notes

- Sample IDs are derived from the first eight characters of each VCF basename by default.
- The batch runner supports both uncompressed `.vcf` and compressed `.vcf.gz` inputs.
- Output logs are written to `LOG_DIR` for per-sample troubleshooting.

## Software metadata

- Operating system(s): Linux; Windows users can run supported workflows via WSL where needed
- Programming language(s): Bash shell
- License: MIT License
