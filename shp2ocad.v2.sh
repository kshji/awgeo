#!/usr/local/bin/awsh
# shp2ocad.sh
#
#
# Copyright 2025 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# Convert shp files to Ocad (dxf / gpkg)
#
# shp2ocad.sh P5313L.shp.zip
# - input from shp.zip files or shp files
# - output default mml/5313L
# shp2ocad.sh -o result/P5313L P5313L.shp.zip many zip files
# shp2ocad.sh -o result/P5313L *.shp many shp files
#

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


#######################################
dbg()
{
        ((DEBUG<1)) && return
        echo "$PRG dbg: $*"
}

#########################################
usage()
{
 echo "
        usage:$0 [ -o outputdir ] [ -c crtfile ] [ -d 0|1 ]  shpfiles or shpzip files
        -s save unziped files, default no
        -o destdir , default is 2ocad
        -c crtfile, default is $crtfile
        -d 0|1 , debug, def 0
        " >&2
}


#########################################
update_some_symbols_v()
{
        Xdb="$1"
        Xfile="$2"
        #update_some_symbols_v "merge_$t.shp"
        :
        # rantaviiva
        ogrinfo  "$Xfile"   -dialect SQLite -sql "
          UPDATE  $Xdb
          SET symbol=42300
          WHERE kartoglk=36200
        "
        # kuvioraja
        ogrinfo  "$Xfile"   -dialect SQLite -sql "
          UPDATE  $Xdb
          SET symbol=30212
          WHERE kartoglk=39110
        "
        # ei nayteta kumpaakaan kuviorajaa tiettyjen alueiden reunalla (suo yms)
        ogrinfo  "$Xfile"   -dialect SQLite -sql "
          UPDATE  $Xdb
          SET symbol=0
          WHERE symbol IN (30211,30212) AND kartoglk IN (32111,32112,32500,32900,34100,34300,34700,35300,35400,35411,35412,35421,35422,38300,38600,38700)        "
}


#########################################
















#########################################################################
# MAIN
#########################################################################

DXF_ENCODING=LATIN1
export DXF_ENCODING

crtfile=$AWGEO/config/FIshp2ISOM2017.v2.crt
outputdir=""
arealabel=""
inputdir=""

while [ $# -gt 0 ]
do
        arg="$1"
        case "$arg" in
                -d) DEBUG="$2" ; shift ;;
                -a) arealabel="$2" ; shift
                        [ "$outputdir" = "" ] && outputdir="mml/$arealabel"
                        [ "$inputdir" = "" ] && inputdir="sourcedata/$arealabel"
                        ;;
                -o) outputdir="$2" ; shift ;;
                -i) inputdir="$2" ; shift ;;
                -c) crtfile="$2" ; shift ;;
        esac
        shift
done

[ "$arealabel" = "" ] && usage && exit 1
[ "$inputdir" = "" ] && usage && exit 2
[ ! -d "$inputdir" = "" ] && echo "no dir:$inputdir " >&2 && exit 3
[ ! -f "$crtfile" ] && echo "no crtfile:$crtfile" >&2 && exit 4

[ ! -f "$inputdir/merge_v.shp" ] && echo "init_shp.sh not done? No merge_?.shp files in $inputdir" >&2 exit 6

Xnow=$PWD

# v = viivat
# p = alueet talot, pellot, suot, tontti, kivikot
# s = symbolit

rm -rf "$inputdir/dxf" 2>/dev/null
rm -f "$inputdir/merge*.dxf" merged_*  2>/dev/null
rm -f "$inputdir/merged_*.*"  2>/dev/null
rm -f "$inputdir/merged*.csv"  2>/dev/null
mkdir -p "$inputdir/dxf" 2>/dev/null

dbg "inputdir $inputdir"
cd "$inputdir"
for t in s p v  #t teksti ei  #
do

        #if ((1<1)) ; then
        dbg ogrinfo  merge_$t.shp -sql "ALTER TABLE merge_$t ADD COLUMN angle character(254)"
        ogrinfo  merge_$t.shp -sql "ALTER TABLE merge_$t ADD COLUMN angle character(254)"

        dbg ogrinfo  merge_$t.shp   -dialect SQLite -sql "UPDATE angle ..."
        ogrinfo  merge_$t.shp   -dialect SQLite -sql "
          UPDATE  merge_$t
                SET angle=CAST(SUUNTA*1.0/10000.0/3.14159*180.0  AS  character(254) )
          WHERE SUUNTA IS NOT NULL
        "

        # unique symbol col add
        dbg  ogrinfo merge_$t.shp -sql "ALTER TABLE merge_$t ADD COLUMN symbol integer(6)"
        ogrinfo  merge_$t.shp -sql "ALTER TABLE merge_$t ADD COLUMN symbol integer(6)"
        # default 0
        dbg ogrinfo  merge_$t.shp   -dialect SQLite -sql "update symbol=0"
        ogrinfo  merge_$t.shp   -dialect SQLite -sql "
          UPDATE  merge_$t
          SET symbol=luokka
        "

        # if v = viiva = polygon - update some symbols
        [ "$t" = "v" ] && update_some_symbols_v "merge_$t.shp"

        dbg ogr2ogr  -f CSV merge_$t.csv -dialect SQLite -sql "SELECT DISTINCT symbol FROM merge_$t " merge_$t.shp
        ogr2ogr  -f CSV merge_$t.csv -dialect SQLite -sql "SELECT DISTINCT symbol FROM merge_$t " merge_$t.shp   2>/dev/null        dbg make_symbol_dxf "$t"

        make_symbol_dxf "$t"

done






cd $Xnow

mkdir -p "$outputdir"
dbg mv -f $inputdir/${arealabel}_?.dxf "$outputdir"
mv -f $inputdir/${arealabel}_?.dxf "$outputdir"

if [ -d "$outputdir" ] ; then
        cp -rf "$TEMP"/* "$outputdir" 2>/dev/null
        # some files to use data in the Ocad
        cp -f $AWGEO/config/*.crt "$outputdir" 2>/dev/null
        cp -f $AWGEO/config/*.ocd "$outputdir" 2>/dev/null
fi
