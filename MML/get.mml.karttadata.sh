#!/usr/local/bin/awsh
# get.mml.karttadata.sh
# ver 2025-10-02 a
# get.mml.karttadata.sh -l lahdedata/pk.txt -o kartat -v 1  -d 1 # only verbose, not wget
# get.mml.karttadata.sh -l lahdedata/pk.txt -o kartat  # get data to the dir kiintkartat using list pk.txt
# pk.txt has map area codes like P51 M44 , one/line

BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0



#######################################################
mitka=""
odir=maastokartat
verbose=0
DEBUG=0
tilename=""

while [ $# -gt 1 ]
do
	arg="$1"
	case "$arg" in
		-l) mitka="$2" ; shift ;;
		-o) odir="$2" ; shift ;;
		-v) verbose=$2 ; shift ;;
		-t) tilename=$2 ; shift ;;
		-d) DEBUG="$2" ; shift ;;
	esac
	shift
done

[ "$mitka" = "" ] && echo "usage:$PRG -l inputlist.txt -o ouputdir" >&2 && exit 1

karttalista="$AWMML/xmldata/maastotietokannat.all.txt"
MT=0
summa=0
echo "$karttalista"
lf="$mitka.log"
mkdir -p "$odir"
((verbose < 1 )) && date > "$lf"
while read alue
do
	echo "alue:$alue $date"
	# joko jokin alue tai yksittainen shp tiedosto
	endtag="/"
	case "$alue" in
		*.shp) endtag="" 
			# remove .shp
			alue=${alue%%.shp*}
			;;
	esac
	
	if ((verbose>0 )) ; then
		read lkm<<<$(grep -c "/$alue$endtag" "$karttalista")
		((summa+=lkm))
		# karkea laskenta
		((koko=lkm*15))
		((MT+=koko))
		echo "$alue $lkm/$summa $koko/$MT"
		continue
	fi
	grep "/$alue$endtag" "$karttalista" | while read inf pvm filepath
	do
		((DEBUG>0)) && echo "file:$inf" >&2
		AREA=${inf%%.shp.zip*}	
		((DEBUG>0)) && echo "tilename:$AREA" >&2

		onjo="$odir/$inf"

		# if exist and size > 0
		[ -s "$onjo" ] && echo "oli jo $onjo" >&2 && continue
		echo "$(date) $AREA" >> "$lf"
		#$AWMML/get.mml.maastotietokanta.sh -o "$odir" "$AREA"
		((DEBUG>0)) && echo $AWMML/get.mml.maastotietokanta.sh -d $DEBUG -p 0 -g 0 -t 0 -o "$odir" "$AREA" >&2
		$AWMML/get.mml.maastotietokanta.sh -d $DEBUG -p 0 -g 0 -t 0 -o "$odir" "$AREA"
		stat=$?
		((stat > 0 )) && rm -f "$odir/$inf" 2>/dev/null
	done
done < "$mitka"



