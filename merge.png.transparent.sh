#!/usr/bin/env bash
# ksh or bash or ...
# merge.png.transparent.sh
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# $AWGEO/merge.png.transparent.sh -b basefile -t transparentfile -o outputfilename
# $AWGEO/merge.png.transparent.sh -b N5424F3.hillshade.tif -t  N5424F3.laz_depr.png -o merged.png
#
VER="2024-11-22.a"
#
# 
#

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

########################################################
usage()
{
	cat <<EOF >&2
usage:$PRG -b basefile -t transparentfile -o outputfilename [ -d 0|1 ]
	-d 0|1   # debug, 0 default
	-o outputfilename have to be png

EOF
	
}

########################################################
step()
{
	dbg "-step:$*" 
}

########################################################
status()
{
	dbg "-status:$*" 
}

########################################################
err()
{
	echo "err:$*" >&2
}

########################################################
dbg()
{
	[ $DEBUG -lt 1 ]  && return
	echo "  $*" >&2
}
  
################################################################
last_slash()
{
        str="$*"
        len=${#str}
        ((len-=1))
        last=${str:$len:1}
        [ "$last" = "/" ] && str=${str:0:len}
        echo "$str"
}

################################################################
getdir()
{
        str="$*"
        strorg="$str"
        [ "$str" = "/" ] && str=""
        str=$(last_slash "$str")
        # ei saa poistaa jos on jo hakemisto !!!
        [ -d "$str" ] && print -- "$str" && return
        #[ "$strorg" = "$str" ] && print -- "." && return
        echo "${str%/*}"
}

################################################################
getfile()
{
        str="$*"
        echo "${str##*/}"
}

################################################################
getfileend()
{
        str="$*"
        echo "${str##*.}"
}


################################################################
getbase()
{
        str="$1"
        remove="$2"
        echo "${str%$remove}"
        #eval echo "\${str//$2/}"
}



########################################################
clear_result()
{
	rm -f "$result".tif "$result".ground.laz  2>/dev/null
}

################################################################
# defaults
set_def()
{
        :
}

########################################################
# MAIN
########################################################
inf=""
set_def
mkdir -p tmp 2>/dev/null
id=$$ # process number = unique id for tempfiles
TEMP="tmp/$id"
outfile=""
force=0
basefile=""
transparentfile=""


# parse cmdline options
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-b) basefile="$2" ; shift ;;
		-t) transparentfile="$2" ; shift ;;
		-o) outfile="$2" ; shift ;;
		-d) DEBUG="$2"; shift  ;;
		-v) echo "$PRG Ver:$VER" >&2 ;;
		-h) usage ; exit 1 ;;
		-*) usage ; exit 1 ;;
		*) break ;;  # filenames
	esac
	shift
done

mkdir -p "$outputdir" 2>/dev/null

[ "$basefile" = "" ] && usage && exit 1
[ "$transparentfile" = "" ] && usage && exit 2
[ "$outfile" = "" ] && usage && exit 2

btype=$(getfileend "$basefile")
ttype=$(getfileend "$transparentfile")
otype=$(getfileend "$outfile")

[ "$otype" != "png" ] && usage "outputfile type have to be .png" && exit 3

# both have to be png, if not - we make conversion
bfile="$TEMP.b.png"
tfile="$TEMP.t.png"
dbg "$basefile $btype"
dbg "$transparentfile $ttype"

cp -f "$basefile" $bfile 2>/dev/null
cp -f "$transparentfile" $tfile 2>/dev/null
if [ "$btype" != "png" ] ; then # convert to png
	dbg "convert basefile => png"
	gdal_translate -co WORLDFILE=YES -of PNG "$basefile"  "$bfile"
fi
if [ "$ttype" != "png" ] ; then # convert to png
	dbg "convert transparentfile => png"
	gdal_translate -co WORLDFILE=YES -of PNG "$transparentfile"  "$tfile"
fi

# be sure that "transparent" is transparent
dbg "transparent check"
convert   "$tfile" -transparent white "$tfile.trans.png"

cp -f "$tfile.trans.png" "$tfile"
rm -f "$tfile.trans.png" 2>/dev/null # tmp png

# now we have base and transparent png
# next fix the size - have to be same
read bwidth bheight <<<$(identify -format "%w %h" "$bfile")
read twidth theight <<<$(identify -format "%w %h" "$tfile")

if ((bwidth<twidth)) ; then
	dbg "resize $tfile $theight x $twidth => $bheight x $bwidth"
	convert  $tfile -resize "${bwidth}x${bheight}" "$tfile.tmp.png"
	cp -f "$tfile.tmp.png" "$tfile"
	rm -f "$tfile.tmp.png" 2>/dev/null
fi
if ((bwidth>twidth)) ; then
	dbg "resize $bfile $bheight x $bwidth => $theight x $twidth"
	convert  $bfile -resize "${twidth}x${theight}" "$bfile.tmp.png"
	cp -f "$bfile.tmp.png" "$bfile"
	rm -f "$bfile.tmp.png" 2>/dev/null
fi

dbg $bfile $(identify -format "%w %h" "$bfile")
dbg $tfile $(identify -format "%w %h" "$tfile")

dbg composite "$bfile" "$tfile" -compose Overlay "$outfile"
composite "$bfile" "$tfile" -compose Overlay "$outfile"

((DEBUG<1)) && rm -f "${TEMP}*"

status "done, $outfile"

