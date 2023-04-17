setwd("~/Documents/Master Thesis Interviews/getIETFinfo")
library(ggplot2)
library(dplyr)
library(maps)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(showtext)
library(lubridate)

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

# read CSV file with country and attendance data
locations <- read.csv("data/location_detailed.csv", stringsAsFactors = FALSE)

# use the table() function to count occurrences of each country
country_counts <- table(locations$Country)

# create a new dataframe with the counts
location_counts <- data.frame(
  Country = names(country_counts),
  Count = as.numeric(country_counts),
  EU_as_country = locations$EU.as.country[match(names(country_counts), locations$Country)]
)

# read in world shapefile
world <- ne_countries(scale = "medium", returnclass = "sf")

# join data file with world object
world <- world %>%
  left_join(location_counts, by = c("adm0_a3" = "Country"))

# unique(world$Count)
colnames(world)

# define colors for the gradient

mycolorsEU <- c("#6DBAFA", "#57ACF2", "#2A92E7", "#2F7BBA", "#255BA1", "#1F4A81")
mycolorsRest <- c("#BDAB8E", "#91836D")

# define Robinson projection
#proj_robinson <- "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs +lat_ts=0"

# transform world object to Robinson projection
#world_robinson <- st_transform(world, crs = proj_robinson)

#EPSG:3857

# create map
#ggplot(data = world_robinson) +
  #geom_sf(aes(fill = Count), color = NA) +
  #coord_sf(crs = proj_robinson,xlim = c(-100e5, 130e5), ylim = c(-5e6, 1e7)) +
  #scale_fill_gradientn(colors = mycolors, na.value = "#CCAACC") +
  ## geom_sf_label(aes(label = Count), color = "black", fontface = "bold", size = 3, fill = "white") +
  #ggtitle("IETF meetings per Country Robinson") +
  #theme(plot.title = element_text(hjust = 0.5, size = 20),
        #legend.position = "bottom",
        #legend.key.size = unit(0.8, "cm"),
        #legend.title = element_blank(),
        #legend.text = element_text(size = 10),
        #axis.line = element_blank(),
        #axis.text.y = element_blank(),
        #axis.ticks = element_blank())


#mercator
# create map
ggplot(data = world) +
  geom_sf(aes(fill = Count), color = '#C4C4C4', size = 0.2) +
  coord_sf(crs = "+proj=merc" ,xlim = c(-125e5, 180e5), ylim = c(-5e6, 1e7)) +
  scale_fill_gradientn(colors = mycolorsEU, na.value = "#F5F5F5", limits = c(min(world$Count), 6)) +
  geom_sf_label(
    aes(label = Count),
    color = "black",  # Set label color to white
    size = 2,  # Set label font size
    fill = NA,  # Remove label background
    family = "IBM Plex Sans Light",  # Set label font family to IBM Plex Sans Light
    label.padding = unit(0.15, "lines"),  # Set padding around the label
    label.r = unit(0.15, "lines"),  # Set the corner radius of the label box
    label.size = 0,  # Remove the border around the label
    na.rm = TRUE  # Remove labels with missing values
  ) +
  ggtitle("IETF meetings per Country EU colors") +
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        legend.position = "none",
        legend.text = element_text(size = 10),
        axis.line = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        panel.background = element_blank()
  )

ggsave(
  paste('graphs/location_map_EU', Sys.time(), '.svg'),
  plot = last_plot(),
  device = 'svg',
  scale = 1,
  width = 5,
  height = 5,
  limitsize = TRUE,
)

ggplot(data = world) +
  geom_sf(aes(fill = Count), color = '#C4C4C4', size = 0.2) +
  coord_sf(crs = "+proj=merc" ,xlim = c(-125e5, 180e5), ylim = c(-5e6, 1e7)) +
  scale_fill_gradientn(colors = mycolorsRest,
                       na.value = "#F5F5F5",
                       limits = c(min(world$Count), 4)
                       ) +
  geom_sf_label(
    aes(label = Count),
    color = "black",  # Set label color to white
    size = 2,  # Set label font size
    fill = NA,  # Remove label background
    family = "IBM Plex Sans Light",  # Set label font family to IBM Plex Sans Light
    label.padding = unit(0.15, "lines"),  # Set padding around the label
    label.r = unit(0.15, "lines"),  # Set the corner radius of the label box
    label.size = 0,  # Remove the border around the label
    na.rm = TRUE  # Remove labels with missing values
  ) +
  ggtitle("IETF meetings per Country rest colors") +
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        legend.position = "none",
        legend.text = element_text(size = 10),
        axis.line = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        panel.background = element_blank()
  )

ggsave(
  paste('graphs/location_map_rest', Sys.time(), '.svg'),
  plot = last_plot(),
  device = 'svg',
  scale = 1,
  width = 5,
  height = 5,
  limitsize = TRUE,
)

# ----------------- HISTOGRAM ------------
# sum up events by country
events_by_country <- locations %>% 
  group_by(EU.as.country) %>% 
  summarise(num_events = n())

# create histogram using ggplot
ggplot(events_by_country, aes(x = EU.as.country, y = num_events)) +
  geom_bar(stat = "identity", fill = "blue") +
  xlab("Country") +
  ylab("Number of Events") +
  ggtitle("Events by Country")


locations <- read.csv("data/location_detailed.csv", stringsAsFactors = FALSE)
# convert the date column to a POSIXct format
locations$Date <- dmy(locations$Date) %>% as.POSIXct()

# group events by year, EU.as.country, date, and meeting
events_by_year_country <- locations %>%
  group_by(year = year(Date), EU.as.country, Date, Meeting) %>%
  summarise(num_events = n()) %>%
  group_by(EU.as.country) %>%
  mutate(cumulative_count = cumsum(num_events))

                    
# create line chart using ggplot with log scale and points
ggplot(events_by_year_country, aes(x = as.Date(Date), y = cumulative_count, color = EU.as.country)) +
  geom_line() +
  geom_point(aes(x = as.Date(Date), y = cumulative_count), size = 2, shape = 22, fill = "white") +
  xlab("Meeting") +
  ylab("Cumulative Number of Events (log scale)") +
  ggtitle("Events by Year and EU.as.Country") +
  scale_y_log10() +
  theme(axis.text.x = element_text(size = 10, angle = 90, vjust = 0.5, hjust = 1),
        axis.text.y = element_text(size = 10),
        axis.ticks = element_blank(),
        axis.title.y = element_text(size = 13, margin = margin(r = 10)))
# create new variable for x-axis labels
meetings <- seq_len(nrow(locations))

# create a wrapper function that defines the labels function and the lookup table
get_custom_labels <- function(data) {
  lookup_table <- data %>%
    select(Meeting, Date) %>%
    distinct() %>%
    mutate(Date = as.Date(Date, "%d.%m.%Y"))
  
  label_fun <- function(x) {
    return(paste(format(x, "%y")))
  }
  
  return(label_fun)
}


# create line chart using ggplot with log scale and points
ggplot(events_by_year_country, aes(x = as.Date(Date), y = cumulative_count, color = EU.as.country)) +
  geom_line() +
  geom_point(aes(x = as.Date(Date), y = cumulative_count), size = 2, shape = 20, fill = "white") +
  xlab("Year") +
  ylab("Cumulative Number of Meetings") +
  ggtitle("Meetings by Year ") +
  # scale_y_log10() +
  scale_x_date(date_breaks = "1 year", labels = get_custom_labels(locations)) +
  theme(axis.text.x = element_text(size = 10, angle = 90, vjust = 0.5, hjust = 1),
        axis.text.y = element_text(size = 10),
        axis.ticks = element_blank(),
        axis.title.y = element_text(size = 13, margin = margin(r = 10)),
        panel.grid.major.x = element_line(color = "#EBEBEB", size = 0.1)
        )

ggsave(
  paste('graphs/location_over_time', Sys.time(), '.svg'),
  plot = last_plot(),
  device = 'svg',
  scale = 1,
  width = 6,
  height = 5,
  limitsize = TRUE,
)
