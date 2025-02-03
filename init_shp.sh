#!/usr/local/bin/awsh
#
# Copyright 2025 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# mml2ocad.sh use this init
#
# init_shp.sh -a P5313L
#
# init_shp.sh -s -d 1 -a P5313L -o output/P5313L
# - save data
# - debug

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

#########################################
usage()
{
 echo "
        usage:$0 -a arealabel [ -s ] [ -o outputdir ] [ -d 0|1 ]
        input directory has to be arealabel.zip file
        -s save unziped files, default no
	-o destdir , default is data/arealabel
	-d 0|1 , debug, def 0
        " >&2
}

#######################################
dbg()
{
        ((DEBUG<1)) && return
        echo "$PRG dbg: $*" >&2
}


#########################################
remove_file()
{
        savefile="$1"
        ((savefile != 0 )) && return
        rm -rf "$2".??? 2>/dev/null
}
#########################################

save=0
debug=0

arealabel=""
outputdir=""
inputdir="$PWD/input"
while [ $# -gt 0 ]
do
        arg="$1"
        case "$arg" in
		-a) arealabel="$2" ; shift 
			[ "$outputdir" = "" ] && outputdir="output/$arealabel"
			;;
                -s) save=1 ;;
		-o) outputdir="$2" ; shift ;;
		-i) inputdir="$2" ; shift ;;
                -d) DEBUG=$2; shift ;;
                -*) ;;
                *) break ;;
        esac
        shift
done

[ "$arealabel" = "" ] && usage && exit 1
dbg "$PRG - $arealabel"
zipf="$inputdir/$arealabel.shp.zip"


dbg "$PWD - $zipf"
((DEBUG>0)) && ls -l *zip
[ ! -f "$zipf" ] && echo "ei ole $zipf" >&2 && exit 2

# Relative path or absolute path
case "$zipf" in
	/*) ;;
	*) zipf="$PWD/$zipf" ;; # relative path => absolute
esac


#rm -rf "$arealabel" 2>/dev/null

NPWD=$PWD
mkdir -p "$outputdir" 2>/dev/null
cd "$outputdir"
unzip -oqj $zipf

mergeshp="merged"

rm -f "$mergeshp" 2>/dev/null

dbg  ?_${arealabel}_?.shp
for shp in ?_${arealabel}_?.shp
do
        echo " - $shp"
        dbg "  make $shp"
        label="${shp%.*}"
        # last char
        first=${label%_*}
        chr1=${label:0:1}
        chrN=${label##*_}
        if [ "$chrN" = "t" ] ; then # text file not merge
		# remove if not like to save
		remove_file $save "${chr1}_${arealabel}_$chrN"
		continue
	fi

        dbg "label:$label"
        dbg "first:$first"
        dbg "chr1:$chr1"
        dbg "chrN:$chrN"

        mergelayer="merge_$chrN"

        # first file
        echo ""
        dbg "$mergelayer.shp - $shp "
        dbg ""
        [ ! -f "$mergelayer.shp" ] && ogr2ogr -f 'ESRI Shapefile' "$mergelayer.shp" "$shp" && \
                remove_file $save "${chr1}_${arealabel}_$chrN" && \
                continue
        # update $mergeshp" layer  = -nlm "$mergeshp"
        dbg "add $mergelayer.shp <pre>"
        ogr2ogr -f 'ESRI Shapefile' -update -append  "$mergelayer.shp" "$shp" -nln "$mergelayer"
        dbg "___________________________"
        remove_file $save "${chr1}_${arealabel}_$chrN"
done


cd $NPWD
echo "dir $arealabel merged files dir:$outputdir" >&2

