#!/usr/local/bin/awsh
# get.mml.kunta.sh
# $AWMML/get.mml.kunta.sh -o sourcedata 
#

BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


########################################################
usage()
{
        cat <<EOF >&2
usage:$PRG [ -o outdir ] [ -d 0|1 ] tilename [ tilename ... ]
        -o outdir # default is $outdir/tilename
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
get_kunta()
{
	Xarea=kunta
	rm -rf "$TEMP" 2>/dev/null
	mkdir -p "$TEMP"
        url="/tuotteet/kuntajako/kuntajako_10k/etrs89/gpkg/TietoaKuntajaosta_2025_10k.zip"
	outfile="kuntajako.2025.zip"
        dbg wget --no-check-certificate -O "$TEMP"/$outfile "$apihost$url?api_key=$apikey"
        wget --no-check-certificate -O "$TEMP"/$outfile "$apihost$url?api_key=$apikey"
	unzip -ojq -d "$TEMP" "$TEMP/$outfile"
        XNOW="$PWD"
        cd "$TEMP"
	cd $XNOW
	#cp -f "$TEMP"/"$destfile".zip "$outdir" 2>/dev/null
	###dbg cp -f "$TEMP"/"$destfile" "$outdir" 
	mkdir -p "$outdir" 2>/dev/null
	###cp -f "$TEMP"/"$outfile" "$outdir" 2>/dev/null
	###((DEBUG<1)) && [ -d "$TEMP" ] && rm -rf "$TEMP"

	NOW=$PWD
	cd $TEMP
	for f in *.gpkg
	do
		mkdir -p "$outdir" 2>/dev/null
		cp -f "$f" "$outdir" 2>/dev/null
	done
	((DEBUG<1)) && [ -d "$TEMP" ] && rm -rf "$TEMP"


}
######################################################################################
# MAIN
######################################################################################
url=""
outputdir="sourcedata"
gpkg=1

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
		-g) gpkg="$2" ; shift ;;
                -*) usage; exit 4 ;;
                *) break ;;
        esac
        shift
done

id=$$ # process number = unique id for tempfiles
TEMP="$PWD/tmp/$id"

mkdir -p "$outputdir" "$TEMP"

outdir="$outputdir/kunta"
mkdir -p "$outdir"
dbg "get_kunta "
get_kunta 

dbg "done:$outdir"


