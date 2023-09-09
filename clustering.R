# Load the core tidyverse and make it available in your current R session
library(tidyverse)

# Read the csv file into a tibble
seeds <- read_csv(file = "seeds.csv")

# Print the first 5 rows of the data
seeds %>% 
  slice_head(n = 5)
# Explore dimension and type of columns
seeds %>% 
  glimpse()

library(skimr)

# Obtain Summary statistics
seeds %>% 
  skim()
# Narrow down to desired features
seeds_select <- seeds %>% 
  select(!groove_length) %>% 
  mutate(species = factor(species))

# View first 5 rows of the data
seeds_select %>% 
  slice_head(n = 5)
# Load the core tidymodels and make it available in your current R session
library(tidymodels)


# Specify a recipe for pca
pca_rec <- recipe(~ ., data = seeds_select) %>% 
  update_role(species, new_role = "ID") %>% 
  step_normalize(all_predictors()) %>% 
  step_pca(all_predictors(), num_comp = 2, id = "pca")

# Print out recipe
pca_rec

# Estimate required statistcs 
pca_estimates <- prep(pca_rec)

# Return preprocessed data using bake
features_2d <- pca_estimates %>% 
  bake(new_data = NULL)

# Print baked data set
features_2d %>% 
  slice_head(n = 5)
# Examine how much variance each PC accounts for
pca_estimates %>% 
  tidy(id = "pca", type = "variance") %>% 
  filter(str_detect(terms, "percent"))


theme_set(theme_light())
# Plot how much variance each PC accounts for
pca_estimates %>% 
  tidy(id = "pca", type = "variance") %>% 
  filter(terms == "percent variance") %>% 
  ggplot(mapping = aes(x = component, y = value)) +
  geom_col(fill = "midnightblue", alpha = 0.7 ) +
  ylab("% of total variance")
# Visualize PC scores
features_2d %>% 
  ggplot(mapping = aes(x = PC1, y = PC2)) +
  geom_point(size = 2, color = "dodgerblue3")
# Drop target column and normalize data
seeds_features<- recipe(~ ., data = seeds_select) %>% 
  step_rm(species) %>% 
  step_normalize(all_predictors()) %>% 
  prep() %>% 
  bake(new_data = NULL)

# Print out data
seeds_features %>% 
  slice_head(n = 5)

set.seed(2056)
# Create 10 models with 1 to 10 clusters
kclusts <- tibble(k = 1:10) %>% 
  mutate(
    model = map(k, ~ kmeans(x = seeds_features, centers = .x,
                            nstart = 20)),
    glanced = map(model, glance)) %>% 
  unnest(cols = c(glanced))



# Plot Total within-cluster sum of squares (tot.withinss)
kclusts %>% 
  ggplot(mapping = aes(x = k, y = tot.withinss)) +
  geom_line(size = 1.2, alpha = 0.5, color = "dodgerblue3") +
  geom_point(size = 2, color = "dodgerblue3")

             