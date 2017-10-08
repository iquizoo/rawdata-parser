# here are all the functions used in calculating results

# speed-accuracy tradeoff results
SAT <- function(RT, ACC, lisas_weight = SRT / SPE){
  # mean and standard deviation of RT (correct trials only)
  MRT <- mean(RT[ACC == 1], na.rm = TRUE)
  SRT <- sd(RT[ACC == 1], na.rm = TRUE)

  # mean and standard deviation of ACC
  PE <- mean(1 - ACC, na.rm = TRUE)
  SPE <- sd(ACC, na.rm = TRUE)

  # inverse efficiency score (IES) (Townsend & Ashby, 1978)
  IES <- MRT / (1 - PE)
  # FIX ME! rate of correct score (RCS) (Woltz&Was, 2006)
  RCS <- sum(ACC == 1, na.rm = TRUE) / sum(RT / 1000, na.rm = TRUE)
  # FIX ME! bin score (Hughes, Linck, Bowles, Koeth,&Bunting, 2014)
  BS <- NA
  # linear integrated speed-accuracy score (LISAS) (Vandierendonck, 2016)
  LISAS <- MRT + lisas_weight * PE

  # out put wrapper
  tibble(MRT, SRT, PE, SPE, IES, RCS, BS, LISAS, lisas_weight)
}

# BART task
BART <- function(rec){
  rec
}

# Control related
control <- function(rec){
  # browser()

  # individual level data preparing
  rec <- rec %>%
    # RT outlier checking (set ACC to -99)
    # using a two-step protocol (10.3389/fpsyg.2016.00823):
    mutate(
      # 1. lower absolute cutoffs (100)
      ACC = ifelse(RT < 100, -99, ACC),
      # 2. IQR-based outlier removal (Q1 - 1.5 * IQR ~ Q3 + 1.5 * IQR)
      ACC = ifelse(RT %in% boxplot.stats(RT)$out, -99, ACC)
    )

  # count trials
  counts <- rec %>%
    summarise(
      n_trial = n(),
      n_resp = sum(ACC != -1), # ACC of -1 is trials of no response
      n_include = sum(ACC != -1 & ACC != -99)
    )

  # set non-normal ACC as NA
  rec <- mutate(rec, ACC = ifelse(ACC == -1 | ACC == -99, NA, ACC))

  # calculating indices regardless of conditions
  total_index <- do(rec, SAT(.$RT, .$ACC))
  lisas_weight <- total_index$lisas_weight

  # calculate for each condition
  cond_score <- rec %>%
    group_by(SCat) %>%
    do(SAT(.$RT, .$ACC, lisas_weight)) %>%
    select(-lisas_weight) %>%
    ungroup()

  # calculate difference between two conditions
  diff_index <- cond_score %>%
    select(-SCat, -SPE, -SRT) %>%
    # 'incongruent/switch' - 'congruent/nonswitch' in case of confusion
    mutate_all(funs(. - lag(.))) %>%
    rename_all(funs(paste0(., "_diff"))) %>%
    slice(2)

  # condition index spreading
  cond_index <- cond_score %>%
    gather(index_name, index, MRT:LISAS) %>%
    unite(cond_index_name, index_name, SCat) %>%
    spread(cond_index_name, index)

  # cbind results
  cbind(counts, total_index, cond_index, diff_index)
}
