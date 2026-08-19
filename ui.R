dateRangeInput2 <- function(inputId, label, minview = "days", maxview = "decades", ...) {
        d <- shiny::dateRangeInput(inputId, label, ...)
        d$children[[2L]]$children[[1]]$attribs[["data-date-min-view-mode"]] <- minview
        d$children[[2L]]$children[[3]]$attribs[["data-date-min-view-mode"]] <- minview
        d$children[[2L]]$children[[1]]$attribs[["data-date-max-view-mode"]] <- maxview
        d$children[[2L]]$children[[3]]$attribs[["data-date-max-view-mode"]] <- maxview
        d
}

        dashboardPage(skin = "black",
                dashboardHeader(title = "Historical FIFA Ranking", titleWidth = 250), #disable = T),
                dashboardSidebar(width = 250,
                        checkboxInput('wc2026_only',
                                      'Show only WC 2026 participants',
                                      value = TRUE),
                        dateRangeInput2('year',
                                       label = 'Date range:',
                                       start = "2014-01-01", end = max(data$date),
                                       min = min(data$date), max = max(data$date),
                                       separator = " - ", format = "mm/yyyy",
                                       startview = 'year', language = 'en-GB',
                                       minview = "months", maxview = "years"
                        ),
                        selectInput('x', 'Team 1 (red)', teams, selected = "Netherlands"),
                        div(style = "margin-top:-18px"),
                        selectInput('y', 'Team 2 (blue)', c("None", teams), selected = "Japan"),
                        div(style = "margin-top:-18px"),
                        shinyjs::disabled(selectInput('z', 'Team 3 (green)', c("None", teams), selected = "Sweden")),
                        div(style = "margin-top:-18px"),
                        shinyjs::disabled(selectInput('a', 'Team 4 (purple)', c("None", teams), selected = "Tunisia")),
                        div(style = "margin-top: 36px"),
                        tags$style(type="text/css", "#down {color: black; margin-left: 60px}"),
                        downloadButton('down', 'Download image', class="butt1"),
                        tags$div(
                                style = "margin-top: 32px; padding: 0 20px; font-size: 11px; color: #b8c7ce; line-height: 1.6;",
                                HTML(paste0(
                                        'Fork by <strong>Piet Stam</strong> &mdash; ',
                                        '<a href="https://github.com/pjastam/fifa-ranking/tree/master" target="_blank" style="color:#b8c7ce; text-decoration:underline;">GitHub</a><br/>',
                                        'Original by <strong>Ismael Gómez Schmidt</strong> &mdash; ',
                                        '<a href="https://github.com/Dato-Futbol/fifa-ranking" target="_blank" style="color:#b8c7ce; text-decoration:underline;">Dato-Futbol</a>'
                                ))
                        )
                ),
        
                dashboardBody(
                        shinyjs::useShinyjs(),
                        fluidRow(
                                column(12, align="center", box(plotlyOutput('plot', height = "550px", width = "98%"), 
                                                               width = 16, height = "580px", background = "black"))
                        )
                )
        )
