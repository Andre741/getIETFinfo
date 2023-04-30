setwd("~/Documents/Master Thesis Interviews/getIETFinfo")
library(tidyverse)
library(dplyr)
library(showtext)
library(readxl)
library(ggplot2)
library(ggrepel)
library(scales)
library(stringr)

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

getwd()

grants <- read_excel("data/eu_grants.xlsx") # attention some floats are not exactly the same

# Rename columns in the "grants" data frame to more descriptive names
# Original names:                       New names:
# "Year"                                "year"
# "Reference (Budget)"                  "budget_reference"
# "Subject of grant or contract"        "subject"
# "Name of beneficiary"                 "beneficiary_name"
# "VAT number of beneficiary"           "beneficiary_VAT"
# "Beneficiary country"                 "beneficiary_country"
# "Beneficiary’s contracted amount (EUR)" "contracted_amount_EUR"
# "Commitment contracted amount (EUR)"  "committed_amount_EUR"
# "Programme name"                      "programme_name"
# "Responsible department"              "responsible_department"
# "Project start date"                  "start_date"
# "Project end date"                    "end_date"
# "group"                               "group"

new_names <- c("year", "budget_reference", "subject", "beneficiary_name",
               "beneficiary_VAT", "beneficiary_country", "contracted_amount_EUR",
               "committed_amount_EUR", "programme_name", "responsible_department",
               "start_date", "end_date", "group")

names(grants) <- new_names

grants <- grants %>% 
  mutate(Subgroup = case_when(
    grepl("\\bNGI\\b|NGI4ALL|825189|780643|780125|732569|825618", `subject`, ignore.case = TRUE) ~ "NGI",
    grepl("\\b(IOT|Internet of Things)\\b", `subject`, ignore.case = TRUE) ~ "IOT",
    grepl("\\b(5|6)G\\b", `subject`, ignore.case = TRUE) ~ "5G",
    grepl("Future Internet", `subject`, ignore.case = TRUE) ~ "Future Internet",
    TRUE ~ "Other"
  )) %>% 
  mutate(Group = case_when(
    Subgroup %in% c("NGI", "Future Internet", "5G", "IOT") ~ "Networking",
    TRUE ~ "Other"
  ))

unique_references_df <- as.data.frame(unique(grants$budget_reference))

# summarise grants by subject
grants_summed_by_subject <- grants %>% 
  group_by(subject, Subgroup, Group) %>% 
  summarize(total_contracted_amount = sum(contracted_amount_EUR, na.rm = TRUE))

## Savegrants_summed_by_subject as CSV file so as to mark it manually with 'x' for the subjects that should be in the 'Networking' group
#grants_summed_by_subject %>%
 # subset(select = 1:(ncol(.)-6)) %>%
  #mutate(ID = as.numeric(sub("^([0-9]+).*", "\\1", subject)))
# write.csv(marked_grants_summed_by_subject, "data/grants_summed_by_subject_marked.csv", row.names = FALSE)

# as the above was already done the data can be taken from the csv saved. NOTE that subjects where the name changed were manually changed to correspond to the original name
marked_grants_summed_by_subject <- read.csv("data/grants_summed_by_subject_marked.csv")

# subset the ID column of the data frame where the internet column equals "x"
ids_networking <- marked_grants_summed_by_subject$ID[marked_grants_summed_by_subject$internet == "x"]

# subset the subject column of the data frame where the internet column equals "x" and the ID column is empty
# note that we use the original data frame `marked_grants_summed_by_subject` instead of `ids_networking` to access the subject column
subjects_networking <- marked_grants_summed_by_subject$subject[marked_grants_summed_by_subject$internet == "x" & is.na(marked_grants_summed_by_subject$ID)]

# create a regular expression pattern from the 'subjects_networking', '\\b1148\\b', and '\\BCOS\\b' vectors, for some reason I had to add the two extra checks
pattern <- paste(subjects_networking, "\\b1148\\b", "\\BCOS\\b", collapse="|")
# create a regular expression pattern that matches the 'ids_networking' values at the beginning of the 'subject' column
patternIDs <- paste("^", paste(ids_networking, collapse="|^"), sep="")

# add the "Networking" group to the 'grants' data frame where the subject matches the specified pattern

grants <- grants %>%
  mutate(Group = case_when(
    grepl(pattern, subject) ~ "Networking",
    grepl(patternIDs, subject) ~ "Networking",
    TRUE ~ Group
  ))


# sanity check for having all marked correctly categorized
# summarise grants by subject, do this again as now we have updated the groups
grants_summed_by_subject <- grants %>% 
  group_by(subject, Subgroup, Group) %>% 
  summarize(total_contracted_amount = sum(contracted_amount_EUR, na.rm = TRUE)) # %>% 
  #mutate(total_contracted_amount_in_millions = total_contracted_amount / 1000000)

# Get all subjects which are marked with an "x" in `marked_grants_summed_by_subject`
marked_x_subjects <- marked_grants_summed_by_subject$subject[marked_grants_summed_by_subject$internet == "x"]

#get all which are not in the networking group
not_networking_subjects <- grants_summed_by_subject$subject[grants_summed_by_subject$Group != "Networking"]

# Check if none of the subjects in marked_x_subjects are in not_networking_subjects
if(all(!marked_x_subjects %in% not_networking_subjects)) {
  # Perform some action if the condition is true
  # For example:
  print("None of the subjects marked with x are in not_networking_subjects.")
} else {
  # Perform some other action if the condition is false
  # For example:
  print("At least one subject marked with x is in not_networking_subjects.")
}

num_marked_x <- sum(marked_grants_summed_by_subject$internet == "x")
num_networking <- sum(grants$Group == "Networking")

if (num_marked_x > num_networking) {
  message("There are more subjects marked with an 'x' than subjects in the 'Networking' group")
} else {
  # message("There are less or equal subjects marked with an 'x' than subjects in the 'Networking' group, this is fine")
}

# _________________________________________________________________
#                 GROUP NETWORKING GRANTS
# _________________________________________________________________

# Define the desired order of the groups
group_order <- c("Other", "Networking", "Future Internet", "Internet", "NGI")

# Create a new factor variable with the desired order of the groups
grants$Group <- factor(grants$Group, levels = group_order)

# Sum up the contracted amount by year and group
grants_summed <- grants %>% 
  group_by(year, Group) %>% 
  summarize(total_contracted_amount = sum(contracted_amount_EUR, na.rm = TRUE))


# define the fill colors for the bars
fill_colors <- c("#BB2080", "#E07373", "#C8C8C8", "#2C84CC", "#B5A488")


# Create the stacked bar graph with ordered fill colors and millions of euros on the y-axis
p <- ggplot(grants_summed, aes(x = year, y = total_contracted_amount/1000000, fill = Group)) + 
  geom_bar(stat = "identity") + 
  labs(x = "Year", y = "Total Contracted Amount (Millions of Euros)", fill = "Group") + 
  scale_fill_manual(values = c("#999999", "#56B4E9", "#009E73","#ff0073", "#E69F00"), 
                    breaks = group_order) + 
   theme(axis.text.x = element_text(size = 5, color = "black"),
        axis.ticks.x = element_line(size = 0.2))

# Add totals for each year at the top of the stacked bar graph
p + geom_text(aes(label = paste0(round(total_contracted_amount/1000000, 1), " M")), 
              position = position_stack(vjust = 1.2), size = 4)

ggsave(
  paste('graphs/barGraphInvestment', Sys.time(), '.svg'),
  plot = last_plot(),
  device = 'svg',
  scale = 1,
  width = 9,
  height = 5,
  limitsize = TRUE,
)

# _________________________________________________________________
#                NOW THE SUBGROUPS
# _________________________________________________________________


# Define the desired order of the groups
subgroup_order <- c("Other", "5G", "IOT", "NGI", "Future Internet")

# Create a new factor variable with the desired order of the groups
grants$Subgroup <- factor(grants$Subgroup, levels = subgroup_order)

# Sum up the contracted amount by year and subgroup only for the networking group
grants_summed_neworking <- grants %>% 
  filter(Group == "Networking"& year != 2021) %>% 
  group_by(year, Subgroup) %>% 
  summarize(total_contracted_amount = sum(contracted_amount_EUR, na.rm = TRUE))


# Add a show_label column to grants_summed_neworking using case_when
grants_summed_neworking$show_label <- case_when(
  grants_summed_neworking$total_contracted_amount/1000000 < 3 ~ FALSE, # Never 
  grants_summed_neworking$Subgroup == "NGI" ~ TRUE, # Mark those in the "NGI" subgroup
  grants_summed_neworking$Subgroup == "Future Internet" ~ TRUE, # Mark those in the "Future Internet" subgroup
  grants_summed_neworking$total_contracted_amount/1000000 > 25 ~ TRUE, # Show labels for amounts > 25 million
  TRUE ~ FALSE # Otherwise, don't show the label
)

# Save the plot in an object
network_plot <- ggplot(grants_summed_neworking, aes(x = year, y = total_contracted_amount/1000000, fill = Subgroup)) + 
  geom_bar(stat = "identity") + 
  geom_text(aes(label = ifelse(show_label, round(total_contracted_amount/1000000, 2), "")),
            position = position_stack(vjust = 0.5), # adjust the vertical position of the label
            size = 3) + # adjust the size of the label text
  labs(x = "", y = "Total Contracted Amount (Millions of Euros)", fill = "Subgroup") + 
  scale_fill_manual(values = c("#999999", "#56B4E9", "#009E73","#ff0073", "#E69F00"), 
                    breaks = subgroup_order) + 
  scale_x_continuous(breaks = unique(grants_summed_neworking$year), expand = c(0, 0)) +
  theme(axis.text.x = element_text(size = 10),
        axis.ticks.x = element_line(size = 0.2))

network_plot

# Add the total label to the plot
# Sum up the total contracted amount by year for all groups
total_grants_summed <- grants_summed %>%
  filter(year != 2021) %>% 
  group_by(year) %>%
  summarize(total_contracted_amount = sum(total_contracted_amount))

calculateAmount <- function(amount) {
  finalAmount <- amount / 1000000 # convert to millions
  finalAmount <- finalAmount ^ 2 # square the value to increase the difference
  finalAmount <- finalAmount / 15000
  finalAmount <- finalAmount + 96 # add 90 to shift the starting point
  
  if (finalAmount > 400) {
    finalAmount <- 250
  } else if (finalAmount > 226) {
    print(amount)
    print(finalAmount)
    print('####')
    finalAmount <- 240
  }
  
  return(finalAmount)
}

network_plot <- network_plot +
  annotate("text", x = total_grants_summed$year, y = sapply(total_grants_summed$total_contracted_amount, calculateAmount), 
           label = round(total_grants_summed$total_contracted_amount/1000000, 0), 
           vjust = -0.5, size = 4) + # adjust the vjust parameter to move the total label right above the bar
  expand_limits(y = c(0, 250)) # set the upper limit of the y-axis to 300 million

ggsave(
  paste('graphs/barGraphInvestmentWithTotal', Sys.time(), '.svg'),
  plot = network_plot,
  device = 'svg',
  scale = 1,
  width = 9,
  height = 5,
  limitsize = TRUE,
)

# _________________________________________________________________
#                OTHER NUMBERS
# _________________________________________________________________



median_networking <- median(grants_summed$total_contracted_amount[grants_summed$Group == "Networking"]) / 1000000
median_other <- median(grants_summed$total_contracted_amount[grants_summed$Group == "Other"]) / 1000000
percentage_networking <- median_networking / (median_networking + median_other) * 100

# Sum up the contracted amount by year and group
grants_highPerformance <- grants %>% 
  filter(grepl("HIGH PERFORMANCE COMPUTING JOINT", subject)) %>% 
  group_by(year) %>% 
  summarize(total_contracted_amount = sum(contracted_amount_EUR, na.rm = TRUE)) %>% 
  mutate(total_contracted_amount_in_millions = total_contracted_amount / 1000000)




# Filter for rows with "NGI" group
ngi_grants <- grants %>% 
  filter(Group == "NGI")

ngi_grants_grouped <- ngi_grants %>% 
  group_by(year, subject) %>% 
  summarise(total_contracted_amount = sum(contracted_amount_EUR))
