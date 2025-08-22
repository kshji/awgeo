#!/usr/local/bin/awsh
# get.mml.orto.sh

BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


########################################################
usage()
{
        cat <<EOF >&2
usage:$PRG [ -o outdir ] [ -d 0|1 ] tilename [ tilename ... ]
        -o outdir # default is $outputdir/tilename
        -d 0|1    # debug, default 0
        tilenames  # list of tiles ex. P5114A P5114B
EOF

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


########################################################
get_orto()
{
        Xarea="$1"
        # could be more than one, select newest (sort)
        mastertile=${Xarea:0:5}
        subarea=${Xarea:0:3}
        last=${Xarea:5:1}
        # def L
        parts="$last"  # only one needed, not all 4 (A-H)
        [ "$last" = "L" ] && parts="A B C D"
        [ "$last" = "R" ] && parts="E F G H"
        dbg "parts:$parts outdir:$outdir"


        for part in $parts
        do
                file="$mastertile$part"
        	dbg grep "^$file.jp2" $AWMML/xmldata/ortokuvat.all.txt
		# could be more than one, select newest (sort)
        	read name url x <<<$(grep "^$file.jp2" $AWMML/xmldata/ortokuvat.all.txt | sort  -t "/" -nrk 5,5  )
        	dbg "name:$name url:$url"
        	dbg wget --no-check-certificate -O $outdir/$file.jp2 $apihost$url?api_key=$apikey
        	((DEBUG<2)) && wget --no-check-certificate -O "$outdir/$file.jp2" "$apihost$url?api_key=$apikey"
        	[ ! -f "$outdir/$file.jp2" ] && continue
        	# - convert jp2 to the jpg
        	((DEBUG<2)) && gdal_translate -co WORLDFILE=YES -of JPEG "$outdir/$file.jp2" "$outdir/$file.orto.jpg"
        	[ -f "$outdir/$file.orto.jpg" ] && rm -f "$outdir/$file.jp2" 2>/dev/null
        	((DEBUG<2)) && mv -f "$outdir/$file.orto.wld" "$outdir/$file.orto.jgw" 2>/dev/null
        	((DEBUG<2)) && rm -f "$outdir/$file.orto.jpg.aux.xml" 2>/dev/null
	
        	dbg "done $outdir/$file.orto.jpg and $outdir/$file.orto.jwg"
        done
}



######################################################################################
# MAIN
######################################################################################
url=""
outputdir="sourcedata"

[ "$AWGEO" = "" ] && err "AWGEO env not set" && exit 1
[ "$AWMML" = "" ] && err "AWMML env not set" && exit 1

# where is your apikey.mm.txt ?
apikeyfile="apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$BINDIR/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWGEO/config/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWMML/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && err "no apikeyfile: apikey.mml.txt dir: . or $BINDIR or $AWGEO/config or $AWMML" && exit 2
. $apikeyfile

[ "$apikey" = "" ] && err "no apikey?" && exit 2
[ "$apihost" = "" ] && err "no apihost?" && exit 3

while [ $# -gt 0 ]
do
        arg="$1"
        case "$arg" in
                -d) DEBUG="$2" ; shift ;;
                -o) outputdir="$2" ; shift ;;
                -*) usage; exit 4 ;;
                *) break ;;
        esac
        shift
done

# files 1-n
[ $# -lt 1 ] && usage && exit 5

mkdir -p "$outputdir"

# you order one orto A,B, ....H or all 4 in area L/R
for orto in $*
do
	len=${#orto}
	((len=len-1)) # last
	last=${orto:${len}:1}
	masterarea=${orto:0:$len}
	box="$masterarea$last"
	case "$last" in
		L) box=$orto ;;
		R) box=$orto ;;
		A|B|C|D) box="${masterarea}L" ;;
		E|F|G|H) box="${masterarea}R" ;;
	esac
        outdir="$outputdir/$box"
        mkdir -p "$outdir"
        dbg "get_orto $orto to dir $outdir"
        get_orto "$orto"
done

dbg "done:$outdir"

#https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilauslataus/tuotteet/orto/ortokuvat?api_key=$apikey

