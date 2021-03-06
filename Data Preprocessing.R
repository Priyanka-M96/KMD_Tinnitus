
#Data Preprocessing
library(dplyr)
library(tidyverse)

df <- read_rds("190426_charite_tinnitus.rds") %>%
  arrange(.testdatum) %>%
  group_by(.jour_nr) %>%
  slice(1) %>%
  ungroup() %>%
  filter(.phase == "A") %>%
  mutate(phqk_paniksyndrom = if_else(phqk_phqk_2a +
                                       phqk_phqk_2b +
                                       phqk_phqk_2c +
                                       phqk_phqk_2d +
                                       phqk_phqk_2e == 5, 1, 0)) %>%
  select(.jour_nr,
         .age,
         acsa_acsa,
         adsl_adsl_sum,
         bi_erschoepfung, bi_magen, bi_glieder, bi_herz, bi_beschwerden,
         bsf_geh, bsf_eng, bsf_aerg, bsf_an_de, bsf_mued, bsf_tnl,
         isr_deprsyn, isr_angstsyn, isr_zwasyn, isr_somasyn, isr_essstsyn,
         isr_zusatz, isr_isr_ges,
         phqk_depressivitaet, phqk_paniksyndrom,
         psq_anford, psq_anspan, psq_freude, psq_sorgen, psq_psq_sum,
         schmerzskal_beein10, schmerzskal_haeuf10, schmerzskal_staerke10,
         ses_ses_affektiv, ses_ses_sensorisch,
         sf8_bp_sf36ks, sf8_gh_sf36ag, sf8_mcs8, sf8_mh_sf36pw, sf8_pcs8,
         sf8_pf_sf36kf, sf8_re_sf36er, sf8_rp_sf36kr, sf8_sf_sf36sf, sf8_vt_sf36vit,
         sozk_soz01_male, sozk_soz02_german, sozk_soz05_partner, sozk_soz06_married,
         sozk_soz09_abitur, sozk_soz10_keinAbschl, sozk_soz11_job, sozk_soz18_selbstst, 
         sozk_soz1920_krank, sozk_soz21_tindauer, sozk_soz2224_psycho, sozk_soz25_numdoc,
         swop_sw, swop_opt, swop_pes,
         tq_aku, tq_co, tq_em, tq_inti, tq_pb, tq_sl, tq_som, tq_tf,
         tinskal_beein10, tinskal_haeuf10, tinskal_laut10,
         starts_with("tlq"), -tlq_timestamp
  ) %>%
  drop_na()

originaldf <- read_rds("190426_charite_tinnitus.rds")
###################################### All Features Except Journ no ####################################
df_allF <- select(df,-c(.jour_nr))

#Data frame with all features "Scaled" except journ no
df_allF_scaled<-scale(df_allF)%>%data.frame()

###################################### Finding Correlation ####################################

library(sqldf)

correlations <- function(cor_threshold) {

  correlated_coloumns <- data.frame(F1 = character(),F2 = character())
  
  #cat("\ncorrelation with 90%:\n")
  matriz_cor <- cor(df_allF,method = "spearman")
  
  
  for (i in 1:nrow(matriz_cor)){
    correlations <-  which((abs(matriz_cor[i,]) > cor_threshold) & (matriz_cor[i,] != 1))
    matriz_cor[correlations,i] <- NA
    
    if(length(correlations)> 0){
      #lapply(correlations,FUN =  function(x) (cat("\t",paste(colnames(test)[i], "with",colnames(test)[x]), "\n")))
      correlated_coloumns <-  rbind(correlated_coloumns,data.frame(F1=colnames(df_allF)[i],F2=colnames(df_allF)[correlations]))
      rownames(correlated_coloumns) <- NULL
    }
  }
  
  
  x <- as.list(sqldf("SELECT distinct(F1) as feat FROM correlated_coloumns UNION SELECT distinct(F2) FROM correlated_coloumns") )
  count <- data.frame(matrix(ncol = length(x$feat), nrow = 0))
  count[1,] <- 0
  colnames(count) <- x$feat
  
  for (i in correlated_coloumns$F1) {
    count[1,which(colnames(count) == i)] <- count[1,which(colnames(count) == i)] + 1
  }
  for (i in correlated_coloumns$F2) {
    count[1,which(colnames(count) == i)] <- count[1,which(colnames(count) == i)] + 1
  }
  count <- as.data.frame(t(apply(count, 1, FUN=function(x) sort(x, decreasing=TRUE))))
  
  x <- c()
  k <- 1
  
  for ( i in 1:length(colnames(count))) {
    if(i < length(colnames(count))) {
      for (j in 1:length(correlated_coloumns$F1)) {
        if(colnames(count[i]) == correlated_coloumns$F1[j])
        {
          num <- which(colnames(count) == correlated_coloumns$F2[j])
          if((correlated_coloumns$F2[j] %in% x) == FALSE) {
            x[k] <- colnames(count[num])
            count <- select(count,-num)
            k <- k + 1 
          }
        }
      }
      for (j in 1:length(correlated_coloumns$F2)) {
        if(colnames(count[i]) == correlated_coloumns$F2[j])
        {
          num <- which(colnames(count) == correlated_coloumns$F1[j])
          if((correlated_coloumns$F1[j] %in% x) == FALSE) {
            x[k] <- colnames(count[num])
            count <- select(count,-num)
            k <- k + 1 
          }
        }
      }
    }
    else 
      break()
  }
  return(x)
}
cor_threshold <- 0.9

x <- correlations(cor_threshold)  
  
#dropping the columns
df_noCorr <- select(df_allF,-x)

#Data frame with reduced features "Scaled"
df_noCorr_scaled <- scale(df_noCorr)%>%data.frame()
