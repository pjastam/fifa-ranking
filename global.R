library(readr)
library(shiny)
library(ggplot2)
library(plotly)
library(lubridate)
library(zoo)
library(dplyr)
library(shinydashboard)
library(shinyjs)

options(shiny.usecairo = TRUE)

data_path = "./ranking_fifa_historical.csv"

data = read_csv(data_path, show_col_types = FALSE) %>%
       filter(!is.na(total_points)) %>%
       mutate(team = ifelse(team == "Curaçao", "Curacao", team),
              team = ifelse(team == "Hong Kong, China", "Hong Kong", team),
              team = ifelse(team == "Czech Republic", "Czechia", team),
              team = ifelse(team == "Turkey", "Türkiye", team)) %>%
       group_by(date) %>%
       mutate(rank = rank(-total_points)) %>%
       rename("points" = "total_points")

teams <- data %>% arrange(team) %>% pull("team") %>% unique()

wc2026_teams <- c(
        "Canada", "Curacao", "Haiti", "Mexico", "Panama", "USA",
        "Argentina", "Brazil", "Colombia", "Ecuador", "Paraguay", "Uruguay",
        "Austria", "Belgium", "Bosnia and Herzegovina", "Croatia", "Czechia",
        "England", "France", "Germany", "Netherlands", "Norway", "Portugal",
        "Scotland", "Spain", "Sweden", "Switzerland", "Türkiye",
        "Australia", "IR Iran", "Iraq", "Japan", "Jordan", "Qatar",
        "Saudi Arabia", "Korea Republic", "Uzbekistan",
        "Algeria", "Cabo Verde", "Congo DR", "Côte d'Ivoire", "Egypt",
        "Ghana", "Morocco", "Senegal", "South Africa", "Tunisia",
        "New Zealand"
)
