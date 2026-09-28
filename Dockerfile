# Based on the mondial-dashboard Dockerfile, trimmed to this app's packages
FROM rocker/shiny:latest

RUN R -e "install.packages(c('shiny','bslib','shinyWidgets','dplyr','tidyr','readxl','writexl','DT','htmltools','digest','jsonlite'))"

WORKDIR /home/shiny-app
COPY . /home/shiny-app/
RUN chown -R shiny:shiny /home/shiny-app
USER shiny

EXPOSE 3838
CMD ["R", "-e", "shiny::runApp('/home/shiny-app', host='0.0.0.0', port=3838)"]
