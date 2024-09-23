# load and install necessary packages
if (!require(pacman)) install.packages("pacman")
pacman::p_load(ape,
               adegenet,
               ggplot2,
               ggraph,
               dplyr,
               tidygraph,
               stringr,
               igraph,
               patchwork
)


# read SNP matrix
TB_snp <- read.csv("", row.names = 1, check.names = F)

# read lineage data
lineage_data <- read.csv(""/, row.names = 1, check.names = F)

# new dataframe
df_lin <- lineage_data %>%
  distinct(Sample1, Lineage1)
df_lin[448,1] <- "2023-622" 
df_lin[448,2] <- "Unknown"


# simplified lineage column added to the new dataframe
df_lin <- df_lin %>%
  mutate(simplified_lineage = str_extract(Lineage1, "^[^.]+"))


# create graph object
clustx <- gengraph(as.matrix(TB_snp), 
                   cutoff =20)


# plot results
p <- ggraph( as_tbl_graph(clustx$graph), layout = "mds" ) +
  geom_edge_link(color="#808080") +
  geom_node_point(aes(color=igraph::vertex_attr(clustx$graph)$color), size=3) +
  theme_classic() + 
  ggtitle("SNP distance threshold - 12")+
  theme(legend.position = "none",
        axis.title = element_blank(),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        plot.title = element_text(hjust = 0.5, face = "bold", size=14)
  )

p


p1 <- ggraph(as_tbl_graph(clustx$graph), layout = "mds" ) +
  geom_edge_link(color="#808080") +
  geom_node_point(aes(color=df_lin$simplified_lineage), size=3) +
  theme_classic() + 
  ggtitle("SNP distance threshold - 12")+
  theme(legend.position = "right",
        axis.title = element_blank(),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        plot.title = element_text(hjust = 0.5, face = "bold", size=14)
  )


p1


df <- data.frame(number=clustx$clust$csize)
pa <- ggplot(df, aes(x = factor(number))) + 
  geom_bar(fill = "blue", width = 0.9) + 
  labs(x = "cluster size", y = "Count", title = "Distribution of cluster size") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        panel.grid = element_blank())


pa

p + p1 + pa


# contignecy table lineages and cluster ID
df_lin$cluster_id <- clustx$clust$membership
lin_clust_table <- table(df_lin$cluster_id, df_lin$simplified_lineage )
write.csv(lin_clust_table, "~/Contignecy_Tables/20.csv")


