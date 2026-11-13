#--------------------------------------------------------------
# FIGURE 1: Islamic win margin and Islamic vote share in 1994
#--------------------------------------------------------------

source("replications/setup.R")

# Need to single out data to plot the observations within 2 percentage points 
# of threshold
outside_thre <- df_matched |> filter(abs(iwm94) > 0.02)
inside_thre <- df_matched |> filter(abs(iwm94) <= 0.02)

fig1 <- ggplot(df_matched, aes(x = vshr_islam1994, y = iwm94)) +
  geom_hline(yintercept = 0, color = "grey") +
  annotate("segment", x = 0, y = -1, xend = 0.75, yend = 0.5, color = "black") + 
  geom_point(data = outside_thre, alpha = 1, size = 1.1, color = 'grey50') + 
  geom_point(data = inside_thre, alpha = 1, size = 1.1, color = 'black') + 
  theme_classic() +
  theme(axis.text.y = element_text(angle = 90, hjust = 0.5, vjust = 0.5, size = 10),
        axis.text.x = element_text(size = 10)) +
  scale_x_continuous(limits = c(0, 0.75), breaks = seq(0, 0.75, by = 0.25), expand = c(0.02, 0), labels = scales::label_number(drop0trailing=TRUE)) +
  scale_y_continuous(limits = c(-1, 0.6), breaks = seq(-1, 0.5, by = 0.5), expand = c(0.02, 0), labels = scales::label_number(drop0trailing=TRUE)) + 
  labs(title= "Figure 1. Islamic win margin and Islamic vote share in 1994", 
       x = "Islamic vote share", 
       y = "Islamic win margin")

nrow(df_matched)

# Save the figure in the output folder
ggsave("output/figures/figure1.png", plot = fig1, width = 8, height = 6, dpi = 300)