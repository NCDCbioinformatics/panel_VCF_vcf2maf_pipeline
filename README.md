# panel_VCF_vcf2maf
<img width="2227" height="970" alt="image" src="https://github.com/user-attachments/assets/b66a5d03-c700-4b54-8f45-62db966795e6" />

# Oversion of panel_VCF_vcf2maf
#parallel process: batch_vcf2maf_liftover_parallel_V.1.1.7_github \
#one by one process: batch_vcf2maf_liftover_V.1.0.9_github

#one by one process \
chmod +x batch_vcf2maf_liftover_V.1.0.9.sh \
./batch_vcf2maf_liftover_V.1.0.9.sh

#parallel process \
chmod +x batch_vcf2maf_liftover_parallel_V.1.1.7.sh \
./batch_vcf2maf_liftover_parallel_V.1.1.7.sh

# panel_VCF_vcf2maf latest version (NCDC_batch_vcf2maf_V.1.3.0)

chmod +x NCDC_batch_vcf2maf_V.1.3.0.sh \
./NCDC_batch_vcf2maf_V.1.3.0.sh

- Setting the number of parallel processing and sample name length \
CORES=4 \
SAMPLE_TAG_LENGTH=8  # Tumor_Sample_Barcode length (e.g., 8 → "T002-033")


# Feature Summary:
- # input: All *.vcf* files under INPUT_DIR (only extensions: .vcf, .vcf.vep)
- # Compressed files and Excel files are absolutely prohibited from being input!!!!!!
 - File name with spaces/parentheses → Create a link with the changed name in TMP_DIR and use it. 
 - Convert Windows CRLF to dos2unix
 - Convert only SNV/indels to VCF using gVCF → bcftools view
 - Automatically detects GRCh37/GRCh38, and if GRCh38, liftover to hg19/GRCh37 with Picard LiftoverVcf 
 - If there is no FORMAT/SAMPLE column in the header, it is automatically added (ensure_sample_header) => Sometimes it is not present due to pseudonymization.
 - GRCh37 FASTA 3 types fallback (hg19_genome, GATK_assembly19, Ensembl_GRCh37_toplevel)
 - Use the first 8 characters of the file name as Tumor_Sample_Barcode (can be changed)
 - The MAF file name is created by replacing spaces/parentheses in the original VCF name with '_'
 - Errors/statuses are logged to LOG_TSV






