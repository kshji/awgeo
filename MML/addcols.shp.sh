#!/bin/bash
# addcols shp-file

# Area code
AREA="$1"
[ "$AREA" = "" ] && echo "usage:$0 area">&2 && exit 1

# Look layers from file, add new column for that and add symbol col for 
# extension using purpose
# loop layers
#ogrinfo -ro -so -q "$GPKG_FILE" | while read ID LAYER
mkdir data
for f in ${area}_*.shp
do
    read id LAYER txt <<<$(ogrinfo -ro -so -q "$f" )
    #LAYER=${f%.shp} # filename include it, but read from file is correct answer
    Xarea=${LAYER#*_}
    table=${{LAYER%%_*}

    echo "l:$LAYER a:$Xarea t:$table"

    continue
    # Add new columns
    ogrinfo "$f" -dialect SQLite -sql "ALTER TABLE $LAYER ADD COLUMN symbol INT"
    ogrinfo "$f" -dialect SQLite -sql "ALTER TABLE $LAYER ADD COLUMN layername TEXT"
    
    # Update layername column with layer name
    ogrinfo "$f" -dialect SQLite -sql "UPDATE $LAYER SET layername = '$LAYER'"
    # Update symbol column with NULL value
    ogrinfo "$f" -dialect SQLite -sql "UPDATE $LAYER SET symbol = NULL"
done
