planetary_hours <- function(day, time){
  
  chaldean_cycle <- c("Saturn","Jupiter","Mars","Sun","Venus","Mercury","Moon")
  
  day_ruler <- list(
    Sunday    = "Sun",
    Monday    = "Moon",
    Tuesday   = "Mars",
    Wednesday = "Mercury",
    Thursday  = "Jupiter",
    Friday    = "Venus",
    Saturday  = "Saturn"
  )
  
  hour_ruler <- function(day){
    start <- day_ruler[[day]]
    i <- match(start, chaldean_cycle)
    chaldean_cycle[((i - 1 + 0:23) %% 7) + 1]
  }
  
  planetary_table <- lapply(names(day_ruler), hour_ruler)
  names(planetary_table) <- names(day_ruler)
  
  hhmm_to_min <- function(x) (x %/% 100) * 60 + (x %% 100)
  
  user_min  <- hhmm_to_min(time)
  
  # Based upon EST
  sunrise_min <- hhmm_to_min(600) 
  ph_len <- 60              

  pass <- user_min - sunrise_min
  hour_index <- floor(pass / ph_len) + 1
  hour_index <- ((hour_index - 1) %% 24) + 1
  
  ruler_of_hour <- planetary_table[[day]][hour_index]
  ruler_of_day  <- day_ruler[[day]]
  
  paste0("Planetary Ruler: ",ruler_of_day,", Planetary Hour: ", ruler_of_hour)
}


# Example use: planetary_hours("Wednesday", 2208)

