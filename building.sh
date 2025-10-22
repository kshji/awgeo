#!/usr/bin/awsh
# building.sh  
# ver 2025-10-20
# Copyright 2025 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# building.sh  -f input.laz -o outdir
#
# This is proto version, need more testing
#

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

#########################################################################
dbg()
{
        ((DEBUG<1)) && return
        echo "$PRG dbg: $*"  >&2
}

#########################################################################
msg()
{
        ((DEBUG>0)) && return
        echo "$*"  >&2
}

#########################################################################
err()
{
        ((DEBUG<1)) && return
        echo "$PRG err: $*"  >&2
}

#########################################################################
usage()
{
 echo "
        usage:$0 -f input.laz -o outdir [ -e epsg ] [ -d 0|1 ]
	"
}

#################################################
odota()
{
	echo -n "jatka:"
	read jatka
}
#################################################


#################################################
# MAIN
#################################################

# Finland on EPSG,3067
odir=building
inf=""
epsg=3067

while [ $# -gt 0 ]
do
        arg="$1"
        case "$arg" in
                -d) DEBUG="$2" ; shift ;;
                -o) odir="$2" ; shift ;;
                -e) epsg="$2" ; shift ;;
                -f|-i) inf="$2" ; shift ;;
                -*) usage ; exit 1 ;;
        esac
        shift
done

ver="64"  # which lastools "" or 64

[ "$inf" = "" ] && usage && exit 2
[ ! -f "$inf" ] && err "can't open file:$inf" && exit 3

#. $AWGEO/lasview.path
tmpdir="tmp/$$.building"
mkdir -p "$odir" $tmpdir
rm -rf $tmpdir/*.* 2>/dev/null

fname="${inf##*/}"
basename="${fname%*.laz}"
{
# don't use ground = it remove big buildings
# normalize

lasheight$ver -i "$inf" -epsg $epsg -o "$tmpdir"/"${basename}".normalized.laz

# classify
lasclassify$ver -i "$tmpdir"/"${basename}".normalized.laz -planar 0.30 -ground_offset 2.0 -small_buildings -rugged 1.00 -step 4 -epsg $epsg -o "$tmpdir"/"${basename}".buildings3d.laz

lasboundary$ver -i "$tmpdir"/"${basename}".buildings3d.laz -keep_class 6 -concavity 2.5 -disjoint -only_2d -ocut 3 -odix .3d -oshp
# -holes = reiat  -ocut 3 leikkaa nimesta 3 ..

} 2>/dev/null

# remove 3d polygon => 2d polygon
ogr2ogr -q -dim 2 -f "ESRI Shapefile" "$tmpdir"/${basename}.building.shp $tmpdir/${basename}.building.3d.shp 

# add symbol column for Ocad
ogrinfo -q "$tmpdir"/${basename}.building.shp  -sql "ALTER TABLE ${basename}.building ADD COLUMN SYMBOL integer"
# set symbol value 99100 = make symbol for this in the Ocad or convert using crt
ogrinfo -q "$tmpdir"/${basename}.building.shp  -dialect sqlite -sql "UPDATE '${basename}.building' SET SYMBOL=99100 "

# take only >8 m2 buildings, smaller are mostly some mistakes
ogr2ogr -q -f "GPKG"  "$odir"/${basename}.building.gpkg "$tmpdir"/${basename}.building.shp -a_srs "EPSG:$epsg" -dialect sqlite -sql "SELECT * FROM '${basename}.building' WHERE ST_Area(Geometry) > 8 " -nln ${basename}.building
# GPKG Geometry fld is geom

