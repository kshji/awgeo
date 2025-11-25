#!/usr/local/bin/awsh
# mml2ocad.sh
# ver 2025-11-25
# Copyright 2025 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# $AWGEO/mml2ocad.sh --angle -10.6 -a N5424L		   # outputdir sourcedata/N5424L
# $AWGEO/mml2ocad.sh --angle -10.6 -a N5424L -o mmlkoe  # output to dir mmlkoe/N5424L
# $AWGEO/mml2ocad.sh --angle -10.6 -a N5424L -m mapname -o mmlkoe  # output to dir mmlkoe/N5424L
#
#
# You can set in ja out dirs
# mml2ocad.sh -y 2022 -a N5424L -i sourcedata -o mml/N5424L
#
# Do all:
# mml2ocad.sh -y 2022 -a 5313L
# - get maastotietokanta, kiinteisto, metsankasittelyilmoitukset
# - make dxf
# - all input are in the sourcedata
# - all result in the mml/area
#
# After this cmd you can process lidar data ex.
# $AWGEO/pullauta.run.sh all --in sourcedata/N5424L --out pullautettu/N5424L -a -10.6 -i 0.625 -z 3
#
# after those steps:
#    - MML data dir: mml/N5424L
#    - pullautin data dir: pullautettu/N5424L
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
err()
{
        #((DEBUG<1)) && return
        echo "$PRG err: $*"  >&2
}

#########################################################################
msg()
{
        ((DEBUG>0)) && return
        echo "$*"  >&2
}

#########################################################################
usage()
{
 echo "
        usage:$0 -a arealabel [ --angle ] [ -m mapname ] [ -i inputdir ] [ -o outputdir ] [ -d 0|1 ]
        -o destdir , default is mml/arealabel
	-i inputdir, include arealabel.shp.zip, default is $inputdir
	-s save temp files, default 0
	-c crtfile, default is $crtfile
	--tiledir 0|1   , subdir using tilename or not
	-m mapname # add extra element to the output files
        -d 0|1 , debug, def 0
        " >&2
}

#########################################################################
get_metsa()
{
	Xarea="$1"
	Xin="$2"
	dbg "get_metsa BEGIN Xarea:$Xarea Xin:$Xin"
	#Xmapname="$3"
	#Xin=${Xin%/*}
	# remove area label from dir
	Xin=${Xin/\/${Xarea}/}
	[ "$AWMML" = "" ] && echo "no \$AWMML env variable">&2 && exit 9
	[ ! -f $AWMML/get.metsa.sh ] && echo "no program $AWMML/get.metsa.sh" >&2 exit 10
	[ "$Xin" = "" ] && echo "not set inputdir" >&2 && return 1
	[ "$Xarea" = "" ] && echo "not set areacode" >&2 && return 1
	#((tiledir>0)) && Xin="$Xin"/"$Xarea"
	mkdir -p "$Xin"
	#dbg $AWMML/get.metsa.sh -y "$year" -o "$Xin"  -t "$tiledir" --mapname "$Xmapname" "$Xarea"
	#msg $AWMML/get.metsa.sh -y "$year" -o "$Xin"  -t "$tiledir" --mapname "$Xmapname" "$Xarea"
	#$AWMML/get.metsa.sh -y "$year" -o "$Xin"  -t "$tiledir" --mapname "$Xmapname" "$Xarea"
	msg $AWMML/get.metsa.sh -y "$year" -o "$Xin"  -t "$tiledir" -d "$DEBUG" "$Xarea"
	dbg $AWMML/get.metsa.sh -y "$year" -o "$Xin"  -t "$tiledir" -d "$DEBUG" "$Xarea"
	$AWMML/get.metsa.sh -y "$year" -o "$Xin"  -t "$tiledir" -d "$DEBUG" "$Xarea"
}

#########################################################################
get_mml_kiinteisto()
{
	Xarea="$1"
	Xin="$2"
	Xmapname="$3"
	#Xin=${Xin%/*}
	# remove area label from dir
	Xin=${Xin/\/${Xarea}/}
	[ "$AWMML" = "" ] && echo "no \$AWMML env variable">&2 && exit 9
	[ ! -f $AWMML/get.mml.kiinteistokartta.sh ] && echo "no program $AWMML/get.kiinteisto.sh" >&2 exit 10
	[ "$Xin" = "" ] && echo "not set inputdir" >&2 && return 1
	[ "$Xarea" = "" ] && echo "not set areacode" >&2 && return 1
	Xoutdir="$Xin"
	((tiledir>0)) && Xoutdir="$Xin"/"$Xarea"
	mkdir -p "$Xin"
	#$AWMML/get.mml.kiinteisto.sh -o "$Xin"  "$Xarea"
	dbg "$AWMML/get.mml.kiinteistokartta.sh -u 0 -o $Xoutdir  -d "$DEBUG" $Xarea"
	msg "$AWMML/get.mml.kiinteistokartta.sh -u 0 -o $Xoutdir  -d "$DEBUG" $Xarea"
	$AWMML/get.mml.kiinteistokartta.sh -u 0 -o "$Xoutdir"  --mapname "$Xmapname" -d "$DEBUG" "$Xarea"
}

#########################################################################
get_mml_shp()
{
	# get_mml_shp "$arealabel" "$inputdir"
	Xarea="$1"
	Xin="$2"
	Xmapname="$3"
	#Xin=${Xin%/*}
	# remove area label from dir
	Xin=${Xin/\/${Xarea}/}
	[ "$AWMML" = "" ] && echo "no \$AWMML env variable">&2 && exit 9
	[ ! -f $AWMML/get.mml.maastotietokanta.sh ] && echo "no program $AWMML/get.maastotietokanta.sh" >&2 exit 10
	[ "$Xin" = "" ] && echo "not set inputdir" >&2 && return 1
	[ "$Xarea" = "" ] && echo "not set areacode" >&2 && return 1
	mkdir -p "$Xin"
	####$AWMML/get.mml.maastotietokanta.sh -o "$Xin"  "$Xarea"
	dbg "$AWMML/get.mml.maastotietokanta.sh -p 0 -g 0 -t $tiledir -o $Xin  --mapname "$Xmapname"-d "$DEBUG" $Xarea"
	msg "$AWMML/get.mml.maastotietokanta.sh -p 0 -g 0 -t $tiledir -o $Xin  --mapname "$Xmapname"-d "$DEBUG" $Xarea"
	$AWMML/get.mml.maastotietokanta.sh -p 1 -g 0 -t "$tiledir" -o "$Xin"  --mapname "$Xmapname" -d "$DEBUG" "$Xarea"

	# tuloksena on sourcedata on jo gpkg tiedostoja !!!
}
#########################################################################
# MAIN
#########################################################################

DXF_ENCODING=LATIN1
export DXF_ENCODING

EPSG=""
[ -f "$AWMML/epsg.cfg" ] && . "$AWMML"/epsg.cfg 

# if set, save
AWGEOSAVE="$AWGEO"
# set AWGEO
awgeoinifile="awgeo.ini"
[ ! -f "$awgeoinifile" ] && awgeoinifile="config/awgeo.ini"
[ ! -f "$awgeoinifile" ] && awgeoinifile="$AWGEO/config/awgeo.ini"
[ ! -f "$awgeoinifile" ] && err "no awgeo.ini file dir: . or ./config or $AWGEO/config" >&2 && exit 2
. "$awgeoinifile" 2>/dev/null
[ "$AWGEOSAVE" != "" ] && AWGEO="$AWGEOSAVE"
export AWGEO
[ "$AWGEO" = "" ] && err "AWGEO env not set" && exit 3

crtfile="$AWGEO/config/FI*shp2ISOM2017.crt"
ocdtemplate="$AWGEO/config/awot_ocadisom2017_mml.ocd"
[ "$AWCRT" != "" ] && crtfile="$AWCRT"
[ "$AWOCD" != "" ] && ocdtemplate="$AWOCD"
outputdir=""
arealabel=""
inputdir=""
save=0
year=$(date +'%Y')
tiledir=1

(( year=year-3 )) # default 3 years

angle="0"
mapname=""

while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-d) DEBUG="$2" ; shift ;;
		--angle) angle="$2" ; shift ;;
		-a) arealabel="$2" ; shift
                        [ "$outputdir" = "" ] && outputdir="mml/$arealabel"
                        [ "$inputdir" = "" ] && inputdir="sourcedata/$arealabel"
                        ;;
                -o) outputdir="$2" ; shift ;;
		--tiledir) tiledir="$2" ; shift ;;
		-m|--mapname) mapname="$2" ; shift ;;
                -t) ocdtemplate="$2" ; shift ;;
                -y) year="$2" ; shift ;;
		-s) save=1 ;;
                -i) inputdir="$2" ; shift ;;
                -c) crtfile="$2" ; shift ;;
	esac
	shift
done

# mapname used only to make outfiles to outdir !!!
[ "$mapname" != "" ] && mapname="$mapname."

datadir="data/$arealabel"
dbg "inputdir:$inputdir datadir:$datadir outputdir:$outputdir"
[ "$arealabel" = "" ] && usage && exit 4
#[ "$inputdir" = "" ] && usage && exit 4
#[ ! -d "$inputdir" = "" ] && usage && exit 4
#[ ! -f "$crtfile" ] && echo "no crtfile:$crtfile" >&2 && exit 4

dbg mkdir -p "$inputdir" "$outputdir"
mkdir -p "$inputdir" "$outputdir"

((DEBUG>2)) && exit 9
# get mml shp, if not already exists
# even it's new version, source is shp.zip
[ ! -f "$inputdir/$arealabel.shp.zip" ] && get_mml_shp "$arealabel" "$inputdir" #"$mapname"
# not lucky ...
[ ! -f "$inputdir/$arealabel.shp.zip" ] && echo "no input file:$inputdir/$arealabel.shp.zip" >&2 && exit 5

# get mml kiinteisto, if not already exists
# ei ole nykyisin ikina ...
[ ! -f "$inputdir/$arealabel.kiinteistoraja.gpkg" ] && get_mml_kiinteisto "$arealabel" "$inputdir" #"$mapname"
# get metsa, if not already exists
[ ! -f "$inputdir/$arealabel.metsa.gpkg" ] && get_metsa "$arealabel" "$inputdir" #"$mapname"

# if we have also area map from MML, copy to the output
[ -f "$inputdir/$arealabel.png" ] && cp -f "$inputdir/$arealabel.png" "$outputdir/$mapname$arealabel.png" 2>/dev/null
[ -f "$inputdir/$arealabel.pgw" ] && cp -f "$inputdir/$arealabel.pgw" "$outputdir/$mapname$arealabel.pgw" 2>/dev/null


masterarea=${arealabel:0:4}
# process input to output
dbg "$AWMML/shpzip2gpkg.sh -t 0 -o $outputdir -a $angle -n $arealabel --mapname "$mapname" -d $DEBUG -e "$EPSG" $inputdir/${masterarea}*.*"
msg "$AWMML/shpzip2gpkg.sh -t 0 -o $outputdir -a $angle -n $arealabel --mapname "$mapname" -d $DEBUG -e "$EPSG" $inputdir/${masterarea}*.*"
$AWMML/shpzip2gpkg.sh -t 0 -o "$outputdir" -a "$angle" -n "$arealabel" --mapname "$mapname" -d "$DEBUG" -e "$EPSG" "$inputdir"/"${masterarea}"*.* 

dbg "crtfile:$crtfile" 
dbg "ocdtemplate:$ocdtemplate" 
#[ -f "$crtfile" ] && cp -f "$crtfile" "$outputdir" 2>/dev/null
# crtfile 1-n, it's possible
cp -f $crtfile "$outputdir" 2>/dev/null
[ -f "$ocdtemplate" ] && cp -f "$ocdtemplate" "$outputdir"/$mapname$arealabel.ocd 2>/dev/null

echo "shp inputfiles dir:$inputdir"
echo "gpkg inputfiles dir:$inputdir"
echo "result file dir:$outputdir"
