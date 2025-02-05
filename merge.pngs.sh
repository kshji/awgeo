#!/usr/bin/env bash
# ksh or bash or ...
# merge.pngs.sh
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# look $AWGEO/merge.png.transparent.sh
# - it merge two files and 1st is base and 2nd is transparent
# This merges n png files, and also make transparent, if needed
#
# $AWGEO/merge.pngs.sh -t -o outputfilename inputpngfiles
# all png have to be same size, merge.png.transparent.sh can do resizing
#
VER="2025-02-05.a"
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
usage:$PRG -t -o outputfilename [ -d 0|1 ] inputpngfiles
	-t # set transparent, default is no
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
notlast()
{
        Xstr="$1"
        Xdelim="\\$2"
        echo "${Xstr%${Xdelim}*}"
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
transparent=0


# parse cmdline options
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-t) transparent=1 ;;
		-o) outfile="$2" ; shift ;;
		-d) DEBUG="$2"; shift  ;;
		-v) echo "$PRG Ver:$VER" >&2 ;;
		-h) usage ; exit 1 ;;
		-*) usage ; exit 1 ;;
		*) break ;;  # filenames
	esac
	shift
done

inputfiles="$*"
mkdir -p "$outputdir" 2>/dev/null

[ "$outfile" = "" ] && usage && exit 2
[ $# -lt 1 ] && usage && exit 3  # need files

file1="$1"
btype=$(getfileend "$file1")
otype=$(getfileend "$outfile")

[ "$btype" != "png" ] && usage "inputfile type have to be .png" && exit 3
[ "$otype" != "png" ] && usage "outputfile type have to be .png" && exit 4
[ ! -f "$file1" ] && err "no file:$file1" && exit 5

# look 1st image size
read bwidth bheight <<<$(identify -format "%w %h" "$file1")
dbg "file $file1 size: $bwidth x $bheight"

# create white base file
WHITEBASE=$TEMP.white.png
TEMPOUT1=$TEMP.out.1.png
TEMPOUT2=$TEMP.out.2.png

filebegin=$(notlast "$file1" ".")
outbegin=$(notlast "$outfile" ".")
pgwfile="$filebegin.pgw"
outpgwfile="$outbegin.pgw"

dbg "filebegin:$filebegin outbegin:$outbegin pgwfile:$pgwfile outpgwfile:$outpgwfile"

convert -size "${bwidth}x${bheight}" canvas:white "$WHITEBASE"
cp -f "$WHITEBASE" "$TEMPOUT1" 2>/dev/null


#-transparent-color color

for inf in $@
do
	dbg "$inf"
	#
	rm -f "$TEMPOUT2" 2>/dev/null
	read width height <<<$(identify -format "%w %h" "$inf")
	dbg "file $inf size: $width x $height"
	(( width != bwidth )) && err "file dimension (width) have to be same" && exit 6
	(( height != bheight )) && err "file dimension (height) have to be same" && exit 6
	# merge  
	convert "$TEMPOUT1" "$inf" -layers merge  "$TEMPOUT2"
	[ ! -f "$TEMPOUT2" ] && err "error to make $TEMPOUT2 using $inf" && exit 7

	cp -f "$TEMPOUT2" "$TEMPOUT1" 2>/dev/null
done

cp -f "$TEMPOUT2"  "$outfile" 2>/dev/null
(( transparent>1 )) && rm -f "$outfile" 2>/dev/null && convert "$TEMPOUT2" -transparent white "$outfile"
((DEBUG<1 )) && rm -f "$WHITEBASE" "$TEMPOUT1" "$TEMPOUT2" 2>/dev/null

[ -f "$pgwfile" ] && cp -f "$pgwfile" "$outpgwfile" 2>/dev/null 

status "done, $outfile"

