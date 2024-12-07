#!/usr/local/bin/awsh
# mml2ocad.sh
#
# $AWGEO/get.mmlshp2ocad.sh -a P5313L
# - input default: dir sourcedata/P5313L include P5313L.shp.zip or if not, it will get if you have $AWMML defined
# - output default: mml/P5313L
#
# You can set in ja out dirs
# mml2ocad.sh -y 2022 -a P5313L -i sourcedata/ -o myoutput/5313L
#
# Do all:
# mml2ocad.sh -y 2022 -a 5313L
# - get maastotietokanta, kiinteisto, metsankasittelyilmoitukset
# - make dxf
# - all input are in the sourcedata
# - all result in the mml/area
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
        echo "$PRG dbg: $*" 
}

#########################################################################
usage()
{
 echo "
        usage:$0 -a arealabel angle [ -i inputdir ] [ -o outputdir ] [ -d 0|1 ]
        -o destdir , default is mml/arealabel
	-i inputdir, include arealabel.shp.zip, default is $inputdir
	-s save temp files, default 0
	-c crtfile, default is $crtfile
        -d 0|1 , debug, def 0
        " >&2
}

#########################################################################
get_metsa()
{
	Xarea="$1"
	Xin="$2"
	#Xin=${Xin%/*}
	# remove area label from dir
	Xin=${Xin/\/${Xarea}/}
	[ "$AWMML" = "" ] && echo "no \$AWMML env variable">&2 && exit 9
	[ ! -f $AWMML/get.metsa.sh ] && echo "no program $AWMML/get.metsa.sh" >&2 exit 10
	[ "$Xin" = "" ] && echo "not set inputdir" >&2 && return 1
	[ "$Xarea" = "" ] && echo "not set areacode" >&2 && return 1
	mkdir -p "$Xin"
	$AWMML/get.metsa.sh -y "$year" -o "$Xin"  "$Xarea"
}

#########################################################################
get_mml_kiinteisto()
{
	Xarea="$1"
	Xin="$2"
	#Xin=${Xin%/*}
	# remove area label from dir
	Xin=${Xin/\/${Xarea}/}
	[ "$AWMML" = "" ] && echo "no \$AWMML env variable">&2 && exit 9
	[ ! -f $AWMML/get.mml.kiinteisto.sh ] && echo "no program $AWMML/get.kiinteisto.sh" >&2 exit 10
	[ "$Xin" = "" ] && echo "not set inputdir" >&2 && return 1
	[ "$Xarea" = "" ] && echo "not set areacode" >&2 && return 1
	mkdir -p "$Xin"
	$AWMML/get.mml.kiinteisto.sh -o "$Xin"  "$Xarea"
}

#########################################################################
get_mml_shp()
{
	# get_mml_shp "$arealabel" "$inputdir"
	Xarea="$1"
	Xin="$2"
	#Xin=${Xin%/*}
	# remove area label from dir
	Xin=${Xin/\/${Xarea}/}
	[ "$AWMML" = "" ] && echo "no \$AWMML env variable">&2 && exit 9
	[ ! -f $AWMML/get.mml.maastotietokanta.sh ] && echo "no program $AWMML/get.maastotietokanta.sh" >&2 exit 10
	[ "$Xin" = "" ] && echo "not set inputdir" >&2 && return 1
	[ "$Xarea" = "" ] && echo "not set areacode" >&2 && return 1
	mkdir -p "$Xin"
	$AWMML/get.mml.maastotietokanta.sh -o "$Xin"  "$Xarea"
}
#########################################################################
# MAIN
#########################################################################

DXF_ENCODING=LATIN1
export DXF_ENCODING

crtfile=$AWGEO/config/FIshp2ISOM2017.crt
ocdtemplate="$AWGEO/config/awot_ocadisom2017_mml.ocd"
outputdir=""
arealabel=""
inputdir=""
save=0
year=$(date +'%Y')
(( year=year-3 )) # default 3 years

angle="11.0"

while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-d) DEBUG="$2" ; shift ;;
		-a) arealabel="$2" ; shift
			angle="$3" ; shift
                        [ "$outputdir" = "" ] && outputdir="mml/$arealabel"
                        [ "$inputdir" = "" ] && inputdir="sourcedata/$arealabel"
                        ;;
                -o) outputdir="$2" ; shift ;;
                -t) ocdtemplate="$2" ; shift ;;
                -y) year="$2" ; shift ;;
		-s) save=1 ;;
                -i) inputdir="$2" ; shift ;;
                -c) crtfile="$2" ; shift ;;
	esac
	shift
done

datadir="data/$arealabel"
dbg "inputdir:$inputdir datadir:$datadir outputdir:$outputdir"
[ "$arealabel" = "" ] && usage && exit 1
[ "$inputdir" = "" ] && usage && exit 2
[ ! -d "$inputdir" = "" ] && usage && exit 2
[ ! -f "$crtfile" ] && echo "no crtfile:$crtfile" >&2 && exit 4

mkdir -p "$inputdir" "$datadir" "$outputdir"

((DEBUG>2)) && exit 0
# get mml shp, if not already exists
# even it's new version, source is shp.zip
[ ! -f "$inputdir/$arealabel.shp.zip" ] && get_mml_shp "$arealabel" "$inputdir"
# not lucky ...
[ ! -f "$inputdir/$arealabel.shp.zip" ] && echo "no input file:$inputdir/$arealabel.shp.zip" >&2 && exit 5

# get mml kiinteisto, if not already exists
[ ! -f "$inputdir/$arealabel.kiinteistoraja.gpkg" ] && get_mml_kiinteisto "$arealabel" "$inputdir"
# get metsa, if not already exists
[ ! -f "$inputdir/$arealabel.metsa.gpkg" ] && get_metsa "$arealabel" "$inputdir"

# if we have also area map from MML, copy to the output
[ -f "$inputdir/$arealabel.png" ] && cp -f "$inputdir/$arealabel.png" "$outputdir/$arealabel.png" 2>/dev/null
[ -f "$inputdir/$arealabel.pgw" ] && cp -f "$inputdir/$arealabel.pgw" "$outputdir/$arealabel.pgw" 2>/dev/null

# remove old files if exists
#rm -rf "$datadir" 2>/dev/null

# org method was SHP => DXF
# new method is gtkp => DXF
#
#
# if exists then new version 
gpkg_v_file="$inputdir/$arealabel.v.gpkg"

if [ ! -f "$gpkg_v_file" ] ;then # old shp version
	dbg "no $gpkg_v_file, use shp.zip"
	$AWGEO/init_shp.sh -d $DEBUG -a "$arealabel" -o "$datadir" -i "$inputdir"  -d "$DEBUG"
	$AWGEO/shp2ocad.sh -a  "$arealabel" -i "$datadir" -o "$outputdir" -d "$DEBUG"
else # new gpkg
	dbg "we have new gpkg format $gpkg_v_file"
fi

saveflag=""
((save>0)) && saveflag=" -s "

# other materials? gpkg format rest of data
# kiinteisto, metsa, maastotietokanta new format, ...
# $AWGEO/gpkg2ocad.sh -a N5424L -i sourcedata -o mml/N5424L -d 1 -s
$AWGEO/gpkg2ocad.sh -a  "$arealabel" -i "$inputdir" -o "$outputdir" -d "$DEBUG" $saveflag

if (( save<1 )) ; then
	# no save
        rm -rf "$datadir" 2>/dev/null
fi

[ -f "$crtfile" ] && cp -f "$crtfile" "$outputdir" 2>/dev/null
[ -f "$ocdtemplate" ] && cp -f "$ocdtemplate" "$outputdir"/$arealabel.mml.ocd 2>/dev/null

echo "shp inputfiles dir:$inputdir"
echo "gpkg inputfiles dir:$inputdir"
echo "result file dir:$outputdir"
