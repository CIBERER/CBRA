#!/usr/bin/env Rscript

# Author: Gonzalo Nunez Moreno
## Reedited by: Yolanda Benítez Quesada

library(optparse)
library(data.table)

#############
# Arguments # 
#############
option_list = list(

  make_option(c("-i", "--input"), type="character", default=NULL, 
              help="\t\t input TSV file (output from VEP)", metavar="character"),
  
  make_option(c("-o", "--output"), type="character", default=NULL, 
              help="\t\t Output file", metavar="character"),

  make_option(c("-a", "--automap"), type="character", default=NULL,
              help="\t\tAutomap output file (optional)", metavar="character"),
  
  make_option(c("-f", "--maf"), type="double", default=0.1,
               help="\t\tMinimum allele frequency to filter (currently unused)", metavar="double"),
  
  make_option(c("-s", "--SGDS"), type="character", default=NULL,
            help="\t\tGLOWgenes Score of Gene-Disease Specificity", metavar="character"),

  make_option(c("-d", "--dbNSFPgene"), type="character", default=NULL, 
              help="\t\tdbNSFP_gene file", metavar="character"),
  
  make_option(c("-r", "--regiondict"), type="character", default=NULL,
              help="\t\tRegion dictionary", metavar="character"),
  
  make_option(c("-m", "--omim"), type="character", default=NULL,
              help="\t\tOMIM information", metavar="character"),
  
  make_option(c("-D", "--domino"), type="character", default=NULL, 
              help="\t\tdomino file", metavar="character"),

  make_option(c("-e", "--expression"), type="character", default=NULL, 
            help="\t\ttissue expression file", metavar="character"),
  
  make_option(c("-g", "--genefilter"), type="character", default=NULL,
              help="\t\tGene list to filter the resutls", metavar="character"),
  
  make_option(c("-w", "--glowgenes"), type="character", default=NULL,
              help="\t\tGLOWgenes output file to annotate and srt the results", metavar="character"),

  make_option(c("-p", "--panel_annotation_file"), type="character", default=NULL,
              help="\t\tGene-Panel file to annotate", metavar="character")

)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

input = opt$input
output = opt$output
automap_path = opt$automap
maf = opt$maf
glowgenes_path = opt$glowgenes
SGDS_path = opt$SGDS

dbNSFPgenepath <- opt$dbNSFPgene
dominopath <- opt$domino
expression_path <- opt$expression
dict_region_path <- opt$regiondict
omim_path = opt$omim
genefilter_path = opt$genefilter
panels_path = opt$panel_annotation_file

required_args <- c("input", "output", "dbNSFPgene", "domino", "expression")
missing_args <- required_args[vapply(required_args, function(x) is.null(opt[[x]]), logical(1))]
if (length(missing_args) > 0) {
  stop("Missing required arguments: ", paste0("--", missing_args, collapse = ", "))
}

#############
# Functions #
#############

# First value of a comma-separated field, as numeric
first_num <- function(x) suppressWarnings(as.numeric(sub(",.*$", "", x)))

# Mean of a comma-separated field ("-" values are counted as 0)
mean_num <- function(x) {
  vapply(x, function(v) mean(suppressWarnings(as.numeric(strsplit(gsub("(?<![eE])-", "0", v, perl = T), ",")[[1]]))),
         numeric(1), USE.NAMES = FALSE)
}

# Left join by gene, warning if the annotation table duplicates variants
merge_by_gene <- function(x, y, by.x, by.y, name) {
  n_before <- nrow(x)
  res <- merge(x, y, by.x = by.x, by.y = by.y, all.x = T)
  if (nrow(res) != n_before) {
    print(paste0("WARNING: ", name, " has repeated genes; ", nrow(res) - n_before, " variant rows were duplicated"))
  }
  res
}

################
# Data loading # 
################

##### VEP

print("Read VEP file")

#### Find the line number where the header starts, using shell grep
start_line <- as.integer(
  system(paste0("zgrep -n -m1 '^#Uploaded_variation' ", shQuote(input), " | cut -d: -f1"),
         intern = TRUE)
)

if (length(start_line) == 0 || is.na(start_line)) {
  stop("The line starting with '#Uploaded_variation' was not found.")
}

# Fichero temporal en el mismo directorio de trabajo (con espacio garantizado),
# en vez de depender de /tmp
tmp_file <- file.path(dirname(input), "vep_body_tmp.tsv")
# zcat -f also works with uncompressed input
status <- system(paste0("zcat -f ", shQuote(input), " | tail -n +", start_line, " > ", shQuote(tmp_file)))
if (status != 0) {
  stop("Error extracting the body of the VEP file")
}

vep <- fread(tmp_file, header = TRUE, sep = "\t",
             colClasses = "character", quote = "",
             data.table = TRUE, na.strings = c("", "NA", "-"))

invisible(file.remove(tmp_file))

if ("Uploaded_variation" %in% colnames(vep) && !("#Uploaded_variation" %in% colnames(vep))) {
  setnames(vep, "Uploaded_variation", "#Uploaded_variation")
}

## Filtering variants by gene panel if included without GLOWgenes ranking

# genefilter
if (!is.null(genefilter_path)){
  genefilter = read.delim(genefilter_path, header = F, stringsAsFactors = F, quote = "", check.names=F)
}

# Gene Filter
if (!is.null(genefilter_path) && is.null(glowgenes_path)){
  vep = vep[vep$SYMBOL %in% genefilter$V1,]
}

## Check if there are remaining variants
if (nrow(vep) == 0) {
  stop("There are no remaining variants")
}

#########################
## Include custom info ##
#########################

# dbNSFP gene
dbNSFP_gene = read.delim(dbNSFPgenepath, header = TRUE, stringsAsFactors = F, quote = "")
vep = merge_by_gene(vep, dbNSFP_gene, "SYMBOL", "Gene_name", "dbNSFP_gene")

#### include GLOWgenes and SGDS if included
if (!is.null(glowgenes_path)){
  print("Include GLOWgenes ranking")
  glowgenes = read.delim(glowgenes_path, header = F, stringsAsFactors = F, quote = "", check.names=F)
  colnames(glowgenes) = c("SYMBOL", "score", "GLOWgenes")

  # The genes of the list (used to run GLOWgenes) are the genes from the panel: they get GLOWgenes = 0.
  # They are removed from the GLOWgenes output to avoid duplicated rows in the merge
  if (!is.null(genefilter_path)){
    panel_genes = data.frame(SYMBOL = unique(genefilter$V1), score = NA, GLOWgenes = 0, stringsAsFactors = F)
    glowgenes = rbind(panel_genes, glowgenes[!glowgenes$SYMBOL %in% panel_genes$SYMBOL, ])
  }

  vep = merge_by_gene(vep, glowgenes[c("SYMBOL", "GLOWgenes")], "SYMBOL", "SYMBOL", "GLOWgenes")
}

if (!is.null(SGDS_path)) {
  print("Include GLOWgenes SGDS")
  SGDS <- read.delim(SGDS_path, sep = ",", header = TRUE, stringsAsFactors = FALSE, quote = "", check.names = FALSE)
  colnames(SGDS) = c("SYMBOL", "SGDS", "GLOWgenes_best_ranking", "GLOWgenes_median_ranking")
  vep = merge_by_gene(vep, SGDS, "SYMBOL", "SYMBOL", "SGDS")
}

# Gene-Panel
if (!is.null(panels_path)){
  gene_panel = read.delim(panels_path, header = TRUE, stringsAsFactors = F, quote = "")
  vep = merge_by_gene(vep, gene_panel, "SYMBOL", "gene", "Gene-Panel")
}

#### OMIM
if (!is.null(omim_path)){
  print("Include OMIM")
  omim = read.delim(omim_path, header = F, stringsAsFactors = F, comment.char = "#", quote = "", check.names=F)
  colnames(omim) = c("Chromosome", "Genomic_Position_Start", "Genomic Position End", "Cyto_Location", "Computed_Cyto_Location", "MIM_Number",
    "Gene_Symbols", "Gene_Name",	"Approved_Gene_Symbol", "Entrez_Gene_ID", "Ensembl_Gene_ID", "Comments", "Phenotypes", "Mouse_Gene_Symbol-ID")
  vep = merge_by_gene(vep, omim, "SYMBOL", "Approved_Gene_Symbol", "OMIM")
}

#### Region dictionary
if (!is.null(dict_region_path)){
  dict_region = read.csv(dict_region_path, header = F, sep = ",", stringsAsFactors = F)
  priority_list = c("SPLICING", "5UTR", "3UTR", "ncRNA", "regulatory", "UPSTREAM", "DOWNSTREAM", "EXONIC", "INTRONIC", "INTERGENIC", "-")
  dict_region$V2[is.na(dict_region$V2)] = "-"
  dict_region$V2 = factor(dict_region$V2, priority_list)
  rownames(dict_region) = dict_region$V1
}

# include domino
domino = read.delim(dominopath, header = TRUE, stringsAsFactors = F, quote = "")
vep = merge_by_gene(vep, domino, "SYMBOL", "Gene_name", "domino")

# include tissue expression
expression = read.delim(expression_path, header = TRUE, stringsAsFactors = F, quote = "")
vep = merge_by_gene(vep, expression, "SYMBOL", "Gene.name", "expression")


### create output dataframe
df_out  = data.frame(row.names = 1:nrow(vep), stringsAsFactors = F)


#==================================#
# Basic information of the variant #
#==================================#
print("Basic information of the variant")

df_out$CHROM = sub(":.*$", "", vep$Location)
df_out$POS = as.numeric(unlist(lapply(vep$`#Uploaded_variation`, function(x) rev(strsplit(x, "_")[[1]])[2])))
df_out$REF = vep$USED_REF
df_out$ALT = vep$Allele

df_out$Location = vep$Location
df_out$SYMBOL = vep$SYMBOL
df_out$Gene_full_name = vep$Gene_full_name
if (!is.null(glowgenes_path)) df_out$GLOWgenes = vep$GLOWgenes
if (!is.null(SGDS_path)) {
  df_out$SGDS = vep$SGDS
  df_out$GLOWgenes_best_ranking = vep$GLOWgenes_best_ranking
  df_out$GLOWgenes_median_ranking = vep$GLOWgenes_median_ranking
}
df_out$VARIANT_CLASS = vep$VARIANT_CLASS
df_out$Panels_name = vep$panels


#=====================#
# Feature information #
#=====================#
print("Feature information")

df_out$Existing_variation = vep$Existing_variation
# Region with the highest priority among the consequences of the variant (NA if none is in the dictionary)
if (!is.null(dict_region_path)) {
  df_out$Genomic_region = vapply(vep$Consequence, function(x) {
    regions = dict_region[strsplit(x, ",")[[1]], 2]
    if (all(is.na(regions))) return(NA_character_)
    as.character(regions[which.min(regions)])
  }, character(1), USE.NAMES = FALSE)
}
df_out$CANONICAL = vep$CANONICAL
df_out$Feature = vep$Feature
df_out$Feature_type = vep$Feature_type
df_out$BIOTYPE = vep$BIOTYPE
df_out$Consequence = vep$Consequence
df_out$INTRON = vep$INTRON
df_out$EXON = vep$EXON
df_out$HGVSc = vep$HGVSc
df_out$HGVSp = vep$HGVSp
df_out$DISTANCE = as.numeric(vep$DISTANCE)
df_out$STRAND = vep$STRAND
df_out$Interpro_domain = vep$Interpro_domain
df_out$Domino_Score = vep$Domino_Score


#===============#
# Pathogenicity #
#===============#
print("Pathogenicity")

df_out$CLNSIG = vep$ClinVar_CLNSIG
df_out$CLNREVSTAT = vep$ClinVar_CLNREVSTAT
df_out$CLNDN = vep$ClinVar_CLNDN
df_out$CLNSIGCONF = vep$ClinVar_CLNSIGCONF                                                                      
df_out$OMIM_phenotype = vep$Phenotypes
df_out$Orphanet_disorder = vep$Orphanet_disorder
df_out$Orphanet_association_type = vep$Orphanet_association_type
df_out$HPO_name = vep$HPO_name
df_out$PUBMED = vep$PUBMED





#=============#
# Frequencies #
#=============#
print("Frequencies")

df_out$gnomADg_AF = first_num(vep$gnomADg_AF)
df_out$gnomADg_AC = first_num(vep$gnomADg_AC)
df_out$gnomADg_AN = first_num(vep$gnomADg_AN)
df_out$gnomADg_nhomalt = first_num(vep$gnomADg_nhomalt)
df_out$gnomADg_cov_median = round(mean_num(vep$gnomADg_cov_median))
df_out$gnomADg_cov_perc_20x = round(mean_num(vep$gnomADg_cov_perc_20x), 2)
df_out$gnomADg_filter = vep$gnomADg_filt
df_out$gnomADg_popmax = vep$gnomADg_grpmax
df_out$gnomADg_AF_popmax = vep$gnomADg_AF_grpmax
df_out$gnomADg_AC_popmax = first_num(vep$gnomADg_AC_grpmax)
df_out$gnomADg_AF_nfe = first_num(vep$gnomADg_AF_nfe)
df_out$gnomADg_AC_nfe = first_num(vep$gnomADg_AC_nfe)

df_out$gnomADe_AF = first_num(vep$gnomADe_AF)
df_out$gnomADe_AC = first_num(vep$gnomADe_AC)
df_out$gnomADe_AN = first_num(vep$gnomADe_AN)
df_out$gnomADe_nhomalt = first_num(vep$gnomADe_nhomalt)
df_out$gnomADe_cov_median = round(mean_num(vep$gnomADe_cov_median))
df_out$gnomADe_cov_perc_20x = round(mean_num(vep$gnomADe_cov_perc_20x), 2)
df_out$gnomADe_filter = vep$gnomADe_filt
df_out$gnomADe_popmax = vep$gnomADe_grpmax
df_out$gnomADe_AF_popmax = vep$gnomADe_AF_grpmax
df_out$gnomADe_AC_popmax = first_num(vep$gnomADe_AC_grpmax)
df_out$gnomADe_AF_nfe = first_num(vep$gnomADe_AF_nfe)
df_out$gnomADe_AC_nfe = first_num(vep$gnomADe_AC_nfe)

df_out$kaviar_AF = vep$Kaviar_AF
df_out$kaviar_AC = vep$Kaviar_AC
df_out$CSVS_AF = first_num(vep$CSVS_AF)
df_out$CSVS_AC = first_num(vep$CSVS_AC)
df_out$FJD_MAF_AF = first_num(vep$FJD_MAF_AF)
df_out$FJD_MAF_AC = first_num(vep$FJD_MAF_AC)
##add new columns del MAF_FJD de DHR vs pseudocontroles (SON DE OJO LOS PSEUDOCONTROLES)
df_out$FJD_MAF_AF_DS_IRD = first_num(vep$FJD_MAF_AF_DS_irdt)
df_out$FJD_MAF_AC_DS_IRD = first_num(vep$FJD_MAF_AC_DS_irdt)
df_out$FJD_MAF_AF_P_IRD = first_num(vep$FJD_MAF_AF_P_eyeg)
df_out$FJD_MAF_AC_P_IRD = first_num(vep$FJD_MAF_AC_P_eyeg)
                                             
df_out$denovoVariants_SAMPLE_CT = vep$denovoVariants_SAMPLE_CT





#==========================#
# Pathogenicity prediction #
#==========================#
print("Pathogenicity prediction")

df_out$CADD_PHRED = as.numeric(vep$CADD_PHRED)
df_out$CADD_RAW = as.numeric(vep$CADD_RAW)
df_out$MutScore = as.numeric(vep$Mut_Score)
df_out$REVELScore = as.numeric(vep$REVEL_Score)

# Normalise the predictions to D (damaging), T (tolerated) or "" (no prediction).
# All values are compared in lower case.
patho_norm_func = function(predictions){
  predictions = gsub(";", ",", predictions)
  predictions = tolower(predictions)
  # VEP SIFT/PolyPhen (--everything) include the score: "tolerated(0.06)"
  predictions = gsub("\\([^)]*\\)", "", predictions)
  vapply(predictions, function(x) {
    y = strsplit(x,",")[[1]]
    y = y[!y %in% c("-", ".", "u", "")]
    y[y %in% c("tolerated", "tolerated_low_confidence", "benign", "tolerant", "n", "l", "p", "t")] = "T"
    y[y %in% c("deleterious", "deleterious_low_confidence", "probably_damaging",
               "possibly_damaging", "a", "m", "h", "d", "dominant", "recessive")] = "D"
    if ("D" %in% y) { return("D") }
    else if ("T" %in% y) { return("T") }
    else {return("")}
  }, character(1), USE.NAMES = FALSE)
}

df_pathogenic_predictors = data.frame(row.names = 1:nrow(vep))
df_pathogenic_predictors$SIFT = patho_norm_func(vep$SIFT)
df_pathogenic_predictors$PolyPhen = patho_norm_func(vep$PolyPhen)
df_pathogenic_predictors$Polyphen2_HDIV_pred = patho_norm_func(vep$Polyphen2_HDIV_pred)
df_pathogenic_predictors$Polyphen2_HVAR_pred = patho_norm_func(vep$Polyphen2_HVAR_pred)
df_pathogenic_predictors$LRT_pred = patho_norm_func(vep$LRT_pred)
df_pathogenic_predictors$`M-CAP_pred` = patho_norm_func(vep$`M-CAP_pred`)
df_pathogenic_predictors$MetaLR_pred = patho_norm_func(vep$MetaLR_pred)
df_pathogenic_predictors$MetaSVM_pred = patho_norm_func(vep$MetaSVM_pred)
df_pathogenic_predictors$MutationAssessor_pred = patho_norm_func(vep$MutationAssessor_pred)
df_pathogenic_predictors$MutationTaster_pred = patho_norm_func(vep$MutationTaster_pred)
df_pathogenic_predictors$PROVEAN_pred = patho_norm_func(vep$PROVEAN_pred)
df_pathogenic_predictors$FATHMM_pred = patho_norm_func(vep$FATHMM_pred)
df_pathogenic_predictors$MetaRNN_pred = patho_norm_func(vep$MetaRNN_pred)
df_pathogenic_predictors$PrimateAI_pred = patho_norm_func(vep$PrimateAI_pred)
df_pathogenic_predictors$DEOGEN2_pred = patho_norm_func(vep$DEOGEN2_pred)
df_pathogenic_predictors$BayesDel_addAF_pred = patho_norm_func(vep$BayesDel_addAF_pred)
df_pathogenic_predictors$BayesDel_noAF_pred = patho_norm_func(vep$BayesDel_noAF_pred)
df_pathogenic_predictors$ClinPred_pred = patho_norm_func(vep$ClinPred_pred)
df_pathogenic_predictors$`LIST-S2_pred` = patho_norm_func(vep$`LIST-S2_pred`)
df_pathogenic_predictors$Aloft_pred = patho_norm_func(vep$Aloft_pred)
df_pathogenic_predictors$`fathmm-MKL_coding_pred` = patho_norm_func(vep$`fathmm-MKL_coding_pred`)
df_pathogenic_predictors$`fathmm-XF_coding_pred` = patho_norm_func(vep$`fathmm-XF_coding_pred`)
  

df_out$N_Pathogenic_pred = rowSums(df_pathogenic_predictors == "D")
df_out$N_Benign_pred = rowSums(df_pathogenic_predictors == "T")
df_out$N_predictions = df_out$N_Pathogenic_pred + df_out$N_Benign_pred
df_out$Pathogenic_pred = apply(df_pathogenic_predictors, 1, function(x) paste(names(x)[which(x == "D")], collapse = ","))
df_out$Benign_pred = apply(df_pathogenic_predictors, 1, function(x) paste(names(x)[which(x == "T")], collapse = ","))





#=====================#
# Splicing predictors #
#=====================#
print("Splicing predictors")

spliceai_cols = c("SpliceAI_SNV_SpliceAI", "SpliceAI_INDEL_SpliceAI")

# Select one SpliceAI prediction per row
for (j in spliceai_cols) {

  if (!j %in% colnames(vep)) {
    print(paste0("There is no ", j, " column"))
    vep[, (j) := NA_character_]
  }

  multi_gene_sites <- which(!is.na(vep[[j]]) & grepl(",", vep[[j]], fixed = TRUE))

  for (i in multi_gene_sites) {

    splice_predictions <- do.call(rbind, strsplit(strsplit(vep[[j]][i], ",", fixed = TRUE)[[1]], "|", fixed = TRUE))

    # Skip malformed annotations
    if (ncol(splice_predictions) < 10)
      next

    # If one prediction matches the annotated SYMBOL, keep it
    if (!is.na(vep$SYMBOL[i]) && vep$SYMBOL[i] %in% splice_predictions[, 2]) {
      selected_row <- which(splice_predictions[, 2] == vep$SYMBOL[i])[1]
    } else {
      # Otherwise keep the prediction with the highest DS score
      scores <- suppressWarnings(matrix(as.numeric(splice_predictions[, 3:6]), ncol = 4))
      max_scores <- suppressWarnings(apply(scores, 1, max, na.rm = TRUE))
      selected_row <- which.max(max_scores)
      if (length(selected_row) == 0) selected_row <- 1
    }

    set(vep, i = i, j = j, value = paste(splice_predictions[selected_row, ], collapse = "|"))
  }
}

# Use the SNV prediction when there is no INDEL prediction
no_indel <- is.na(vep$SpliceAI_INDEL_SpliceAI)
vep$SpliceAI_INDEL_SpliceAI[no_indel] <- vep$SpliceAI_SNV_SpliceAI[no_indel]

split_spliceai <- function(x) {

  if (is.na(x))
    return(rep(NA_character_, 10))

  parts <- strsplit(x, "|", fixed = TRUE)[[1]]
  length(parts) <- 10

  parts
}

SpliceAI <- data.frame(do.call(rbind, lapply(vep$SpliceAI_INDEL_SpliceAI, split_spliceai)), stringsAsFactors = FALSE)
colnames(SpliceAI) <- c("ALLELE", "SYMBOL", "DS_AG", "DS_AL", "DS_DG", "DS_DL", "DP_AG", "DP_AL", "DP_DG", "DP_DL")

df_out$SpliceAI_SYMBOL <- SpliceAI$SYMBOL
df_out$SpliceAI_DS_AG <- suppressWarnings(as.numeric(SpliceAI$DS_AG))
df_out$SpliceAI_DS_AL <- suppressWarnings(as.numeric(SpliceAI$DS_AL))
df_out$SpliceAI_DS_DG <- suppressWarnings(as.numeric(SpliceAI$DS_DG))
df_out$SpliceAI_DS_DL <- suppressWarnings(as.numeric(SpliceAI$DS_DL))

# Maximum DS score (NA when there is no SpliceAI score, instead of -Inf)
ds_scores <- df_out[, c("SpliceAI_DS_AG", "SpliceAI_DS_AL", "SpliceAI_DS_DG", "SpliceAI_DS_DL")]
df_out$SpliceAI_DS_Max <- ifelse(rowSums(!is.na(ds_scores)) == 0, NA,
                                 suppressWarnings(apply(ds_scores, 1, max, na.rm = TRUE)))

df_out$SpliceAI_DP_AG <- suppressWarnings(as.numeric(SpliceAI$DP_AG))
df_out$SpliceAI_DP_AL <- suppressWarnings(as.numeric(SpliceAI$DP_AL))
df_out$SpliceAI_DP_DG <- suppressWarnings(as.numeric(SpliceAI$DP_DG))
df_out$SpliceAI_DP_DL <- suppressWarnings(as.numeric(SpliceAI$DP_DL))

df_out$ada_score <- as.numeric(vep$ada_score)
df_out$rf_score <- as.numeric(vep$rf_score)

df_out$MaxEntScan_alt <- as.numeric(vep$MaxEntScan_alt)
df_out$MaxEntScan_diff <- as.numeric(vep$MaxEntScan_diff)
df_out$MaxEntScan_ref <- as.numeric(vep$MaxEntScan_ref)


#============================#
# Conservation and phylogeny #
#============================#
print("Conservation and phylogeny")

df_out$LoFtool = as.numeric(vep$LoFtool)
#antiguo "ExACpLI ahora es pLI_gene_value
df_out$ExACpLI = as.numeric(vep$pLI_gene_value)
df_out$gnomAD_exomes_CCR = vep$gnomAD_exomes_CCR
df_out$phastCons30way_mammalian = as.numeric(vep$phastCons470way_mammalian)
df_out$phyloP30way_mammalian = as.numeric(vep$phyloP470way_mammalian)
df_out$MGI_mouse_phenotype = vep$MGI_mouse_phenotype_filt



#=====================================================#
#Expression, process, route, function and interaction #
#=====================================================#
print("Expression, process, route, function and interaction")

df_out$GTEx_V8_gene = vep$GTEx_V8_eQTL_gene
df_out$GTEx_V8_tissue = vep$GTEx_V8_eQTL_tissue
df_out$`Expression_GNF-Atlas` = vep$Expression.GNF.Atlas.
df_out$Pathway_KEGG = vep$Pathway.KEGG._full
df_out$GO_biological_process = vep$GO_biological_process
df_out$GO_cellular_component = vep$GO_cellular_component
df_out$GO_molecular_function = vep$GO_molecular_function
df_out$Interactions_IntAct = vep$Interactions.IntAct.

df_out$retina_RNA_tissue_consensus = round(vep$retina,2)
df_out$testis_RNA_tissue_consensus = round(vep$testis,2)
df_out$kidney_RNA_tissue_consensus = round(vep$kidney,2)
df_out$brain_max_RNA_tissue_consensus = round(vep$brain_max,2)
df_out$glands_max_RNA_tissue_consensus = round(vep$glands_max,2)
df_out$digestive_max_RNA_tissue_consensus = round(vep$digestive_max,2)
df_out$heart_RNA_tissue_consensus = round(vep$heart.muscle,2)
df_out$liver_RNA_tissue_consensus = round(vep$liver,2)
df_out$lung_RNA_tissue_consensus = round(vep$lung,2)
df_out$pancreas_RNA_tissue_consensus = round(vep$pancreas,2)
df_out$skel_muscle_RNA_tissue_consensus = round(vep$skeletal.muscle,2)
df_out$skin_RNA_tissue_consensus = round(vep$skin,2)
df_out$mean_expression_RNA_tissue_consensus = round(vep$mean_exp,2)
df_out$retina_ratio_exp_RNA_tissue_consensus = round(vep$retina_ratio, 2)
                           
df_out$Original_pos = vep$SAMPLE_Original_pos
df_out$variant_id = vep$SAMPLE_variant_id



#====================#
# Sample information #
#====================#
print("Sample information")

# Sample columns are SAMPLE_{sample}_{field}. The merged VCF also has SAMPLE_{sample}_{program}_GT columns,
# so a sample is a name with both _GT and _GD columns (or with _GT if there are no _GD columns).
# This also works with sample names that contain "_".
gt_columns = grep("^SAMPLE_.+_GT$", colnames(vep), value = TRUE)
samples = unique(sub("_GT$", "", sub("^SAMPLE_", "", gt_columns)))
samples_with_gd = samples[paste0("SAMPLE_", samples, "_GD") %in% colnames(vep)]
if (length(samples_with_gd) > 0) samples = samples_with_gd
print(paste0("Samples: ", paste(samples, collapse = ", ")))

# Copy the columns SAMPLE_{sample}_{field} to df_out as {sample}_{field}
copy_sample_fields <- function(df, sample, fields) {
  src = paste0("SAMPLE_", sample, "_", fields)
  present = src %in% colnames(vep)
  if (any(!present)) print(paste0("There is no ", paste(fields[!present], collapse = ", "), " information of the sample ", sample))
  for (k in which(present)) df[[paste0(sample, "_", fields[k])]] = vep[[src[k]]]
  df
}

# ROH from AutoMap (the same file is used for all the samples)
roh = rep("NaN", nrow(df_out))
if (!is.null(automap_path) && file.exists(automap_path)) {
  automap_lines = readLines(automap_path)
  automap_lines = automap_lines[!startsWith(automap_lines, "#") & nzchar(automap_lines)]
  roh = rep("False", nrow(df_out))
  if (length(automap_lines) > 0) {
    automap = read.delim(text = automap_lines, header = F, stringsAsFactors = F)
    chrom = sub("^chr", "", df_out$CHROM)
    for (i in seq_len(nrow(automap))) {
      roh[which(chrom == sub("^chr", "", automap$V1[i]) & df_out$POS >= automap$V2[i] & df_out$POS <= automap$V3[i])] = "True"
    }
  }
} else {
  print("There is no AutoMap information")
}

for (sample in samples) {
  df_out = copy_sample_fields(df_out, sample, c("GT", "VAF", "AD", "DP", "SF", "GD", "GQ", "FT"))
  df_out[[paste0(sample, "_ROH")]] = roh
}

df_out$hiConfDeNovo = vep$SAMPLE_hiConfDeNovo
df_out$loConfDeNovo = vep$SAMPLE_loConfDeNovo



#==============================================#
#Extra sample information (individual callers) #
#==============================================#

# Fields SAMPLE_{sample}_{program}_{field} of each sample (the ones with "_" after the sample name)
for (sample in samples) {
  prefix = paste0("SAMPLE_", sample, "_")
  sample_columns = colnames(vep)[startsWith(colnames(vep), prefix)]
  # Exclude the columns of other samples whose name starts with this sample name (e.g. S1 and S1_father)
  for (other in setdiff(samples, sample)) {
    sample_columns = sample_columns[!startsWith(sample_columns, paste0("SAMPLE_", other, "_"))]
  }
  program_fields = substring(sample_columns, nchar(prefix) + 1)
  program_fields = program_fields[grepl("_", program_fields, fixed = TRUE)]
  df_out = copy_sample_fields(df_out, sample, program_fields)
}


# #======== #
# # Sorting #
# #======== #

## Sort the output (chromosomes in natural order: 1, 2, ..., 22, X, Y, M)
chrom_key = sub("^chr", "", df_out$CHROM)
chrom_num = suppressWarnings(as.numeric(chrom_key))
chrom_num[chrom_key == "X"] = 23
chrom_num[chrom_key == "Y"] = 24
chrom_num[chrom_key %in% c("M", "MT")] = 25

if (!is.null(glowgenes_path)){
  df_out = df_out[order(df_out$GLOWgenes, chrom_num, chrom_key, df_out$POS),]
} else {
  df_out = df_out[order(chrom_num, chrom_key, df_out$POS),]
}


#==============#
# Write output #
#==============#
df_out[df_out=="-"] = NA
write.table(df_out, output, sep = "\t", col.names = T, row.names = F, quote = F, na = "")
