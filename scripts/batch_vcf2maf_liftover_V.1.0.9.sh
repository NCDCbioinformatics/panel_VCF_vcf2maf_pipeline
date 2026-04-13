#!/usr/bin/env bash
# batch_vcf2maf_liftover_V.1.0.9.sh
#
# 湲곕뒫 ?붿빟:
# - ?낅젰: INPUT_DIR ?꾨옒??紐⑤뱺 *.vcf* ?뚯씪 (?뺤옣???먯쑀: .vcf, .vcf.gz, .vcf.vep ??
# - ?뺤텞 ?뚯씪 泥섎━:
#     * gzip/bzip2/xz ????댁꽌 VCF ?ъ슜
#     * zip/7z/rar/tar ???대? *.vcf / *.vcf.gz 李얠븘???ъ슜, ?놁쑝硫?FORMAT_ERROR_ARCHIVE
# - Excel/?ㅽ봽?덈뱶?쒗듃(.xlsx ?? ??vcf濡?媛뺤젣 蹂寃????ㅽ뻾 ?묯ORMAT_ERROR_EXCEL濡?濡쒓렇 ???ㅽ궢
# - 怨듬갚/愿꾪샇媛 ?ㅼ뼱媛??뚯씪紐???TMP_DIR???덉쟾???대쫫?쇰줈 留뚮뱾???ъ슜
# - Windows CRLF ??dos2unix 濡?蹂??# - gVCF ??bcftools view 濡?SNV/indel留?VCF濡?蹂??# - GRCh37 / GRCh38 ?먮룞 ?먮퀎, GRCh38?대㈃ Picard LiftoverVcf濡?hg19/GRCh37濡?liftover
# - Liftover 寃곌낵媛 empty?щ룄 vcf2maf 媛뺥뻾 ??LIFTOVER_EMPTY_BUT_RUN
# - 鍮?VCF??vcf2maf 媛뺥뻾 ??EMPTY_BUT_RUN
# - ?ㅻ뜑??FORMAT/SAMPLE 而щ읆???놁쑝硫??먮룞?쇰줈 異붽?(ensure_sample_header)
# - GRCh37 FASTA 3醫?fallback (hg19_genome, GATK_assembly19, Ensembl_GRCh37_toplevel)
# - ?뚯씪紐???8湲?먮? Tumor_Sample_Barcode 濡??ъ슜
# - MAF ?뚯씪紐낆? ?먮옒 VCF ?대쫫?먯꽌 怨듬갚/愿꾪샇瑜?'_'濡?移섑솚?댁꽌 ?앹꽦
# - ?먮윭/?곹깭??LOG_TSV??湲곕줉:
#     * FORMAT_ERROR_EXCEL   : Excel/?ㅽ봽?덈뱶?쒗듃 ?뺤떇
#     * FORMAT_ERROR_ARCHIVE : ?꾩뭅?대툕??VCF ?놁쓬
#     * FORMAT_ERROR_INVALID : VCF ?ㅻ뜑/?щ㎎??源⑥졇??sample 異붿텧 遺덇?
#     * EMPTY_BUT_RUN        : 蹂???놁쓬?댁?留?媛뺤젣濡?annotation ?섑뻾
#     * LIFTOVER_EMPTY_BUT_RUN : liftover ??蹂???놁쓬?댁?留?媛뺤젣濡?annotation ?섑뻾
#     * SUCCESS              : vcf2maf ?깃났
#     * FAIL_VCF2MAF         : FASTA fallback 紐⑤몢 ?ㅽ뙣 ??#     * 湲고?: FAIL_GUNZIP, FAIL_BCFTOOLS_VIEW ???몃? ?먮윭

set -u

########################################
# 0. ?ъ슜???섍꼍 ?ㅼ젙
########################################

INPUT_DIR="/path/VCF_ALL"
OUT_MAF="/path/VCF_ALL_MAF"
TMP_DIR="/path/VCF_ALL_TMP"
LOG_DIR="/path/VCF_ALL_LOG"
VCF2MAF_PATH="/path/mskcc-vcf2maf-754d68a"

GRCH37_FASTAS=(
  "/path/.vep/hg19_genome/hg19.fa"
  "/path/.vep/GATK/Homo_sapiens_assembly19.fasta"
  "/path/.vep/homo_sapiens/102_GRCh37/Homo_sapiens.GRCh37.dna.toplevel.fa"
)
GRCH37_FASTA_LABELS=("hg19_genome" "GATK_assembly19" "Ensembl_GRCh37_toplevel")
VCF2MAF_EXTRA_OPTS_GRCH37="--species homo_sapiens --ncbi-build GRCh37"

PICARD_JAR="/path/picard.jar"
LIFTOVER_CHAIN_38_TO_37="/path/.vep/liftover/hg38ToHg19.over.chain.gz"
LIFTOVER_REF_GRCH37="/path/.vep/hg19_genome/hg19.fa"

mkdir -p "$OUT_MAF" "$TMP_DIR" "$LOG_DIR"
LOG_TSV="$LOG_DIR/vcf2maf_batch_log.tsv"
if [ ! -f "$LOG_TSV" ]; then
  echo -e "datetime\tvcf_path\tsample_tag8\tref_info\tis_gvcf\thas_normal\tstatus\tmessage" > "$LOG_TSV"
fi

########################################
# 1. ?좏떥 ?⑥닔??########################################

log_line() {
  local vcf="$1"; local tag8="$2"; local ref_info="$3"
  local is_gvcf="$4"; local has_normal="$5"; local status="$6"; local message="$7"
  echo -e "$(date '+%Y-%m-%d %H:%M:%S')\t${vcf}\t${tag8}\t${ref_info}\t${is_gvcf}\t${has_normal}\t${status}\t${message}" >> "$LOG_TSV"
}

is_empty_vcf() {
  local vcf="$1"
  local n
  n=$(bcftools view -H "$vcf" 2>/dev/null | head -n 1 | wc -l)
  [ "$n" -eq 0 ]
}

detect_gvcf() {
  local vcf="$1"
  if [[ "$vcf" == *.gz ]]; then
    if zgrep -m1 "GVCF" "$vcf" >/dev/null 2>&1; then
      return 0
    elif zgrep -m1 "<NON_REF>" "$vcf" >/dev/null 2>&1; then
      return 0
    fi
  else
    if grep -m1 "GVCF" "$vcf" >/dev/null 2>&1; then
      return 0
    elif grep -m1 "<NON_REF>" "$vcf" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

detect_ref_genome_group() {
  local vcf="$1"
  local ref_line ref_lower
  if [[ "$vcf" == *.gz ]]; then
    ref_line=$(zgrep -m1 "^##reference=" "$vcf" 2>/dev/null || true)
  else
    ref_line=$(grep -m1 "^##reference=" "$vcf" 2>/dev/null || true)
  fi
  ref_lower=$(echo "$ref_line" | tr 'A-Z' 'a-z')

  if echo "$ref_lower" | grep -q "grch37\|hg19\|assembly19\|b37"; then
    echo "GRCh37"; return 0
  fi
  if echo "$ref_lower" | grep -q "grch38\|hg38\|assembly38\|analysis_set\|no_alt"; then
    echo "GRCh38"; return 0
  fi

  local len
  if [[ "$vcf" == *.gz ]]; then
    len=$(zgrep -m1 "^##contig=<ID=chr1," "$vcf" 2>/dev/null | sed -n 's/.*length=\([0-9]*\).*/\1/p')
    if [ -z "$len" ]; then
      len=$(zgrep -m1 "^##contig=<ID=1," "$vcf" 2>/dev/null | sed -n 's/.*length=\([0-9]*\).*/\1/p')
    fi
  else
    len=$(grep -m1 "^##contig=<ID=chr1," "$vcf" 2>/dev/null | sed -n 's/.*length=\([0-9]*\).*/\1/p')
    if [ -z "$len" ]; then
      len=$(grep -m1 "^##contig=<ID=1," "$vcf" 2>/dev/null | sed -n 's/.*length=\([0-9]*\).*/\1/p')
    fi
  fi

  case "$len" in
    "249250621") echo "GRCh37" ;;
    "248956422") echo "GRCh38";;
x    *)           echo "GRCh37" ;;
  esac
}

detect_samples() {
  local vcf="$1"
  local samples
  mapfile -t samples < <(bcftools query -l "$vcf" 2>/dev/null)
  local n=${#samples[@]}
  local tumor_id=""; local normal_id=""; local has_normal="0"

  if [ "$n" -eq 0 ]; then
    :
  elif [ "$n" -eq 1 ]; then
    tumor_id="${samples[0]}"
  else
    local s0_lower s1_lower
    s0_lower=$(echo "${samples[0]}" | tr 'A-Z' 'a-z')
    s1_lower=$(echo "${samples[1]}" | tr 'A-Z' 'a-z')
    if echo "$s0_lower" | grep -q "norm\|normal\|control\|blood\|bld\|wbc\|germ"; then
      normal_id="${samples[0]}"; tumor_id="${samples[1]}"
    elif echo "$s1_lower" | grep -q "norm\|normal\|control\|blood\|bld\|wbc\|germ"; then
      normal_id="${samples[1]}"; tumor_id="${samples[0]}"
    else
      tumor_id="${samples[0]}"; normal_id="${samples[1]}"
    fi
    has_normal="1"
  fi
  echo "$tumor_id,$normal_id,$has_normal"
}

ensure_sample_header() {
  local vcf="$1"
  local sample_tag8="$2"

  local new_vcf="$vcf"

  local samples=()
  mapfile -t samples < <(bcftools query -l "$vcf" 2>/dev/null || true)
  if [ "${#samples[@]}" -gt 0 ]; then
    echo "$new_vcf"
    return 0
  fi

  local hdr
  if [[ "$vcf" == *.gz ]]; then
    hdr=$(zgrep -m1 "^#CHROM" "$vcf" 2>/dev/null || true)
  else
    hdr=$(grep -m1 "^#CHROM" "$vcf" 2>/dev/null || true)
  fi
  [ -z "$hdr" ] && { echo "$new_vcf"; return 0; }

  local hdr_cols
  hdr_cols=$(echo "$hdr" | awk -F'\t' '{print NF}')

  local data_line data_cols
  data_line=$(bcftools view -H "$vcf" 2>/dev/null | head -n 1 || true)
  [ -z "$data_line" ] && { echo "$new_vcf"; return 0; }
  data_cols=$(echo "$data_line" | awk -F'\t' '{print NF}')

  if [ "$hdr_cols" -eq 8 ] && [ "$data_cols" -ge 10 ]; then
    echo "    sample header ?놁쓬 ??FORMAT, ?섑뵆 ?대쫫(${sample_tag8})??header??異붽?"
    local tmp_base out_vcf
    tmp_base=$(basename "$vcf")
    out_vcf="$TMP_DIR/${tmp_base}.addsample.vcf"

    if [[ "$vcf" == *.gz ]]; then
      zcat "$vcf" | \
        awk -v smp="$sample_tag8" 'BEGIN{FS=OFS="\t"} /^#CHROM/ {print $0, "FORMAT", smp; next} {print}' \
        > "$out_vcf"
    else
      awk -v smp="$sample_tag8" 'BEGIN{FS=OFS="\t"} /^#CHROM/ {print $0, "FORMAT", smp; next} {print}' \
        "$vcf" > "$out_vcf"
    fi

    log_line "$vcf" "$sample_tag8" "ADD_SAMPLE_HEADER" "0" "0" "FIX_HEADER" "Added FORMAT and sample column name"
    new_vcf="$out_vcf"
  fi

  echo "$new_vcf"
}

run_vcf2maf_grch37_with_fallback() {
  local orig_vcf_path="$1"
  local vcf_for_maf="$2"
  local maf_out="$3"
  local sample_tag8="$4"
  local tumor_vcf_id="$5"
  local normal_vcf_id="$6"
  local has_normal="$7"
  local ref_info_for_log="$8"
  local is_gvcf_flag="$9"

  local idx rc
  local tried_labels=()

  for idx in "${!GRCH37_FASTAS[@]}"; do
    local ref_fasta="${GRCH37_FASTAS[$idx]}"
    local label="${GRCH37_FASTA_LABELS[$idx]}"
    tried_labels+=("$label")

    echo "    vcf2maf ?쒕룄 (GRCh37, ref=$label)"
    local cmd=( perl "$VCF2MAF_PATH/vcf2maf.pl"
                --input-vcf "$vcf_for_maf"
                --output-maf "$maf_out"
                --ref-fasta "$ref_fasta"
                --tumor-id "$sample_tag8"
                --vcf-tumor-id "$tumor_vcf_id"
                $VCF2MAF_EXTRA_OPTS_GRCH37 )
    if [ "$has_normal" = "1" ] && [ -n "$normal_vcf_id" ]; then
      cmd+=( --normal-id "${sample_tag8}_N" --vcf-normal-id "$normal_vcf_id" )
    fi

    if "${cmd[@]}" >"$TMP_DIR/${sample_tag8}.vcf2maf.${label}.stdout.log" \
                    2>"$TMP_DIR/${sample_tag8}.vcf2maf.${label}.stderr.log"; then
      echo "    vcf2maf SUCCESS (ref=$label)"
      log_line "$orig_vcf_path" "$sample_tag8" "${ref_info_for_log}+${label}" \
               "$is_gvcf_flag" "$has_normal" "SUCCESS" "vcf2maf completed with ref=$label"
      return 0
    else
      rc=$?
      echo "    vcf2maf FAILED (ref=$label, exit=$rc) ???ㅼ쓬 FASTA濡??쒕룄"
    fi
  done

  local joined_labels
  joined_labels=$(IFS=','; echo "${tried_labels[*]}")
  log_line "$orig_vcf_path" "$sample_tag8" "${ref_info_for_log}+ALL_FAIL" \
           "$is_gvcf_flag" "$has_normal" "FAIL_VCF2MAF" \
           "vcf2maf failed for all GRCh37 FASTAs: ${joined_labels}"
  return 1
}

########################################
# 2. 硫붿씤 猷⑦봽 (?쒖감 泥섎━)
########################################

echo "=== batch_vcf2maf_liftover_V.1.0.8 (sequential) ?쒖옉 ==="
echo "INPUT_DIR = $INPUT_DIR"
echo "OUT_MAF   = $OUT_MAF"

find "$INPUT_DIR" -type f -name "*.vcf*" | sort | \
while IFS= read -r vcf; do
  [ -z "$vcf" ] && continue

  orig_vcf="$vcf"
  # Excel/?뺤옣??臾몄젣 異붿쟻???뚮옒洹?  excel_flag=0
  base=$(basename "$orig_vcf")
  orig_bn="${base%.vcf}"
  orig_bn="${orig_bn%.gz}"
  work_bn="$orig_bn"
  work_bn="${work_bn// /_}"
  work_bn="${work_bn//(/_}"
  work_bn="${work_bn?/)/_}"

  sample_tag8="${orig_bn:0:8}"

  echo "==============================================="
  echo " Processing: $orig_vcf"
  echo "   ??sample_tag8 (Tumor_Sample_Barcode) = $sample_tag8"

  # ?뚯씪 ???寃??諛??뺤텞/?꾩뭅?대툕/?묒? 泥섎━
  ftype=$(file -b "$orig_vcf" 2>/dev/null || echo "")

  if echo "$ftype" | grep -qi "gzip compressed data"; then
    echo "    gzip ?뺤텞 VCF 媛먯? ????댁꽌 ?ъ슜"
    gz_out="$TMP_DIR/${work_bn}.from_gzip.vcf"
    if ! gunzip -c "$orig_vcf" > "$gz_out"; then
      echo "    gunzip ?ㅽ뙣"
      log_line "$orig_vcf" "$sample_tag8" "NA" "0" "0" "FAIL_GUNZIP" "gunzip failed"
      continue
    fi
    orig_vcf="$gz_out"
    base=$(basename "$orig_vcf")
    orig_bn="${base%.vcf}"
    work_bn="$orig_bn"; work_bn="${work_bn// /_}"; work_bn="${work_bn//(/_}"; work_bn="${work_bn//)/_}"
  elif echo "$ftype" | grep -qi "bzip2 compressed data"; then
    echo "    bzip2 ?뺤텞 VCF 媛먯? ????댁꽌 ?ъ슜"
    bz_out="$TMP_DIR/${work_bn}.from_bzip2.vcf"
    if ! bunzip2 -c "$orig_vcf" > "$bz_out"; then
      echo "    bunzip2 ?ㅽ뙣"
      log_line "$orig_vcf" "$sample_tag8" "NA" "0" "0" "FAIL_BUNZIP2" "bunzip2 failed"
      continue
    fi
    orig_vcf="$bz_out"
    base=$(basename "$orig_vcf")
    orig_bn="${base%.vcf}"
    work_bn="$orig_bn"; work_bn="${work_bn// /_}"; work_bn="${work_bn//(/_}"; work_bn="${work_bn//)/_}"
  elif echo "$ftype" | grep -qi "XZ compressed data"; then
    echo "    xz ?뺤텞 VCF 媛먯? ????댁꽌 ?ъ슜"
    xz_out="$TMP_DIR/${work_bn}.from_xz.vcf"
    if ! xz -dc "$orig_vcf" > "$xz_out"; then
      echo "    xz -d ?ㅽ뙣"
      log_line "$orig_vcf" "$sample_tag8" "NA" "0" "0" "FAIL_XZ" "xz decompress failed"
      continue
    fi
    orig_vcf="$xz_out"
    base=$(basename "$orig_vcf")
    orig_bn="${base%.vcf}"
    work_bn="$orig_bn"; work_bn="${work_bn// /_}"; work_bn="${work_bn//(/_}"; work_bn="${work_bn//)/_}"
  fi

  ftype=$(file -b "$orig_vcf" 2>/dev/null || echo "")
  if echo "$ftype" | grep -qiE "Zip archive|7-zip archive|RAR archive|tar archive"; then
    echo "    ?꾩뭅?대툕 ?뚯씪 媛먯? ($ftype) ???대? VCF 寃??
    unzip_dir="$TMP_DIR/${work_bn}_unz"
    mkdir -p "$unzip_dir"

    if echo "$ftype" | grep -qi "Zip archive"; then
      unzip -o "$orig_vcf" -d "$unzip_dir" >/dev/null 2>&1 || true
    elif echo "$ftype" | grep -qi "7-zip archive"; then
      7z x -y -o"$unzip_dir" "$orig_vcf" >/dev/null 2>&1 || true
    elif echo "$ftype" | grep -qi "RAR archive"; then
      unrar x -o+ "$orig_vcf" "$unzip_dir" >/dev/null 2>&1 || true
    elif echo "$ftype" | grep -qi "tar archive"; then
      tar -xf "$orig_vcf" -C "$unzip_dir" >/dev/null 2>&1 || true
    fi

    inner_vcf=$(find "$unzip_dir" -type f \( -name "*.vcf" -o -name "*.vcf.gz" \) | head -n 1 || true)
    if [ -z "$inner_vcf" ]; then
      echo "    ?꾩뭅?대툕 ?대??먯꽌 VCF瑜?李얠? 紐삵븿 ???ㅽ뙣"
      log_line "$orig_vcf" "$sample_tag8" "NA" "0" "0" "FORMAT_ERROR_ARCHIVE" "Archive file does not contain any VCF; verify file content"
      continue
    fi

    echo "    ?꾩뭅?대툕 ?대? VCF ?ъ슜: $inner_vcf"
    orig_vcf="$inner_vcf"
    base=$(basename "$orig_vcf")
    orig_bn="${base%.vcf}"; orig_bn="${orig_bn%.gz}"
    work_bn="$orig_bn"; work_bn="${work_bn// /_}"; work_bn="${work_bn//(/_}"; work_bn="${work_bn//)/_}"
  fi

  ftype=$(file -b "$orig_vcf" 2>/dev/null || echo "")
  if echo "$ftype" | grep -qiE "Excel|spreadsheet"; then
    echo "    Excel/?ㅽ봽?덈뱶?쒗듃 ?뺤떇 媛먯? (file: $ftype) ???쇰떒 VCF泥섎읆 ?쒕룄 ?? ?ㅽ뙣 ???뺤옣??臾몄젣濡?濡쒓렇"
    excel_flag=1
  fi

  # 怨듬갚/愿꾪샇 ?ы븿 ?뚯씪紐???TMP ?щ낵由?留곹겕
  if [[ "$base" =~ [\ \(\)] ]]; then
    echo "   ?お 怨듬갚/愿꾪샇 ?ы븿 ?뚯씪紐?媛먯? ??TMP 留곹겕濡??뺢퇋??
    work_vcf="$TMP_DIR/${work_bn}.orig$( [[ "$base" == *.gz ]] && echo ".vcf.gz" || echo ".vcf" )"
    ln -sf "$orig_vcf" "$work_vcf"
  else
    work_vcf="$orig_vcf"
  fi

  vcf="$work_vcf"

  if [[ "$vcf" != *.gz ]] && command -v dos2unix >/dev/null 2>&1; then
    if file "$vcf" | grep -q "CRLF"; then
      echo "    Windows line endings detected ??converting to UNIX (dos2unix)"
      tmp_fixed="$TMP_DIR/${work_bn}.fixed.vcf"
      dos2unix -n "$vcf" "$tmp_fixed" >/dev/null 2>&1
      vcf="$tmp_fixed"
    fi
  fi

  if [ "$excel_flag" -eq 0 ] && is_empty_vcf "$vcf"; then
    echo "    No variants detected (Empty VCF) ??annotation 吏꾪뻾 (鍮?MAF ?덉긽)"
    log_line "$orig_vcf" "$sample_tag8" "NA" "0" "0" "EMPTY_BUT_RUN" "No variant lines, forcing vcf2maf"
  fi

  is_gvcf_flag="0"
  vcf_for_maf="$vcf"
  if detect_gvcf "$vcf"; then
    is_gvcf_flag="1"
    echo "    gVCF detected ??variants-only VCF濡?蹂??
    tmp_vcf="$TMP_DIR/${work_bn}.variants.vcf.gz"
    if ! bcftools view -v snps,indels "$vcf" -Oz -o "$tmp_vcf" 2>"$TMP_DIR/${work_bn}.bcftools_view.log"; then
      echo "    bcftools view ?ㅽ뙣"
      log_line "$orig_vcf" "$sample_tag8" "NA" "$is_gvcf_flag" "0" "FAIL_BCFTOOLS_VIEW" "bcftools view error (gVCF?뭋CF)"
      continue
    fi
    vcf_for_maf="$tmp_vcf"
  fi

  ref_group_orig=$(detect_ref_genome_group "$vcf_for_maf")
  echo "    original ref_group = $ref_group_orig"
  ref_info_for_log="$ref_group_orig"

  if [ "$ref_group_orig" = "GRCh38" ]; then
    echo "    Liftover GRCh38 ??GRCh37 (hg19)"
    lifted_vcf_gz="$TMP_DIR/${work_bn}.lifted.hg19.vcf.gz"
    lifted_vcf="$TMP_DIR/${work_bn}.lifted.hg19.vcf"
    reject_vcf="$TMP_DIR/${work_bn}.rejected.hg38to19.vcf.gz"

    if ! java -Xmx4g -jar "$PICARD_JAR" LiftoverVcf \
          I="$vcf_for_maf" \
          O="$lifted_vcf_gz" \
          CHAIN="$LIFTOVER_CHAIN_38_TO_37" \
          REJECT="$reject_vcf" \
          R="$LIFTOVER_REF_GRCH37" \
          2>"$TMP_DIR/${work_bn}.liftover.log"; then
      echo "    LiftoverVcf ?ㅽ뙣"
      log_line "$orig_vcf" "$sample_tag8" "GRCh38?묰RCh37_FAIL" "$is_gvcf_flag" "0" "FAIL_LIFTOVER" "Picard LiftoverVcf error"
      continue
    fi

    if [ -f "$lifted_vcf_gz" ]; then
      echo "    Liftover output compressed ??decompressing"
      gunzip -c "$lifted_vcf_gz" > "$lifted_vcf"
    fi

    if is_empty_vcf "$lifted_vcf"; then
      echo "    Liftover 寃곌낵 VCF媛 鍮꾩뼱 ?덉쓬 ??annotation 吏꾪뻾 (鍮?MAF ?덉긽)"
      log_line "$orig_vcf" "$sample_tag8" "GRCh38?묰RCh37_EMPTY" "$is_gvcf_flag" "0" "LIFTOVER_EMPTY_BUT_RUN" "Lifted VCF has no variants, forcing vcf2maf"
    fi

    vcf_for_maf="$lifted_vcf"
    ref_info_for_log="GRCh38?묰RCh37"
  fi

  # sample header 蹂댁젙
  vcf_for_maf="$(ensure_sample_header "$vcf_for_maf" "$sample_tag8")"

  # sample ?뺣낫 諛?tumor/normal 異붾줎
  sample_info=$(detect_samples "$vcf_for_maf")
  tumor_vcf_id=$(echo "$sample_info" | cut -d',' -f1)
  normal_vcf_id=$(echo "$sample_info" | cut -d',' -f2)
  has_normal=$(echo "$sample_info" | cut -d',' -f3)

  if [ -z "$tumor_vcf_id" ]; then
    echo "    sample column ?놁쓬 ?먮뒗 VCF ?щ㎎ 源⑥쭚 ??annotation 遺덇?"
    if [ "$excel_flag" -eq 1 ]; then
      log_line "$orig_vcf" "$sample_tag8" "$ref_info_for_log" "$is_gvcf_flag" "$has_normal" "FORMAT_ERROR_EXCEL" "Excel/spreadsheet treated as VCF caused parse failure (extension/format problem)"
    else
      log_line "$orig_vcf" "$sample_tag8" "$ref_info_for_log" "$is_gvcf_flag" "$has_normal" "FORMAT_ERROR_INVALID" "Invalid or corrupted VCF format ??unable to detect sample columns"
    fi
    continue
  fi

  echo "    samples:"
  echo "      tumor_vcf_id  = $tumor_vcf_id"
  if [ "$has_normal" = "1" ]; then
    echo "      normal_vcf_id = $normal_vcf_id"
  else
    echo "      normal_vcf_id = (none, tumor-only)"
  fi

  maf_bn="$orig_bn"
  maf_bn="${maf_bn// /_}"
  maf_bn="${maf_bn//(/_}"
  maf_bn="${maf_bn//)/_}"
  maf_out="$OUT_MAF/${maf_bn}.maf"
  echo "    vcf2maf (GRCh37, FASTA fallback) ??$maf_out"

  if run_vcf2maf_grch37_with_fallback \
        "$orig_vcf" \
        "$vcf_for_maf" \
        "$maf_out" \
        "$sample_tag8" \
        "$tumor_vcf_id" \
        "$normal_vcf_id" \
        "$has_normal" \
        "$ref_info_for_log" \
        "$is_gvcf_flag"; then
    :
  else
    echo "    vcf2maf FAILED for all GRCh37 FASTAs"
  fi

done

echo "==============================================="
echo " ?꾩껜 泥섎━ ?꾨즺. 濡쒓렇 ?뚯씪: $LOG_TSV"
