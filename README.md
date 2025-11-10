# NCDC_panel_VCF_vcf2maf


#parallel process: batch_vcf2maf_liftover_parallel_V.1.1.7_github \
#one by one process: batch_vcf2maf_liftover_V.1.0.9_github

#one by one process \
chmod +x batch_vcf2maf_liftover_V.1.0.9.sh \
./batch_vcf2maf_liftover_V.1.0.9.sh

#parallel process \
chmod +x batch_vcf2maf_liftover_parallel_V.1.1.7.sh \
./batch_vcf2maf_liftover_parallel_V.1.1.7.sh

# 기능 요약:
- 입력: INPUT_DIR 아래의 모든 *.vcf* 파일 (확장자 자유: .vcf, .vcf.gz, .vcf.vep 등) 
- 압축 파일 처리: 
     * gzip/bzip2/xz → 풀어서 VCF 사용 
     * zip/7z/rar/tar → 내부 *.vcf / *.vcf.gz 찾아서 사용, 없으면 FORMAT_ERROR_ARCHIVE 
 - Excel/스프레드시트(.xlsx 등) → vcf 포멧으로 강제 변형 후 annotation 실행=> 만약 실패시 log에는 확장자 문제로 표시 
 - 공백/괄호가 들어간 파일명 → TMP_DIR에 변경된 이름으로 링크 만들어 사용 
 - Windows CRLF → dos2unix 로 변환 
 - gVCF → bcftools view 로 SNV/indel만 VCF로 변환 
 - GRCh37 / GRCh38 자동 판별, GRCh38이면 Picard LiftoverVcf로 hg19/GRCh37로 liftover 
 - Liftover 결과가 empty여도 vcf2maf 강행 → LIFTOVER_EMPTY_BUT_RUN => 파일 이력 관리위하여 빈 MAF 파일도 필요 
 - 빈 VCF도 vcf2maf 강행 → EMPTY_BUT_RUN => 파일 이력 관리위하여 빈 MAF 파일도 필요 
 - 헤더에 FORMAT/SAMPLE 컬럼이 없으면 자동으로 추가(ensure_sample_header) => 가명 처리로 인해 없는 경우가 있음 
 - GRCh37 FASTA 3종 fallback (hg19_genome, GATK_assembly19, Ensembl_GRCh37_toplevel) 
 - 파일명 앞 8글자를 Tumor_Sample_Barcode 로 사용 
 - MAF 파일명은 원래 VCF 이름에서 공백/괄호를 '_'로 치환해서 생성 
 - 에러/상태는 LOG_TSV에 기록: 
     * FORMAT_ERROR_EXCEL   : Excel/스프레드시트 형식 
     * FORMAT_ERROR_ARCHIVE : 아카이브에 VCF 없음 
     * FORMAT_ERROR_INVALID : VCF 헤더/포맷이 깨져서 sample 추출 불가 
     * EMPTY_BUT_RUN        : 변이 없음이지만 강제로 annotation 수행 
     * LIFTOVER_EMPTY_BUT_RUN : liftover 후 변이 없음이지만 강제로 annotation 수행 
     * SUCCESS              : vcf2maf 성공 
     * FAIL_VCF2MAF         : FASTA fallback 모두 실패 등 
     * 기타: FAIL_GUNZIP, FAIL_BCFTOOLS_VIEW 등 세부 에러 
