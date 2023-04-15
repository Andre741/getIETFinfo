setwd("~/Documents/Master Thesis Interviews/getIETFinfo")
library(tidyverse)
library(dplyr)
library(ggstream)

options(pillar.print_max = 50)

#design

font_add_google("IBM Plex Sans", "IBM Plex Sans")

theme_set(theme_minimal(base_family = "IBM Plex Sans"))
theme_update(
  plot.background = element_rect(fill = "#fafaf5", color = "#fafaf5"),
  panel.background = element_rect(fill = NA, color = NA),
  panel.border = element_rect(fill = NA, color = NA),
  panel.grid.major.x = element_blank(),
  panel.grid.minor = element_blank(),
  axis.text.x = element_blank(),
  axis.text.y = element_text(size = 10),
  axis.ticks = element_blank(),
  axis.title.y = element_text(size = 13, margin = margin(r = 10)),
  legend.title = element_text(size = 9),
  plot.caption = element_text(
    family = "IBM Plex Sans",
    size = 10,
    color = "grey70",
    face = "bold",
    hjust = .5,
    margin = margin(5, 0, 20, 0)
  ),
  plot.margin = margin(10, 25, 10, 25)
)
showtext_auto()


# helpers

#convert X year to year
remove_X_toNumeric <- function(sParam) {
  sParam <- substr(sParam, 2, 5)
  sParam_num <- as.numeric(sParam)
  return(sParam_num)
}

countries_of_interest <- c("Asia", "EU", "US", "CN")
# process data
getwd()
IETF <- read.csv(file = 'output/output2.csv', header = TRUE)
IETF_agg <- IETF %>%
  group_by(Year, Country) %>%
  summarise(Count = sum(Count, na.rm = TRUE))

Selection <- IETF_agg[IETF_agg$Country %in% countries_of_interest, ]

# Calculate the total count for each year using dplyr
totals <- IETF_agg %>%
  group_by(Year) %>%
  summarize(TotalCount = sum(Count))

total_counts <- data.frame(Year = totals$Year, Count = totals$TotalCount, Country = "Total") # Create a new data frame with the total counts

# Combine the data frames
IETF_totals <- rbind(IETF_agg, total_counts)
Selection_total <- IETF_totals[IETF_totals$Country %in% c("Total", countries_of_interest), ]

# Calculate the Other countries
other_countries <- IETF_agg %>%
  filter(!(Country %in% countries_of_interest)) %>%
  group_by(Year) %>%
  summarise(Count = sum(Count))
other_countries <- data.frame(Year = other_countries$Year, Count = other_countries$Count, Country = "Other")
IETF_rest <- rbind(IETF_agg, other_countries)
Selection_rest <- IETF_rest[IETF_rest$Country %in% c("Other", countries_of_interest), ]

# Filter the data frame to only include rows where Country is not one of the countries of interest
Selection_other <- subset(IETF_rest, !(Country %in% countries_of_interest))

# Show the unique values of the Country column in Selection_other
unique(Selection_other$Country)

# ––––––––––––––– line charts  ––––––––––––––– 
# simple line chart
ggplot(data = Selection, aes(x = Year, y = Count, color = Country)) +
  geom_line() +
  labs(title = "Line Chart for US and EU", x = "Year", y = "Count")

# Create the ggplot object with the line chart and total count line
ggplot(data = IETF_totals, aes(x = Year, y = Count, color = Country)) +
  geom_line() +
  labs(title = "Line Chart for all countries", x = "Year", y = "Count")

# -------------- Percentage Plot  ----------------
Selection_rest_total <- rbind(Selection_rest, total_counts)
# calculate the percentages
mydata_subset_percent <- Selection_rest_total %>% 
  group_by(Year) %>% 
  mutate(Percentage = Count / totals$TotalCount[totals$Year == Year]) %>% 
  select(Year, Percentage, Country) %>%
  filter(Country != "Total")

ggplot(data = mydata_subset_percent, aes(x = Year, y = Percentage, color = Country)) +
  geom_line() +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 10))

# reorder the levels of the Country factor variable
mydata_subset_percent$Country <- factor(mydata_subset_percent$Country,
                                        levels = c("CN", "Asia", "Other",  "EU", "US"))

ggplot(data = mydata_subset_percent, aes(x = Year, y = Percentage, fill = Country)) +
  geom_bar(stat = "identity") +
  geom_smooth(aes(group = Country), method = "lm", se = FALSE, color = "black") +
  labs(x = "Meeting", y = "", fill = "Country") +
  scale_x_continuous(breaks = c(47,84, 94, 104, 114), limits = c(47, 115)) +
  theme(axis.text.x = element_text(size = 5, color = "black"),
        axis.ticks.x = element_line(size = 0.5))
  
# define the fill colors for the bars
fill_colors <- c("#BB2080", "#E07373", "#C8C8C8", "#2C84CC", "#B5A488")

# create the bar graph with trend lines
ggplot(data = mydata_subset_percent, aes(x = Year, y = Percentage, fill = Country)) +
  geom_bar(stat = "identity", position = position_stack()) +
  scale_fill_manual(values = fill_colors) +
  geom_smooth(aes(group = Country, color = Country), method = "lm", se = FALSE) +
  # move them manually
  scale_color_manual(values = fill_colors) +
  labs(x = "Meeting", y = "Percentage", fill = "Country") +
  scale_x_continuous(breaks = c(48:114), limits = c(47, 115)) +
  theme(axis.ticks.x = element_line(size = 0.2), axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1) )

ggsave(
  paste('bar graph with trendlines', Sys.time(), '.svg'),
  plot = last_plot(),
  device = 'svg',
  scale = 1,
  width = 9,
  height = 5,
  limitsize = TRUE,
)

# get the R-squared value for each country's trend line
# group the data by country and fit a linear regression model for each country
rsquared_df <- mydata_subset_percent %>%
  group_by(Country) %>%
  do(rsq = summary(lm(Percentage ~ Year, data = .))$r.squared)

# view the R-squared values for each country
rsquared_df

# --------- stream chart ------
# define the order of the countries
country_order <- c("Other", "Asia", "CN", "EU", "US")

# aggregate the data by year and country
mydata_agg <- mydata_subset_percent %>%
  group_by(Year, Country) %>%
  summarize(Count = sum(Percentage)) %>%
  mutate(Country = factor(Country, levels = country_order))

# create the streamgraph
ggplot(mydata_agg, aes(x = Year, y = Count, fill = Country)) +
  geom_stream(offset = "wiggle") +
  scale_x_continuous(breaks = unique(mydata_agg$Year)) +
  labs(x = "Year", y = "Count", fill = "Country")



# -------------- INTERPRETATION -------------- 
# calculate the mean percentage for each year and country
mydata_summary <- mydata_subset_percent %>%
  group_by(Year, Country) %>%
  summarize(mean_percentage = mean(Percentage))

# calculate the difference between mean percentage values for each year
mydata_diff <- mydata_summary %>%
  group_by(Country) %>%
  mutate(diff_percentage = mean_percentage - lag(mean_percentage, default = first(mean_percentage)))

# view the difference values
mydata_diff

# -------------- Reshape the data ----------------
reshaped_data <- mydata_subset_percent %>%
  spread(key = Country, value = Percentage)

write.csv(reshaped_data, "reshaped_data_percent.csv", row.names = FALSE)

#normalised line chart

# Calculate the percentage of total count for each group
data_totals <- IETF %>% group_by(Year, Country) %>% summarize(TotalCount = sum(Count))
year_totals <- data_totals %>% group_by(Year) %>% summarize(TotalYearCount = sum(TotalCount))
data_pct <- data_totals %>% left_join(year_totals, by = "Year") %>% mutate(PctOfTotal = TotalCount / TotalYearCount * 100)

plot <- data_pct %>% 
  ggplot(aes(x = Year, y = PctOfTotal, color = Country)) + 
  geom_smooth(method = "scam", 
              # b-spline monotonic deceasing
              # see ?shape.constrained.smooth.terms
              formula = y ~ s(x, k = 5, bs = "mpd"), 
              se = FALSE)
guides(color = FALSE) +
  scale_color_identity() +
  ggtitle("IETF")
labs(title = "Percentage of Total Count over Time by Country", x = "Year", y = "% of Total Count")

plot

ggsave(
  paste('complete overview graph', Sys.time(), '.svg'),
  plot = last_plot(),
  device = 'svg',
  scale = 1,
  width = 5,
  height = 5,
  limitsize = TRUE,
)


