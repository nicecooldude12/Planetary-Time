# Planetary-Time
This R Package is able accurately calculate the Planetary ruler of the day and hour regardless of location.

# Example use case
planetary_hours("2018-09-02", "19:27", timezone = "Africa/Nairobi", latitude = -1.2921, longitude = 36.8219)

**Output**
Planetary Day: Sun
Planetary Hour: Jupiter

The Chaldean Order goes as follows:
    
| Sunday | Sun |
| Monday | Moon |
|Tuesday | Mars |
| Wednesday | Mercury |
| Thursday | Jupiter |
| Friday | Venus |
| Saturday | Saturn |

And each hour of the day have their own ruler as well:
<img width="800" height="316" alt="Screenshot 2025-11-28 135846" src="https://github.com/user-attachments/assets/a2b7f7bc-985d-46bf-9a57-a8a9cffeb6bf" />

Source: https://en.wikipedia.org/wiki/Planetary_hours



The code uses the crime.csv dataset, 'Crimes in Boston' from Kaggle, which is used to create the results from the planetary_time() function.

The Planetary Time is not used to prove such events has a correlation but show how it can use time values in ways that are reliable.

The function only needs the day and time (24 hour) ie planetary_time("Friday", 1130). 

The use of Planetary Timing can be used in a variety of ways. One of the most common use in Occult tradition is to find the optimal time to execute a ritual. Specfically, the ritual methods written by Johannes Trithemius 'The art of drawing spirits into crystals' written between 1462 - 1516. He established the idea of timing rituals based on the time and day in which an Planet is at its most influential. These Planets loosley uses names of deities such as the Angels in the Judeo-Christian religion that rule over these celestial bodies. These Angels are then made visibile in a crystial for example to, obtainin material wealth, enhancing ones own negotiation skills, contemplating on the mysteries of the universe, etc. If you wish to read the book itself: https://www.esotericarchives.com/tritheim/trchryst.htm


Write up: https://rprogramming21.wordpress.com/2025/11/26/planetary-hours-project/
