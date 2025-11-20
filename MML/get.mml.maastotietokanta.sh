#!/usr/local/bin/awsh
# get.mml.maastotietokanta.sh
# ver 2025-10-02 a
#
# get.mml.maastotietokanta.sh N5424L N5424R
#	output to dir sourcedata/tile
#	- also done png
#	- also convert to the gpkg version = faster to use
# get.mml.maastotietokanta.sh -d 1 -p 0 N5424L N5424R
# get.mml.maastotietokanta.sh -d 1 -p 0 -g 0 -t 0 -o outdir N5424L  N5424R
# get.mml.maastotietokanta.sh -d 1 -p 0 -g 0 -t 0 -o outdir --mapname somename N5424L  N5424R
#
#
: '/*
Teema -1. kirjain

h = Hallintorajat
Kunnanrajat, aluehallintorajat, suojelualueiden rajat.
k = Korkeussuhteet
Korkeuskäyrät, korkeuspisteet, jyrkänteet.
l = Liikenneverkko
Tiet, rautatiet, ajopolut, lautat.
m = Maanpeite
Pellot, suot, metsäalueet, kallioalueet, niityt, puistot.
n = Nimistö
Karttanimet (kylät, järvet, tiet, talot).
r = Rakennukset ja rakennelmat
Asuinrakennukset, julkiset rakennukset, lomamökit, altaat, mastot.
v = Vesistöt
Järvet, joet, ojat, rantaviivat, kosket.
j = Johtoverkko (Joskus erillisenä, joskus osa liikennettä)
Sähkölinjat, muuntajat, kaasuputket.

_p = Polygon (Alue)
_v = Viiva (Line/Arc) – Huom: usein 'v', ei 'vector'
_s = Symboli/Piste (Point)
_t = Teksti (Text) – Nämä ovat usein pistemäisiä kohteita, joissa on tekstin sijoittelu- ja kääntökulmatiedot.

ogrinfo -al m_L4133R_p.shp -sql "SELECT DISTINCT LUOKKA FROM m_L4133R_p"
*/'
#
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
usage:$PRG [ -o outdir ] [ -p 0|1 ] [ -d 0|1 ] tilename [ tilename ... ]
	-o outdir # default is $outdir/tilename
	-p 0|1    # get also area png, default 1
	-g 0|1    # build gpkg version, default 1
	-t 0|1    # 0 = outdir/tilename 1 = outdir
	--mapname mapnamelabel # default nothing
	-d 0|1    # debug, default 0
	tilenames  # list of tiles ex. P5114L P5114R
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
        # dont remove - it's already dir
        [ -d "$str" ] && print -- "$str" && return
        echo "${str%/*}"
}

################################################################
getfile()
{
        str="$*"
        echo "${str##*/}"
}

################################################################
getbase()
{
        str="$1"
        remove="$2"
        echo "${str%$remove}"
}

#########################################################################
update_some_symbols_v()
{
        Xdb="$1"
        Xfile="$2"
        #update_some_symbols_v "merge_$t.shp"
        :
        # rantaviiva
        ogrinfo  "$Xfile"   $quit -dialect SQLite -sql "
          UPDATE  $Xdb
          SET symbol=42300
          WHERE kartoglk=36200
        "
        # kuvioraja
        ogrinfo  "$Xfile"   $quit -dialect SQLite -sql "
          UPDATE  $Xdb
          SET symbol=30212
          WHERE kartoglk=39110
        "
        # ei nayteta kumpaakaan kuviorajaa tiettyjen alueiden reunalla (suo yms)
        ogrinfo  "$Xfile"   $quit -dialect SQLite -sql "
          UPDATE  $Xdb
          SET symbol=0
          WHERE symbol IN (30211,30212) AND kartoglk IN (32111,32112,32500,32900,34100,34300,34700,35300,35400,35411,35412,35421,35422,38300,38600,38700)        "
}


########################################################
shp2gpkg()
{
 	#shp2gpkg "$area" "$outdir/$area.shp.zip"  "$outdir"
	#for t in v p s #t
	Xarea="$1"
	Xshp="$2"
	Xoutdir="$3"
	unzip -oqj "$Xshp" -d "$TEMP"
	XXnow=$PWD
	cd $TEMP
	resultfile=""
	for shp in ?_${Xarea}_?.shp
	do
		label="${shp%.*}"
		first=${label%_*}
		chr1=${label:0:1}
		chrN=${label##*_}
		label="${label#*_}"  # 1st *_ remove
		label="${label%_*}"  # last _* remove
		db=$chrN
		resultfile=$Xarea.$chrN.gpkg
		dbg "db:$db Xarea:$Xarea label:$label label3:$label3 shp:$shp"
		if [ ! -f "$resultfile"  ] ; then # create
        		dbg ogr2ogr -f "GPKG" "$resultfile" $EPSG  "$shp" -nln "$db" 
        		ogr2ogr -f "GPKG" "$resultfile" $EPSG  "$shp" $quit -nln "$db" 2>/dev/null
		else # append
        		dbg ogr2ogr -f "GPKG" "$resultfile" $EPSG  -append -update "$shp" -nln "$db" 
        		ogr2ogr -f "GPKG" "$resultfile" $EPSG  $quit -append -update "$shp" -nln "$db" 2>/dev/null
		fi
	done 

	# init table changes
	appendstr=" "
	resultfile=$Xarea.full.gpkg
	for destfile in $Xarea.*.gpkg
	do
		
		str=$(getbase "$destfile" ".gpkg")
		tablename=${str##*.}
		ogrinfo "$destfile" $quit -sql "ALTER TABLE $tablename ADD COLUMN symbol integer"
		ogrinfo "$destfile" $quit -sql "ALTER TABLE $tablename ADD COLUMN angle character(254)"

		ogrinfo  "$destfile" $quit -dialect SQLite -sql "
                	UPDATE  $tablename
                	SET symbol=luokka
                	"
		# update angle
		ogrinfo  "$destfile"   $quit -dialect SQLite -sql "
          		UPDATE  $tablename
                		SET angle=CAST(SUUNTA*1.0/10000.0/3.14159*180.0  AS  character(254) )
          		WHERE SUUNTA IS NOT NULL
        		"


		[ "$tablename" = "v" ] && update_some_symbols_v "$tablename" "$destfile"

		
		ogr2ogr -f "GPKG" "$resultfile" $EPSG  $quit $appendstr "$destfile" -nln "$tablename" 2>/dev/null
		appendstr=" -append -update "
	
	done

	#
	cd $XXnow
	for gpkg in "$TEMP"/$Xarea.*.gpkg
	do
		dbg "resultfile:$gpkg"
		Xfname=$(getfile "$gpkg")
		[ -f "$gpkg" ] && cp -f "$gpkg" "$Xoutdir" && dbg "done:$Xoutdir/$Xfname"
	done

	(( DEBUG<1)) && rm -rf "$TEMP"
}


######################################################################################
# MAIN
######################################################################################
url=""
outputdir="sourcedata"
png=1
do_shp2gpkg=1
tiledir=1
quit=" -q "
mapname=""

[ "$AWGEO" = "" ] && err "AWGEO env not set" && exit 1
[ "$AWMML" = "" ] && err "AWMML env not set" && exit 1

# where is your apikey.mm.txt ?
apikeyfile="apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$BINDIR/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWGEO/config/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWMML/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && err "no apikeyfile: apikey.mml.txt dir: . or $BINDIR or $AWGEO/config or $AWMML" && exit 2
. $apikeyfile

EPSG=""
[ -f "$AWMML/epsg.cfg" ] && . "$AWMML"/epsg.cfg 


[ "$apikey" = "" ] && err "no apikey?" && exit 2
[ "$apihost" = "" ] && err "no apihost?" && exit 3

while [ $# -gt 0 ] 
do
	arg="$1"
	case "$arg" in
		-d) DEBUG="$2" ; shift ;;
		-o) outputdir="$2" ; shift ;;
		-e) EPSG="$2" ; shift ;;
		-p) png="$2" ; shift ;;
		-g) do_shp2gpkg="$2" ; shift ;;
		-t) tiledir="$2" ; shift ;;
		-m|--mapname) mapname="$2" ; shift ;;
		-*) usage; exit 4 ;;
		*) break ;;
	esac
	shift
done

# files 1-n
[ $# -lt 1 ] && usage && exit 5

mkdir -p "$outputdir"
TEMP="tmp/$id"
mkdir -p "$TEMP"

((DEBUG>0)) && quit=" "

for area in $*
do
	[ "$area" = "" ] && continue
	outdir="$outputdir"
	((tiledir>0)) && outdir="$outputdir/$area"
	rm -rf "$TEMP"
	mkdir -p "$TEMP" "$outdir"
	read name url x <<<$(grep "^$area.shp.zip" $AWMML/xmldata/maastotietokannat.all.txt  )
	dbg "name:$name url:$url"
	dbg wget $quit --no-check-certificate -O "$outdir/$area.shp.zip" "$apihost$url?api_key=$apikey" 
	#echo wget --no-check-certificate -O "$outdir/$area.shp.zip" "$apihost$url?api_key=$apikey"  > tmp.$area.wget
	wget $quit --no-check-certificate -O "$outdir/$area.shp.zip" "$apihost$url?api_key=$apikey" 
	dbg "done $outdir/$area.shp.zip"

	[ ! -f "$outdir/$area.shp.zip" ] && continue

	if (( png > 0 )) ; then
		# get also png, edit url
		xurl=${url//\//|}
		#vanha"xpngurl="${xurl/maastotietokanta|kaikki/peruskarttarasteri_jhs180|painovari|1m}"
		xpngurl="${xurl/maastotietokanta|avoin/peruskarttarasteri_jhs180|painovari|1m}"
		xpngurl=${xpngurl/|shp|/|png|}
		xpngurl=${xpngurl/.shp.zip/.png}
		xpgwurl=${xpngurl/.png/.pgw}
		pngurl=${xpngurl//|//}
		pgwurl=${xpgwurl//|//}
		dbg "png:$pngurl"
		dbg "pwf:$pgwurl"
		dbg wget $quit --no-check-certificate -O "$outdir/$area.png" "$apihost$pngurl?api_key=$apikey" 
		wget $quit --no-check-certificate -O "$outdir/$area.png" "$apihost$pngurl?api_key=$apikey" 
		dbg wget $quit --no-check-certificate -O "$outdir/$area.pgw" "$apihost$pgwurl?api_key=$apikey" 
		wget $quit --no-check-certificate -O "$outdir/$area.pgw" "$apihost$pgwurl?api_key=$apikey" 
	fi

	(( do_shp2gpkg < 1 )) && continue
	dbg shp2gpkg "$area" "$outdir/$area.shp.zip"  "$outdir"
	shp2gpkg "$area" "$outdir/$area.shp.zip"  "$outdir" 


done

dbg "done:$outdir"

#https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilauslataus/tuotteet/peruskarttarasteri_jhs180/painovari/1m/etrs89/png/$osa1/$osa2/$alue.png?$tokenvar=$token"
#https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilauslataus/tuotteet/maastotietokanta/kaikki/etrs89/shp/P5/P53/P5313L.shp.zip?api_key=$token
