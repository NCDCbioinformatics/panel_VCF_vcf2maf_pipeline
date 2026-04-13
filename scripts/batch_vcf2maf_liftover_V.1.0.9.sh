#!/usr/bin/env bash
set -euo pipefail

# Batch wrapper for converting per-sample VCF files into MAF with vcf2maf.
# Expected tools: bcftools, perl, and a local vcf2maf checkout.

INPUT_DIR="${INPUT_DIR:-./input_vcf}"
OUTPUT_DIR="${OUTPUT_DIR:-./output_maf}"
LOG_DIR="${LOG_DIR:-./logs}"
TMP_DIR="${TMP_DIR:-./tmp}"
VCF2MAF_DIR="${VCF2MAF_DIR:-/path/to/mskcc-vcf2maf}"
REF_FASTA="${REF_FASTA:-/path/to/hg19.fa}"
NCBI_BUILD="${NCBI_BUILD:-GRCh37}"
PARALLEL_JOBS="${PARALLEL_JOBS:-4}"

usage() {
  cat <<EOF
Usage:
  INPUT_DIR=/path/to/vcfs \
  OUTPUT_DIR=/path/to/maf \
  VCF2MAF_DIR=/path/to/vcf2maf \
  REF_FASTA=/path/to/hg19.fa \
  $0
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERROR] Missing required command: $1" >&2
    exit 1
  }
}

sample_tag() {
  local path="$1"
  local base
  base="$(basename "$path")"
  base="${base%.vcf.gz}"
  base="${base%.vcf}"
  printf '%s' "${base:0:8}"
}

normalize_vcf() {
  local input="$1"
  local work_name="$2"
  local output="$input"

  if [[ "$input" == *.vcf.gz ]]; then
    output="$TMP_DIR/${work_name}.vcf"
    gunzip -c "$input" > "$output"
  fi

  printf '%s' "$output"
}

pick_sample_ids() {
  local vcf="$1"
  mapfile -t ids < <(bcftools query -l "$vcf")
  if [[ ${#ids[@]} -eq 0 ]]; then
    echo "|"
    return 0
  fi
  if [[ ${#ids[@]} -eq 1 ]]; then
    echo "${ids[0]}|"
    return 0
  fi
  echo "${ids[0]}|${ids[1]}"
}

run_one() {
  local vcf="$1"
  local tag
  local work_vcf
  local tumor_id
  local normal_id
  local maf_out
  local stdout_log
  local stderr_log
  local ids

  tag="$(sample_tag "$vcf")"
  work_vcf="$(normalize_vcf "$vcf" "$tag")"
  ids="$(pick_sample_ids "$work_vcf")"
  tumor_id="${ids%%|*}"
  normal_id="${ids#*|}"
  maf_out="$OUTPUT_DIR/${tag}.maf"
  stdout_log="$LOG_DIR/${tag}.stdout.log"
  stderr_log="$LOG_DIR/${tag}.stderr.log"

  if [[ -z "$tumor_id" ]]; then
    echo "[WARN] No sample column detected: $vcf" | tee -a "$LOG_DIR/batch.log"
    return 0
  fi

  cmd=(
    perl "$VCF2MAF_DIR/vcf2maf.pl"
    --input-vcf "$work_vcf"
    --output-maf "$maf_out"
    --ref-fasta "$REF_FASTA"
    --ncbi-build "$NCBI_BUILD"
    --tumor-id "$tag"
    --vcf-tumor-id "$tumor_id"
  )

  if [[ -n "$normal_id" ]]; then
    cmd+=(--normal-id "${tag}_N" --vcf-normal-id "$normal_id")
  fi

  echo "[INFO] Processing $vcf -> $maf_out" | tee -a "$LOG_DIR/batch.log"
  if "${cmd[@]}" >"$stdout_log" 2>"$stderr_log"; then
    echo "[OK] $vcf" | tee -a "$LOG_DIR/batch.log"
  else
    echo "[FAIL] $vcf" | tee -a "$LOG_DIR/batch.log"
    return 1
  fi
}

export -f sample_tag normalize_vcf pick_sample_ids run_one require_cmd
export INPUT_DIR OUTPUT_DIR LOG_DIR TMP_DIR VCF2MAF_DIR REF_FASTA NCBI_BUILD

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  require_cmd bcftools
  require_cmd perl
  require_cmd gunzip

  mkdir -p "$OUTPUT_DIR" "$LOG_DIR" "$TMP_DIR"

  mapfile -t vcfs < <(find "$INPUT_DIR" -type f \( -name '*.vcf' -o -name '*.vcf.gz' \) | sort)
  if [[ ${#vcfs[@]} -eq 0 ]]; then
    echo "[ERROR] No VCF files found in $INPUT_DIR" >&2
    exit 1
  fi

  if command -v parallel >/dev/null 2>&1; then
    printf '%s\n' "${vcfs[@]}" | parallel -j "$PARALLEL_JOBS" run_one {}
  else
    for vcf in "${vcfs[@]}"; do
      run_one "$vcf"
    done
  fi
}

main "$@"
