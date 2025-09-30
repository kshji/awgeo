#!/bin/bash
# addcols gpgk-file

# GeoPackage file
GPKG_FILE="$1"
[ "$GPKG_FILE" = "" ] && echo "usage:$0 input.gpkg">&2 && exit 1
[ ! -f "$GPKG_FILE" = "" ] && echo "can't open $GPKG_FILE">&2 && exit 2

# Look layers from file, add new column for that and add symbol col for 
# extension using purpose
# loop layers
ogrinfo -ro -so -q "$GPKG_FILE" | while read ID LAYER
do
    # Add new columns
    ogrinfo "$GPKG_FILE" -dialect SQLite -sql "ALTER TABLE $LAYER ADD COLUMN symbol INT"
    ogrinfo "$GPKG_FILE" -dialect SQLite -sql "ALTER TABLE $LAYER ADD COLUMN layername TEXT"
    
    # Update layername column with layer name
    ogrinfo "$GPKG_FILE" -dialect SQLite -sql "UPDATE $LAYER SET layername = '$LAYER'"
    # Update symbol column with NULL value
    ogrinfo "$GPKG_FILE" -dialect SQLite -sql "UPDATE $LAYER SET symbol = NULL"
done
