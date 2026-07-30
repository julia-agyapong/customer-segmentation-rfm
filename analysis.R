# ==============================================================================
# Customer Segmentation Using RFM Analysis and K-Means Clustering
# Evidence from an Online Retail Dataset
#
# Juliana Agyapong
# M.S. Marketing Analytics, Illinois Institute of Technology
# ==============================================================================

library(readr)
library(dplyr)
library(lubridate)
library(ggplot2)
library(purrr)
library(cluster)

# ------------------------------------------------------------------------------
# 1. LOAD DATA
# ------------------------------------------------------------------------------

data.df <- read_csv("data/online_retail_II.csv")

# ------------------------------------------------------------------------------
# 2. DATA CLEANING
# ------------------------------------------------------------------------------
# Remove cancelled orders, non-positive prices, and missing Customer IDs;
# convert InvoiceDate to a proper date-time format.

clean.df <- data.df %>%
  filter(!grepl("^C", Invoice)) %>%      # remove cancelled orders
  filter(Price > 0) %>%                   # remove non-positive prices
  filter(!is.na(Customer.ID)) %>%         # remove missing customer IDs
  mutate(InvoiceDate = mdy_hm(InvoiceDate))  # convert text to real date-time

# ------------------------------------------------------------------------------
# 3. RFM TABLE CONSTRUCTION
# ------------------------------------------------------------------------------

reference_date <- max(clean.df$InvoiceDate) + days(1)

rfm.df <- clean.df %>%
  mutate(LineTotal = Quantity * Price) %>%
  group_by(Customer.ID) %>%
  summarise(
    Recency   = as.numeric(difftime(reference_date, max(InvoiceDate), units = "days")),
    Frequency = n_distinct(Invoice),
    Monetary  = sum(LineTotal)
  )

# ------------------------------------------------------------------------------
# 4. CORRELATION ANALYSIS (Spearman)
# ------------------------------------------------------------------------------

# Frequency vs Monetary
cor_result <- cor.test(rfm.df$Frequency, rfm.df$Monetary, method = "spearman")
cor_result

# Full RFM correlation matrix (Recency, Frequency, Monetary)
rfm_matrix <- rfm.df %>%
  select(Recency, Frequency, Monetary) %>%
  cor(method = "spearman")
print(rfm_matrix)

# ------------------------------------------------------------------------------
# 5. LOG TRANSFORMATION & SCALING (for clustering)
# ------------------------------------------------------------------------------

rfm.df <- rfm.df %>%
  mutate(Log_Monetary = log(Monetary + 1))

log_monetary_plot <- ggplot(rfm.df, aes(x = Log_Monetary)) +
  geom_histogram(bins = 40, fill = "darkorange") +
  labs(title = "Distribution of Log-Transformed Monetary Value",
       x = "Log(Monetary Value)",
       y = "Number of customers")
log_monetary_plot
ggsave("figures/log_monetary_plot.png", plot = log_monetary_plot, width = 8, height = 6, dpi = 300)

scaled.df <- rfm.df %>%
  select(Frequency, Log_Monetary) %>%
  scale()

# ------------------------------------------------------------------------------
# 6. ELBOW METHOD (choosing k)
# ------------------------------------------------------------------------------

set.seed(123)
wss <- map_dbl(1:10, function(k) {
  kmeans(scaled.df, centers = k, nstart = 25)$tot.withinss
})

elbow_plot <- ggplot(data.frame(k = 1:10, wss = wss), aes(x = k, y = wss)) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(color = "steelblue", size = 2.5) +
  scale_x_continuous(breaks = 1:10) +
  labs(title = "Elbow Method for Choosing k",
       subtitle = "Frequency and Log-Transformed Monetary Value",
       x = "Number of Clusters (k)",
       y = "Total Within-Cluster Sum of Squares") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())
elbow_plot
ggsave("figures/elbow_plot.png", plot = elbow_plot, width = 7, height = 5, dpi = 300)

# ------------------------------------------------------------------------------
# 7. FINAL K-MEANS CLUSTERING (k = 4)
# ------------------------------------------------------------------------------

set.seed(123)
kmeans_result_k4 <- kmeans(scaled.df, centers = 4, nstart = 25)
rfm.df$Cluster_k4 <- as.factor(kmeans_result_k4$cluster)

table(rfm.df$Cluster_k4)

rfm.df %>%
  group_by(Cluster_k4) %>%
  summarise(
    Customers = n(),
    Mean_Frequency = mean(Frequency),
    Mean_Monetary = mean(Monetary)
  )

# Cluster visualization (Frequency vs Log-Monetary, with centroids)
centroids <- rfm.df %>%
  group_by(Cluster_k4) %>%
  summarise(
    Frequency = mean(Frequency),
    Log_Monetary = mean(Log_Monetary)
  )

cluster_plot <- ggplot(rfm.df, aes(x = Frequency, y = Log_Monetary, color = Cluster_k4)) +
  geom_point(size = 2, alpha = 0.6) +
  scale_color_brewer(palette = "Set2") +
  geom_point(data = centroids, aes(x = Frequency, y = Log_Monetary),
             color = "black", shape = 18, size = 6, inherit.aes = FALSE) +
  labs(title = "Customer Segments by Frequency and Monetary Value",
       subtitle = "K-means clustering (k = 4); black diamonds mark cluster centroids",
       x = "Frequency (number of orders)",
       y = "Log(Monetary Value)",
       color = "Cluster") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())
cluster_plot
ggsave("figures/cluster_plot.png", plot = cluster_plot, width = 8, height = 6, dpi = 300)

# ------------------------------------------------------------------------------
# 8. SILHOUETTE ANALYSIS (validating k = 4 against k = 2-10)
# ------------------------------------------------------------------------------

set.seed(123)
sil_widths <- map_dbl(2:10, function(k) {
  km <- kmeans(scaled.df, centers = k, nstart = 25)
  ss <- silhouette(km$cluster, dist(scaled.df))
  mean(ss[, 3])
})

sil_table <- data.frame(k = 2:10, avg_silhouette_width = round(sil_widths, 3))
print(sil_table)

# ------------------------------------------------------------------------------
# 9. PRINCIPAL COMPONENT ANALYSIS (Recency, Frequency, Log_Monetary)
# ------------------------------------------------------------------------------

pca_input <- rfm.df %>%
  select(Recency, Frequency, Log_Monetary) %>%
  scale()

pca_result <- prcomp(pca_input, center = TRUE, scale. = TRUE)
summary(pca_result)

pca_df <- as.data.frame(pca_result$x)
pca_df$Cluster_k4 <- as.factor(rfm.df$Cluster_k4)

pca_plot <- ggplot(pca_df, aes(x = PC1, y = PC2, color = Cluster_k4)) +
  geom_point(size = 2, alpha = 0.6) +
  scale_color_brewer(palette = "Set2") +
  labs(
    title = "Customer Segments in Principal Component Space",
    subtitle = "PCA on Recency, Frequency, and Log-Transformed Monetary Value",
    x = "PC1", y = "PC2", color = "Cluster"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))
pca_plot
ggsave("figures/pca_plot.png", plot = pca_plot, width = 8, height = 6, dpi = 300)

# ------------------------------------------------------------------------------
# 10. SESSION INFO (for reproducibility)
# ------------------------------------------------------------------------------

sessionInfo()
