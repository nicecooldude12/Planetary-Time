# Planetary-Time
This **SOON TO BE** R Package is able accurately calculate the Planetary ruler of the day and hour regardless of location. This was made with a dataset usage in mind by allowing Planetary-Time able to read past dates.

## Example usage

```r
planetary_hours(
  "2018-09-02",
  "19:27",
  timezone = "Africa/Nairobi",
  latitude = -1.2921,
  longitude = 36.8219
)
```

Example output:

```text
Planetary Day: Sun
Planetary Hour: Jupiter
```

## How planetary hours work

The traditional system assigns a ruler to each weekday and follows a repeating sequence for the hours.

### Weekday rulers

| Day | Planetary ruler |
| --- | --- |
| Sunday | Sun |
| Monday | Moon |
| Tuesday | Mars |
| Wednesday | Mercury |
| Thursday | Jupiter |
| Friday | Venus |
| Saturday | Saturn |

### Hourly sequence

The **Chaldean order** is:

**Saturn → Jupiter → Mars → Sun → Venus → Mercury → Moon**

The first hour after sunrise takes the ruler of that weekday. Subsequent hours follow the sequence above, repeating as needed.

In the traditional calculation, daylight from sunrise to sunset is divided into **12 equal intervals**. Nighttime from sunset to the following sunrise is divided into another **12 equal intervals**. These planetary hours are therefore not necessarily 60 minutes long, and the planetary day begins at sunrise rather than midnight.

The date and coordinates provide the context for sunrise and sunset; the timezone provides the context for the recorded clock time.

## Historical background
Planetary hours appear in historical astrological and ceremonial traditions, including *The Art of Drawing Spirits into Crystals*, a text attributed to Johannes Trithemius. These traditions use planetary days and hours to choose times for particular activities.

This historical framework provides the project's inspiration; its computational focus is translating timekeeping rules into reproducible calculations.

## References
- [The Art of Drawing Spirits into Crystals: text and editorial notes](https://www.esotericarchives.com/tritheim/trchryst.htm)

- [Original project write-up, November 2025](https://rprogramming21.wordpress.com/2025/11/26/planetary-hours-project/)
