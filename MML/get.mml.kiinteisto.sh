#!/usr/local/bin/awsh
# get.mml.kiinteisto.sh
# $AWMML/get.mml.kiinteisto.sh -o sourcedata N5313R
# - osaa hakea 4 tiedostoa L (ABCD) /R (EFGH) perusteella
# -g 0|1 = default 1 = do gpkg files
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
get_kiinteisto()
{
	Xarea="$1"
        # could be more than one, select newest (sort)
        mastertile=${Xarea:0:5}
        subarea=${Xarea:0:3}
        last=${Xarea:5:1}
	# def L
	parts="A B C D"
	[ "$last" = "R" ] && parts="E F G H"
	dbg "parts:$parts"

	rm -rf "$TEMP" 2>/dev/null
	mkdir -p "$TEMP"

	for part in $parts
	do
		file="$mastertile$part"
        	url="/tuotteet/kiinteistorekisterikartta/avoin/karttalehdittain/tm35fin/shp/$subarea/$file.zip"
		outfile="$Xarea.kiint.$file.shp.zip"
        	dbg "mastertile:$mastertile file:$file $outfile url:$url"
        	dbg wget --no-check-certificate -O "$TEMP"/$outfile "$apihost$url?api_key=$apikey"
        	wget --no-check-certificate -O "$TEMP"/$outfile "$apihost$url?api_key=$apikey"
		unzip -ojq -d "$TEMP" "$TEMP/$outfile"
        	[ ! -f "$TEMP/$outfile" ] && exit 8
		((DEBUG<1)) && rm -f "$TEMP/$outfile" 2>/dev/null

	done

	# merge 4 files to one file
        XNOW="$PWD"
        cd "$TEMP"

	if ((gpkg == 1 )) ; then
		destfile="$Xarea.kiinteistoraja.gpkg"
		# merge shp to the gpkg file
		# vain kiinteistorajat kiinnostavat
		for f in *_kiinteistoraja.shp
		do
			if [ ! -f "$destfile" ] ; then
				ogr2ogr -f 'GPKG' -nln kiinteistoraja "$destfile" "$f" 
			else
				ogr2ogr -f 'GPKG' -append -nln kiinteistoraja "$destfile" "$f" 
			fi
		done
		#ogrinfo  $Xarea.kiinteistoraja.shp -sql "ALTER TABLE $Xarea.kiinteistoraja ADD COLUMN symbol integer(6)"
		ogrinfo "$destfile" -sql "ALTER TABLE kiinteistoraja ADD COLUMN symbol text"
		ogrinfo  "$destfile" -dialect SQLite -sql "
          		UPDATE  kiinteistoraja
          		SET symbol=cast(97000+LAJI AS text)
        		"
	else # no gpkg
		destfile="$Xarea.kiinteistot.shp"
		for f in *_*.shp
		do
			if [ ! -f "$destfile" ] ; then
				ogr2ogr -f 'ESRI Shapefile' -nln kiinteistot "$destfile" "$f" 
			else
				ogr2ogr -f 'ESRI Shapefile' -append -nln kiinteistot "$destfile" "$f" 
			fi
		done
	fi
	#zip "$destfile".zip "$destfile"
	cd $XNOW
	#cp -f "$TEMP"/"$destfile".zip "$outdir" 2>/dev/null
	dbg cp -f "$TEMP"/"$destfile" "$outdir" 
	mkdir -p "$outdir" 2>/dev/null
	cp -f "$TEMP"/"$destfile" "$outdir" 2>/dev/null
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

# files 1-n
[ $# -lt 1 ] && usage && exit 5

id=$$ # process number = unique id for tempfiles
TEMP="$PWD/tmp/$id"

mkdir -p "$outputdir" "$TEMP"

for kiint in $*
do
	outdir="$outputdir/$kiint"
	mkdir -p "$outputdir"
	dbg "get_kiinteisto $kiint"
	get_kiinteisto "$kiint"
done

dbg "done:$outputdir"

#https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilauslataus/tuotteet/kiinteistorekisterikartta/avoin/karttalehdittain/tm35fin/shp/N54/N5424A.zip?api_key=$apikey

