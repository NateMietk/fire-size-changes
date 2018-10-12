
 h <- mtbs_ecoreg %>%
   group_by(na_l2name, Year) %>%
   do(data.frame(rbind(smean.cl.boot(.$fire_km2, B = 10000)))) 
  
h_year <- mtbs_ecoreg %>%
 group_by(Year) %>%
 do(data.frame(rbind(smean.cl.boot(.$fire_km2, B = 10000)))) 
 
mtbs_ecoreg %>%
  filter(na_l2name != 'WATER') %>%
  ggplot(aes(x = Year, y = fire_km2)) +
  geom_point() +
  geom_smooth(method = sen) +
  facet_wrap(~na_l2name)

mtbs_sen <- as.data.frame(mtbs_ecoreg) %>%
  dplyr::select(Year, na_l2name, fire_km2) %>%
  group_by(na_l2name) %>%
  do(model = mblm(fire_km2 ~ Year, data = ., repeated = FALSE))
model_coef <- broom::tidy(mtbs_sen, model, conf.int = TRUE)
model_pred <- broom::augment(mtbs_sen, model)
df_pred <- broom::glance(mtbs_sen, model)

model_coef %>%
  ggplot(aes(estimate, term, color = term)) +
  geom_point() +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high))

df_pred %>%
  ggplot(aes(x = reorder(na_l2name, -r.squared), y = r.squared)) +
  geom_bar(stat = 'identity') +
  xlab('') + ylab('R Sqaure') +
  theme_pub() 

model_pred %>%
  ggplot(aes(x = fire_km2, y = .fitted)) +
  geom_point() +
  geom_smooth()




mean_fsr_p <- lvl1_eco_fsr_slim %>%
  filter(na_l1name != 'WATER') %>%
  ggplot(aes(x = reorder(na_l1name, -mean_fsr), y = mean_fsr)) +
  geom_bar(stat = 'identity') +
  geom_errorbar(aes(ymin = lower_95ci_fsr, ymax = upper_95ci_fsr), alpha=0.3) +
  xlab('') + ylab('Average fire rate of spread (pixels per day)') +
  theme_pub() 
ggsave(file = 'results/mean_fsr.pdf', mean_fsr_p, width = 6, height = 8, dpi=1200, scale = 3, units = "cm")