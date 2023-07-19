# sortation

This app allows users to scan different parts into sortatation.
Unfortunately Perl is not the best tool for it from many different reasons. The biggest is security or its lack. The code in the app can be easily modified to bypass password (and other functions) + the password is visible while typing.
It is intended to work/look as a standard WMS in case we cannot use the WMS for whatever reason.

The serial number needs to be added to:
db: general
table: stations
columns: id, station, serial_number, path, ip_address
WHERE path & ip_address can be set to whatever e.g. 'NA'
AND station needs to have a structure like 'place_line_type' e.g. 'NLDC_NL07_SORTATION-IN' OR 'NLDC_NL07_SORTATION-OUT'

user: p3user
db: p3
tables(columns):
#1 mpn_bom(id,upc,mpn,type,qty_max),
#2 sort_loc(id,line,location,serial_number,UPC,location_orig,date_in,date_out),
#3 sortation(id,line,location,upc,quantity,status,loc_status,last_change,qty_max,mpn)

The locations in db need to be set up as P3SORTxxxx, otherwise the script will not work.
The loc_status needs to be set to 'LIVE'. This function is not available for the user - it can only be done by a db admin.

# version history

1.0 initial app
3.0 the app has been rebuilt, the logic is simpler now, adding an option to update mpn_bom values from the app interface
