#!/usr/local/bin/awsh
# get.mml.karttadata.sh
# get.mml.karttadata.sh -l lahdedata/pk.txt -o kartat -v 1  # only verbose, not wget
# get.mml.karttadata.sh -l lahdedata/pk.txt -o kartat  # get data to the dir kiintkartat using list pk.txt
# pk.txt has map area codes like P51 M44 , one/line

BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0



#######################################################
mitka=""
odir=kiinkartat
verbose=0

while [ $# -gt 1 ]
do
	arg="$1"
	case "$arg" in
		-l) mitka="$2" ; shift ;;
		-o) odir="$2" ; shift ;;
		-v) verbose=$2 ; shift ;;
	esac
	shift
done

[ "$mitka" = "" ] && echo "usage:$PRG -l inputlist.txt -o ouputdir" >&2 && exit 1

karttalista="$AWMML/xmldata/maastotietokannat.all.txt"
MT=0
summa=0
echo "$karttalista"
lf="$mitka.log"
((verbose < 1 )) && date > "$lf"
while read alue
do
	echo "alue:$alue $date"
	if ((verbose>0 )) ; then
		read lkm<<<$(grep -c "/$alue/" "$karttalista")
		((summa+=lkm))
		# karkea laskenta
		((koko=lkm*35))
		((MT+=koko))
		echo "$alue $lkm/$summa $koko/$MT"
		continue
	fi
	grep "/$alue/" "$karttalista" | while read inf pvm filepath
	do
		AREA=${inf%%.zip*}	
		echo "$AREA"
		echo "area:$AREA" >&2

		onjo="$odir/${AREA}_kiinteistoraja.shp"
		[ -f "$onjo" ] && echo "oli jo $onjo" >&2 && continue
		echo "$(date) $AREA" >> "$lf"
		$AWMML/get.mml.kiinteistokartta.sh -o "$odir" "$AREA"
	done
done < "$mitka"



