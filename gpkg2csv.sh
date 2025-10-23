#!/usr/bin/awsh
# gpkg2csv.sh
# v. 2025-10-10
# gpkg2csv.sh input.gpkg
# csv have to include field SYMBOL

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


#############################################
dbg()
{
        ((DEBUG<1)) && return
        echo "$*" >&2
}


#############################################
# MAIN
#############################################

DEBUG=0
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-d|--debug) DEBUG=$2; shift ;;
		*) break ;;
	esac
	shift
done

infile="$1"
tilename="$2"
[ "$infile" = "" ] && echo "usage:$PRG inputfile tilename" >&2 && exit 1
[ "$tilename" = "" ] && echo "usage:$PRG inputfile tilename" >&2 && exit 1

dbg "$PRG dir:$PWD infile:$infile tilename:$tilename"

# loop tables v,t,s,p, palstatunnus, kiinteistoraja, ...
#for table in palstatunnus t s
ogrinfo -q -so -ro "$infile" | while read Xid tablename Xdescription
do


	dbg "   table:$tablename"
	case "$tablename" in
		s|t|palstatunnus)
			dbg "   ogr2ogr -f CSV $tilename.$tablename.csv $infile -dialect  postgresql -sql \"SELECT * FROM $tablename\" -lco GEOMETRY=AS_WKT -lco \"SEPARATOR=SEMICOLON\" "
			ogr2ogr -f CSV $tilename.$tablename.csv $infile -dialect  postgresql -sql "SELECT * FROM $tablename" -lco GEOMETRY=AS_WKT -lco "SEPARATOR=SEMICOLON"   
			dbg "   ogr2ogr -f CSV $tilename.$tablename.symbols.csv $infile -dialect  postgresql -sql \"SELECT DISTINCT(SYMBOL) AS SYMBOL  FROM $tablename ORDER BY SYMBOL\" -lco GEOMETRY=AS_WKT -lco \"SEPARATOR=SEMICOLON\"  "
			ogr2ogr -f CSV $tilename.$tablename.symbols.csv $infile -dialect  postgresql -sql "SELECT DISTINCT(SYMBOL) AS SYMBOL  FROM $tablename ORDER BY SYMBOL" -lco GEOMETRY=AS_WKT -lco "SEPARATOR=SEMICOLON"
			;;
	esac
done        

dbg "$PRG done"
exit 0

#########################################################
# if need to calculate angle ...
#ogr2ogr -f CSV $x.csv N5424D_$x.shp -dialect  postgresql -sql "SELECT LUOKKA, SUUNTA, CAST(SUUNTA*1.0/10000.0/3.14159*180.0  AS  character(254) ) AS ANGLE, TEKSTI AS TEXT,geom FROM N5424D_$x" -lco GEOMETRY=AS_WKT -lco "SEPARATOR=SEMICOLON"                      
