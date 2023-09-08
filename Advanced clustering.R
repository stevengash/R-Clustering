# Load the core tidyverse and tidymodels
#install.packages ("tidyverse")
#install.packages ("tidymodels")

library(tidyverse)
library(tidymodels)
#install.packages("dplyr")
library(dplyr)
# Read the csv file into a tibble
seeds <- read_csv(file = "seeds.csv")
#colnames(seeds)

# Narrow down to desired features
seeds_select <- seeds %>% 
  select(!groove_length) %>% 
  mutate(species = factor(species))

# Specify a recipe for PCA and extract 2 PCA components
features_2d <- recipe(~ ., data = seeds_select) %>% 
  update_role(species, new_role = "ID") %>% 
  step_normalize(all_predictors()) %>% 
  step_pca(all_predictors(), num_comp = 2, id = "pca") %>% 
  prep() %>% 
  bake(new_data = NULL)

# Preprocess and obtain data for clustering
# Drop target column and normalize data
seeds_features<- recipe(~ ., data = seeds_select) %>% 
  step_rm(species) %>% 
  step_normalize(all_predictors()) %>% 
  prep() %>% 
  bake(new_data = NULL)

set.seed(2056)
# Fit and predict clusters with k = 3
final_kmeans <- kmeans(seeds_features, centers = 3, nstart = 100, iter.max = 1000)

# Add cluster prediction to the data set
results_kmeans <- augment(final_kmeans, seeds_features) %>% 
  # Bind pca_data - features_2d
  bind_cols(features_2d)

results_kmeans %>% 
  slice_head(n = 5)

  #install.packages ("plotly")
library(plotly)
# Plot km_cluster assignment on the PC data
cluster_plot <- results_kmeans %>% 
  ggplot(mapping = aes(x = PC1, y = PC2)) +
  geom_point(aes(shape = .cluster), size = 2) +
  scale_color_manual(values = c("darkorange","purple","cyan4"))

# Make plot interactive
ggplotly(cluster_plot)
# Plot km_cluster assignment on the PC data
clust_spc_plot <- results_kmeans %>% 
  ggplot(mapping = aes(x = PC1, y = PC2)) +
  geom_point(aes(shape = .cluster, color = species), size = 2, alpha = 0.8) +
  scale_color_manual(values = c("darkorange","purple","cyan4"))

# Make plot interactive
ggplotly(clust_spc_plot)

# For reproducibility
set.seed(2056)

# Distance between observations matrix
d <- dist(x = seeds_features, method = "euclidean")

# Hierarchical clustering using Complete Linkage
seeds_hclust_complete <- hclust(d, method = "complete")

# Hierarchical clustering using Average Linkage
seeds_hclust_average <- hclust(d, method = "average")

# Hierarchical clustering using Ward Linkage
seeds_hclust_ward <- hclust(d, method = "ward.D2")

#install.packages("factoextra")
library(factoextra)

# Visualize cluster separations
fviz_dend(seeds_hclust_complete, main = "Complete Linkage")
# Visualize cluster separations
fviz_dend(seeds_hclust_average, main = "Average Linkage")
# Visualize cluster separations
fviz_dend(seeds_hclust_ward, main = "Ward Linkage")

#install.packages("cluster")
library(cluster)
#Compute ac values
ac_metric <- list(
  complete_ac = agnes(seeds_features, metric = "euclidean", method = "complete")$ac,
  average_ac = agnes(seeds_features, metric = "euclidean", method = "average")$ac,
  ward_ac = agnes(seeds_features, metric = "euclidean", method = "ward")$ac
)

ac_metric

# Determine and visualize optimal n. of clusters
#  hcut (for hierarchical clustering)
fviz_nbclust(seeds_features, FUNcluster = hcut, method = "wss")
# Visualize clustering structure for 3 groups
fviz_dend(seeds_hclust_ward, k = 3, main = "Ward Linkage")

# Hierarchical clustering using Ward Linkage
seeds_hclust_ward <- hclust(d, method = "ward.D2")

# Group data into 3 clusters
results_hclust <- tibble(
  cluster_id = cutree(seeds_hclust_ward, k = 3)) %>% 
  mutate(cluster_id = factor(cluster_id)) %>% 
  bind_cols(features_2d)

results_hclust %>% 
  slice_head(n = 5)
# Compare k-m and hc
results_hclust %>% 
  count(species, cluster_id) %>% 
  rename(cluster_id_hclust = cluster_id, n_hclust = n) %>% 
  bind_cols(results_kmeans %>% 
              count(species, .cluster) %>%
              select(!species) %>% 
              rename(cluster_id_kmclust = .cluster, n_kmclust = n))

# Plot h-cluster assignment on the PC data
hclust_spc_plot <- results_hclust %>% 
  ggplot(mapping = aes(x = PC1, y = PC2)) +
  geom_point(aes(shape = cluster_id, color = species), size = 2, alpha = 0.8) +
  scale_color_manual(values = c("darkorange","purple","cyan4"))

# Make plot interactive
ggplotly(hclust_spc_plot)

library(rmarkdown)
#render("Advanced clustering.R")
#render("Advanced clustering.R", output_format = "word_document")

