# atptour19

Conversion of ATP tennis data to csv or json format.

## Background

I have been using Jeff Sackman's tennis ATP database but he updates it once a year or so.

I've tried to duplicate the data and format, but it is too complicated and error-prone with 
changes in HTML structure at atptour.com. And then he uses his own player id's which I then have to map to the ATP ids.

So I am making a smaller database with a more relational format. I am using ATP's player ids and match numbers.

I will upload the parsed data files in either tab-delimited format, or json format or both with scripts to import.

This project is mostly done in bash (shell) and ruby with nokogiri.

