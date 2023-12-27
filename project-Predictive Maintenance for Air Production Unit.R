# Project: Predictive Maintenance for Air Production Unit


# Setting working directory
setwd('C:\\Users\\User\\Documents\\DERSLER\\3360-001 Fundamentals of Data Analytics\\PROJECT\\p2_fikret_durmaz')

library(readr)
library(dplyr)
library(caret)

# a. Data exploration

# Loading dataset
data <- read.csv("data/MetroPT3(AirCompressor).csv")

# Sampling a fraction of the data
set.seed(42) # Set the random seed for reproducibility
data_sampled <- data %>%
  sample_frac(0.001, replace = FALSE)

# Drop the 'timestamp' column
data_sampled <- data_sampled %>%
  select(-timestamp)


# Descriptive statistics for the numerical features
summary(data_sampled)


# b. Data pre-process

# Identifying columns with missing values 
# Creating a function which calculates number of missing values in columns
sum_of_na_values = function(dataset) {
  sapply(
    data_sampled,
    FUN = function(col)
      sum(is.na(col))
  )
}

# Calling the function to see number of missing values
na_counts <- sum_of_na_values(data_sampled)
hasNA = which(na_counts > 0)
na_counts[hasNA]

# CORRELATION HEATMAP
# Load necessary libraries
library(ggplot2)
library(reshape2)
library(corrplot)

# Compute the correlation matrix
cor_matrix <- cor(data[, sapply(data, is.numeric)], use="complete.obs")

# Use corrplot to create a correlation heatmap
corrplot(cor_matrix, method="color", type="upper", order="hclust", 
         tl.col="black", tl.srt=45)


# Load necessary library
library(rpart)

# Load necessary library
library(e1071)

# Load necessary library
library(randomForest)

# Load necessary libraries
library(caret)

# Target variable is "LPS"
target_column <- "LPS"

# Converting the target variable to a factor with two levels (binary classification)
data_sampled[[target_column]] <- factor(data_sampled[[target_column]], levels = c(0, 1))

# Splitting data into features (X) and target (y)
X <- data_sampled[, !colnames(data_sampled) %in% target_column]
y <- data_sampled[[target_column]]

# Set up the k-fold cross-validation
num_folds <- 5

# Defining the models to evaluate
models <- list(
  "Decision Tree" = "rpart",
  "SVM" = "svmRadial",
  "Random Forest" = "rf"
)

# Function to perform k-fold cross-validation and get accuracy metrics
evaluate_model <- function(model_name, method) {
  model <- train(y = y, x = X, method = method, trControl = trainControl(method = "cv", number = num_folds))
  return(data.frame(Method = model_name, Accuracy = model$results$Accuracy))
}

# Evaluating models and combine the results into a data frame
results <- lapply(names(models), function(model_name) {
  evaluate_model(model_name, models[[model_name]])
}) %>%
  bind_rows()

# Calculating the mean accuracy and standard deviation for each model
summary_results <- results %>%
  group_by(Method) %>%
  summarise(Avg_Accuracy = mean(Accuracy), Std_Dev_Accuracy = sd(Accuracy))

# Printing the summary table of performance
print(summary_results)

# Finding the best method and its accuracy
best_accuracy <- max(summary_results$Avg_Accuracy)
best_method <- summary_results$Method[which.max(summary_results$Avg_Accuracy)]

# Printing the best method and accuracy
cat("Best method:", best_method, "\n")
cat("Best accuracy:", round(best_accuracy, 4), "\n")

library(dplyr)
library(ggplot2)

# Function to identify numerical columns in a dataframe
get_numerical_columns <- function(data) {
  numerical_cols <- sapply(data, is.numeric)
  return(names(data)[numerical_cols])
}

# Using the function to get numerical features for clustering
numerical_features <- get_numerical_columns(data_sampled)


# Subsetting the data to include only numerical features
data_numerical <- data_sampled[, numerical_features]

# Functioning to calculate within-cluster sum of squares (WCSS)
calculate_wcss <- function(data, k) {
  kmeans_model <- kmeans(data, centers = k, nstart = 25)
  return(sum(kmeans_model$withinss))
}

# Applying Elbow Method to determine the optimal number of clusters 'k'
elbow_df <- tibble(K = integer(), WCSS = double())

for (k in 1:10) {
  wcss_value <- calculate_wcss(data_numerical, k)
  elbow_df <- elbow_df %>% add_row(K = k, WCSS = wcss_value)
}

# Plotting the Elbow Method
ggplot(elbow_df, aes(x = K, y = WCSS)) +
  geom_line() +
  geom_point() +
  labs(x = "Number of Clusters (k)", y = "Within-Cluster Sum of Squares (WCSS)") +
  ggtitle("Elbow Method for Optimal 'k'")


library(viridis)
library(ggplot2)

# Applying KMeans clustering with the optimal number of clusters
optimal_k <- 3
kmeans_model <- kmeans(data_numerical, centers = optimal_k, nstart = 25)

# Scaling the data before PCA
scaled_data <- scale(data_numerical)

# Applying PCA for visualization
pca_result <- prcomp(scaled_data, center = FALSE, scale. = FALSE, retx = TRUE)
principal_components <- data.frame(PC1 = pca_result$x[, 1], PC2 = pca_result$x[, 2])

# Creating a new dataframe with the two principal components and cluster labels
pc_df <- cbind(principal_components, Cluster = as.factor(kmeans_model$cluster))

# Creating a scatter plot with a legend using ggplot2
ggplot(pc_df, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point() +
  labs(x = 'First Principal Component', y = 'Second Principal Component', title = 'Cluster visualization') +
  scale_color_viridis_d(name = 'Clusters') +
  theme_minimal()




















