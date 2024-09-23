# Load/install necessary package.
if (!require(pacman)) install.packages("pacman")
pacman::p_load(ggplot2,
               tidyr,
               dplyr,
               plotly,
               htmlwidgets
               )

# Define the path to your TSV file and read it
file_path <- "/home/rgadalla/tickets/COVID/BCCSUPPORT-999/plate_0110-0140_2024_amplicon_depth_summary.tsv"
data <- read.csv(file_path, sep = "\t")


# Reshape the data from wide to long format
data_long <- data %>%
  pivot_longer(
    cols = -c(PlateName, SampleName),
    names_to = "Amplicon",
    values_to = "Depth"
  )


# Making x-axis label more readable
data_long$Amplicon_ID <- factor(gsub(".*_(\\d+)$", "\\1", data_long$Amplicon), levels = c(1:99))
data_long$Highlight <- ifelse(data_long$Amplicon == "SARS.CoV.2_70", "Amplicon 70", "Other Amplicons")


# Create the boxplot using ggplot2
p <- ggplot(data_long, aes(x = Amplicon_ID, y = log10(Depth), fill=Highlight)) +
  geom_boxplot(outlier.size = 0.1) +
  scale_fill_manual(values = c("Amplicon 70" = "red", "Other Amplicons" = "grey"), guide=FALSE) +  # Color mapping
  theme_minimal()+
  theme(axis.text.x = element_text(angle=90, hjust = 1),
        panel.grid = element_blank()
        ) +
  labs(
    title = "Depth Distribution per Amplicon plate0110 to plate0140 (no controls)",
    x = "Amplicon",
    y = "Depth(log10)"
  )

# plot figure in html interactive format
p_plotly <- ggplotly(p)
htmlwidgets::saveWidget(p_plotly, "/home/rgadalla/tickets/COVID/BCCSUPPORT-999/depth_distribution_per_amplicon_2024.html")






