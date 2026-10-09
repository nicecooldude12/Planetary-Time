day_rulers <- c("Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn")
chaldean_order <- c("Saturn", "Jupiter", "Mars", "Sun", "Venus", "Mercury", "Moon")

.check_location <- function(timezone, latitude, longitude) {
  if (!is.character(timezone) || length(timezone) != 1L ||
      is.na(timezone) || !timezone %in% OlsonNames()) {
    stop("Use a valid time zone, e.g. America/New_York or Africa/Nairobi.")
  }
  if (!is.numeric(latitude) || length(latitude) != 1L ||
      !is.finite(latitude) || abs(latitude) > 90) {
    stop("latitude must be one number between -90 and 90.")
  }
  if (!is.numeric(longitude) || length(longitude) != 1L ||
      !is.finite(longitude) || abs(longitude) > 180) {
    stop("longitude must be one number between -180 and 180.")
  }
  if (!requireNamespace("suncalc", quietly = TRUE)) {
    stop('Install suncalc first: install.packages("suncalc")')
  }
}

# Query neighboring dates, then select by LOCAL date. This matters near the
# international date line, where a sunrise's UTC date can differ from its local date.
.solar_events <- function(date, timezone, latitude, longitude) {
  candidates <- suncalc::getSunlightTimes(
    date = seq(date - 2, date + 2, by = "day"),
    lat = latitude, lon = longitude,
    keep = c("sunrise", "sunset"), tz = timezone
  )
  rise_dates <- as.Date(candidates$sunrise, tz = timezone)
  today <- which(!is.na(rise_dates) & rise_dates == date)
  tomorrow <- which(!is.na(rise_dates) & rise_dates == date + 1)
  if (length(today) != 1L || length(tomorrow) != 1L) {
    stop("Cannot calculate hours: sunrise is missing or not unique for ",
         date, " or the next local date. Check location and polar conditions.")
  }
  sunrise <- candidates$sunrise[today]
  next_sunrise <- candidates$sunrise[tomorrow]
  sets <- which(!is.na(candidates$sunset) &
                  candidates$sunset > sunrise & candidates$sunset < next_sunrise)
  if (length(sets) != 1L) {
    stop("Cannot calculate hours: no unique sunset between consecutive sunrises.")
  }
  list(sunrise = sunrise, sunset = candidates$sunset[sets],
       next_sunrise = next_sunrise)
}

# Internal calculator separated from astronomy so boundaries can be tested.
.make_schedule <- function(date, timezone, sunrise, sunset, next_sunrise) {
  points <- as.numeric(c(sunrise, sunset, next_sunrise))
  if (any(!is.finite(points)) || any(diff(points) <= 0)) {
    stop("Solar events must be finite and ordered: sunrise < sunset < next sunrise.")
  }
  # Twelve equal parts of daylight and twelve equal parts of darkness.
  bounds <- c(seq(points[1], points[2], length.out = 13),
              seq(points[2], points[3], length.out = 13)[-1])
  weekday <- as.POSIXlt(as.Date(date), tz = "UTC")$wday + 1L
  day_ruler <- day_rulers[weekday]
  first <- match(day_ruler, chaldean_order)
  rulers <- chaldean_order[((first - 1L + 0:23) %% 7L) + 1L]
  data.frame(
    planetary_date = rep(as.Date(date), 24),
    day_ruler = rep(day_ruler, 24),
    planetary_hour = 1:24,
    period = rep(c("Day", "Night"), each = 12),
    hour_ruler = rulers,
    hour_start = as.POSIXct(bounds[1:24], origin = "1970-01-01", tz = timezone),
    hour_end = as.POSIXct(bounds[2:25], origin = "1970-01-01", tz = timezone),
    duration_minutes = diff(bounds) / 60,
    stringsAsFactors = FALSE
  )
}

# Produce the complete 24-hour timetable for a local planetary date.
# The timetable starts at that date's sunrise and ends at next sunrise.
#' @export
planetary_schedule <- function(date, timezone, latitude, longitude) {
  .check_location(timezone, latitude, longitude)
  date <- as.Date(date)
  if (length(date) != 1L || is.na(date)) stop("Supply one valid date: YYYY-MM-DD.")
  solar <- .solar_events(date, timezone, latitude, longitude)
  .make_schedule(date, timezone, solar$sunrise, solar$sunset, solar$next_sunrise)
}

.parse_timestamp <- function(timestamp, source_timezone) {
  # POSIXct already describes an instant. Never reinterpret its clock reading.
  if (inherits(timestamp, "POSIXt")) return(as.POSIXct(timestamp))
  if (!is.character(timestamp)) stop("Use timestamp text or a POSIXct object.")
  if (is.na(timestamp)) return(as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC"))
  if (!requireNamespace("clock", quietly = TRUE)) {
    stop('Install clock first: install.packages("clock")')
  }
  timestamp <- trimws(timestamp)
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$", timestamp)) {
    timestamp <- paste0(timestamp, ":00")
  }
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$", timestamp)) {
    stop("Use YYYY-MM-DD HH:MM:SS, or pass an already parsed POSIXct object.")
  }
  value <- suppressWarnings(clock::date_time_parse(
    timestamp, zone = source_timezone, format = "%Y-%m-%d %H:%M:%S",
    nonexistent = "error", ambiguous = "error"
  ))
  if (is.na(value)) stop("Invalid timestamp: ", timestamp)
  value
}

# Find rulers for one timestamp or a vector of timestamps at ONE location.
# source_timezone: where the input clock readings were recorded.
# timezone: where the planetary hours are being calculated.
# For different locations, call this function separately for each location.
#' @export
planetary_hours <- function(timestamp, time = NULL, timezone,
                            latitude, longitude, source_timezone = timezone,
                            on_error = c("stop", "NA")) {
  .check_location(timezone, latitude, longitude)
  on_error <- match.arg(on_error)
  if (!is.character(source_timezone) || length(source_timezone) != 1L ||
      is.na(source_timezone) || !source_timezone %in% OlsonNames()) {
    stop("source_timezone must be a valid time zone name.")
  }
  if (!is.null(time)) {
    if (length(time) != 1L && length(time) != length(timestamp)) {
      stop("time must have length one or the same length as timestamp.")
    }
    dates <- as.character(timestamp)
    missing <- is.na(timestamp) | is.na(rep(time, length.out = length(timestamp)))
    timestamp <- paste(dates, time)
    timestamp[missing] <- NA_character_
  }
  if (!length(timestamp)) stop("Supply at least one timestamp.")
  cache <- new.env(parent = emptyenv())
  get_schedule <- function(date) {
    key <- as.character(date)
    if (!exists(key, envir = cache, inherits = FALSE)) {
      assign(key, planetary_schedule(date, timezone, latitude, longitude), envir = cache)
    }
    get(key, envir = cache, inherits = FALSE)
  }
  blank <- function(status) {
    data.frame(
      timestamp_utc = as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC"),
      local_time = NA_character_, timezone = timezone,
      planetary_date = as.Date(NA_character_), day_ruler = NA_character_,
      hour_ruler = NA_character_, planetary_hour = NA_integer_, period = NA_character_,
      hour_start = as.POSIXct(NA_real_, origin = "1970-01-01", tz = timezone),
      hour_end = as.POSIXct(NA_real_, origin = "1970-01-01", tz = timezone),
      duration_minutes = NA_real_, status = status, stringsAsFactors = FALSE
    )
  }
  rows <- lapply(seq_along(timestamp), function(i) {
    tryCatch({
      instant <- .parse_timestamp(timestamp[i], source_timezone)
      if (is.na(instant)) return(blank("Missing timestamp"))
      local_date <- as.Date(instant, tz = timezone)
      schedule <- get_schedule(local_date)
      # Before today's sunrise, the previous planetary day is still in effect.
      if (instant < schedule$hour_start[1]) schedule <- get_schedule(local_date - 1)
      hour <- which(instant >= schedule$hour_start & instant < schedule$hour_end)
      if (length(hour) != 1L) stop("Timestamp is outside the calculated solar intervals.")
      chosen <- schedule[hour, ]
      result <- blank("OK")
      result$timestamp_utc <- as.POSIXct(as.numeric(instant), origin = "1970-01-01", tz = "UTC")
      result$local_time <- format(instant, "%Y-%m-%d %H:%M:%S %Z", tz = timezone)
      result[names(chosen)] <- chosen
      result
    }, error = function(e) {
      if (on_error == "stop") stop("Timestamp ", i, ": ", conditionMessage(e), call. = FALSE)
      blank(conditionMessage(e))
    })
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}

# Attach ruler columns to any data frame containing a timestamp column.
#' @export
add_planetary_info <- function(data, timestamp_column, timezone,
                               latitude, longitude, source_timezone = timezone,
                               on_error = "NA") {
  if (!is.data.frame(data)) stop("data must be a data frame.")
  if (!is.character(timestamp_column) || length(timestamp_column) != 1L ||
      !timestamp_column %in% names(data)) stop("Choose an existing timestamp column.")
  if (!nrow(data)) stop("The data frame has no rows.")
  info <- planetary_hours(data[[timestamp_column]], timezone = timezone,
                          latitude = latitude, longitude = longitude,
                          source_timezone = source_timezone, on_error = on_error)
  if (any(names(info) %in% names(data))) {
    stop("Output column names already exist in data. Rename them before adding planetary info.")
  }
  cbind(data, info)
}
