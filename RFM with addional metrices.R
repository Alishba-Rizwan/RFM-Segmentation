# Load required libraries
library(tidyverse)
library(lubridate)
library(janitor)

# Load the dataset
df_salesData <- read.csv("E:/Data Analytics/df_sales_data.csv")

# Clean column names
df_salesData <- clean_names(df_salesData)

# Convert 'invoice_date' to a Date object
df_salesData$invoice_date <- as.Date(df_salesData$invoice_date, format = "%m/%d/%Y")

# Print the first few rows to check the data
print(head(df_salesData))

# Find the latest date in the dataset
latest_date <- max(df_salesData$invoice_date, na.rm = TRUE)
print(latest_date)

# Calculate recency, frequency, monetary value, and additional metrics
rfm_data <- df_salesData %>%
  group_by(customer_id) %>%
  summarise(
    recency = as.numeric(difftime(latest_date, max(invoice_date), units = "days")),
    frequency = n_distinct(invoice_no),
    monetary = sum(quantity * unit_price),
    avg_order_value = mean(quantity * unit_price, na.rm = TRUE),
    total_items = sum(quantity, na.rm = TRUE),
    avg_days_between_purchases = ifelse(n_distinct(invoice_no) > 1,
     mean(difftime(sort(unique(invoice_date)), lag(sort(unique(invoice_date))), units = "days"), na.rm = TRUE),
    NA),
    clv = sum(quantity * unit_price, na.rm = TRUE) / n_distinct(invoice_no),
    first_purchase = min(invoice_date, na.rm = TRUE),
    customer_tenure = as.numeric(difftime(latest_date, min(invoice_date, na.rm = TRUE), units = "days")),
    avg_cart_size = mean(quantity, na.rm = TRUE),
    repeat_purchase_rate = ifelse(n_distinct(invoice_no) > 1, 1, 0)
  ) %>%
  ungroup()

# Print the first few rows to check the data
print(head(rfm_data))

# Create quartiles for each RFM metric
rfm_data <- rfm_data %>%
  mutate(
    recency_quartile = ntile(recency, 4),
    frequency_quartile = ntile(frequency, 4),
    monetary_quartile = ntile(monetary, 4),
    avg_order_value_quartile = ntile(avg_order_value, 4),
    total_items_quartile = ntile(total_items, 4),
    clv_quartile = ntile(clv, 4),
    customer_tenure_quartile = ntile(customer_tenure, 4)
  )

# Print the first few rows to check the data
print(head(rfm_data))

# Combine the quartiles to create an RFM segment
rfm_data <- rfm_data %>%
  mutate(
    RFM_Score = paste(recency_quartile, frequency_quartile, monetary_quartile, sep = ""),
    RFM_Segment = case_when(
      RFM_Score %in% c("444", "443", "434", "433", "344", "343", "334") ~ "Champions",
      RFM_Score %in% c("442", "441", "432", "431", "424", "423", "422", "414", "413", "412", "411") ~ "Loyal Customers",
      RFM_Score %in% c("324", "323", "322", "314", "313", "312", "311") ~ "Potential Loyalists",
      RFM_Score %in% c("441", "431", "421", "411") ~ "New Customers",
      RFM_Score %in% c("344", "343", "334", "324", "323", "322") ~ "Promising",
      RFM_Score %in% c("242", "241", "232", "231", "224", "223", "222", "214", "213", "212", "211") ~ "Need Attention",
      RFM_Score %in% c("432", "431", "422", "421", "412", "411") ~ "About to Sleep",
      RFM_Score %in% c("144", "143", "142", "141", "134", "133", "132", "131", "124", "123", "122", "121") ~ "Churn Risk",
      RFM_Score %in% c("244", "243", "242", "241", "234", "233", "232", "231") ~ "High Spending New Customers",
      RFM_Score %in% c("111") ~ "Lost Low-Value Customers",
      RFM_Score %in% c("211", "212", "213") ~ "One-Time High Spenders",
      TRUE ~ "Other"
    )
  )

# Print the first few rows to check the data
print(head(rfm_data))

# Visualize RFM segments using ggplot2
ggplot(rfm_data, aes(x = RFM_Segment)) +
  geom_bar() +
  xlab("RFM Segment") +
  ylab("Count") +
  ggtitle("RFM Segmentation") +
  theme(axis.text.x = element_text(angle = 45))
# Visualize the distribution of average order value
ggplot(rfm_data, aes(x = avg_order_value)) +
  geom_histogram(binwidth = 50, fill = "skyblue", color = "black") +
  xlab("Average Order Value") +
  ylab("Frequency") +
  ggtitle("Distribution of Average Order Value")

ggplot(rfm_data, aes(x = frequency)) +
  geom_histogram(binwidth = 1, fill = "skyblue", color = "black") +
  xlab("Frequency") +
  ylab("Count") +
  ggtitle("Distribution of Purchase Frequency")


ggplot(rfm_data, aes(x = monetary)) +
  geom_histogram(binwidth = 100, fill = "skyblue", color = "black") +
  xlab("Monetary Value") +
  ylab("Count") +
  ggtitle("Distribution of Monetary Value")

ggplot(rfm_data, aes(x = recency, y = frequency)) +
  geom_point(color = "skyblue") +
  xlab("Recency") +
  ylab("Frequency") +
  ggtitle("Recency vs Frequency")

ggplot(rfm_data, aes(x = recency, y = monetary)) +
  geom_point(color = "skyblue") +
  xlab("Recency") +
  ylab("Monetary Value") +
  ggtitle("Recency vs Monetary Value")

