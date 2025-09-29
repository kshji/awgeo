#!/usr/local/bin/awsh
#get.mml.data.sh

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

host="https://tiedostopalvelu.maanmittauslaitos.fi"
host2="https://avoin-paikkatieto.maanmittauslaitos.fi"

#########################################################################
laserlista()
{
        filename="xmldata/laser"
        cp -f "$xmlfile" backup 2>/dev/null
        rm -f "$xmlfile" 2>/dev/null
        url="/tp/feed/mtp/laser/automaattinen?api_key=$apikey"
        kierros=0
        jatka=1
        next=""
        while ((jatka>0))
        do
                wget -O "$filename.$kierros.xml" "$host/$url$next"
                gawk -f lib/get.2.example.awk "$filename.$kierros.xml" > $filename.$kierros.dat
                jatkumo=$(grep "ATTR|link|/feed/link|href|" $filename.$kierros.dat 2>/dev/null)
                [ "$jatkumo" = "" ] && jatka=0 && continue
                next=$(echo "$jatkumo" | awk -F '&' '{ print "&" $2 "&" $3 }')
                echo "seuraava $next"
                ((kierros+=1))
        done

}

#########################################################################
yhdista_laser()
{
	filename="xmldata/laser"
	all="xmldata/laser.all.txt"
	# laser.0.dat:DAT|id|/feed/entry/id||urn:path:/tuotteet/laser/automaattinen/2024/20240207_Swissphoto_Vierema_kesa/Harvennettu/Q5121D4.laz
	grep "DAT|id|/feed/entry/id||.*\.laz" $filename.*.dat | \
	awk -F '|' '
		$3 == "/feed/entry/id" { 
					url=$5
					gsub(/^urn:path:/,"",url)
					lkm=split(url,kentat,"/")
					tiedosto=kentat[lkm]
		 			print tiedosto,url 
					}
	' > $all
}

#########################################################################
yhdista_maastotietokanta()
{
	filename="xmldata/maastotietokannat"
	all="xmldata/maastotietokannat.all.txt"
	# laser.0.dat:DAT|id|/feed/entry/id||urn:path:/tuotteet/laser/automaattinen/2024/20240207_Swissphoto_Vierema_kesa/Harvennettu/Q5121D4.laz
	# maastotietokannat.9.dat:DAT|id|/feed/entry/id||urn:path:/tuotteet/maastotietokanta/kaikki/etrs89/shp/Q3/Q34/Q3413R.shp.zip
	grep "DAT|id|/feed/entry/id||.*\.shp.zip" $filename.*.dat | \
	awk -F '|' '
		$3 == "/feed/entry/id" { 
					url=$5
					gsub(/^urn:path:/,"",url)
					lkm=split(url,kentat,"/")
					tiedosto=kentat[lkm]
		 			print tiedosto,url 
					}
	' > $all
}

#########################################################################
Xyhdista_maastotietokanta()
{
	filename="xmldata/maastotietokannat"
	all="xmldata/maastotietokannat.all.txt"
	# maastotietokannat.9.dat:DAT|id|/feed/entry/id||urn:path:/tuotteet/maastotietokanta/kaikki/etrs89/shp/Q3/Q34/Q3413R.shp.zip
	grep "DAT|id|/feed/entry/id||.*shp.zip" $filename.*.dat | \
	awk -F '/' '
		NF > 2 { shapefile=$NF
		 	print shapefile
			}
	' > $all
}

#########################################################################
yhdista_ortokuva()
{
	filename="xmldata/ortokuvat"
	all="xmldata/ortokuvat.all.txt"
	# DAT|id|/feed/entry/id||urn:path:/tuotteet/orto/etrs-tm35fin/smk_v_15000_50/2024/S43/02m/1/S4322B.jp2
	grep "DAT|id|/feed/entry/id||.*\.jp2" $filename.*.dat | \
	awk -F '|' '
		$3 == "/feed/entry/id" { 
					url=$5
					gsub(/^urn:path:/,"",url)
					lkm=split(url,kentat,"/")
					tiedosto=kentat[lkm]
		 			print tiedosto,url 
					}
	' > $all
}


#########################################################################
ortokuvalista()
{
	filename="xmldata/ortokuvat"
	cp -f "$xmlfile" backup 2>/dev/null
	rm -f "$xmlfile" 2>/dev/null
	url="/tp/feed/mtp/orto/ortokuva?api_key=$apikey"
	kierros=0
	jatka=1
	next=""
	while ((jatka>0))
	do
		wget -O "$filename.$kierros.xml" "$host/$url$next"
		gawk -f lib/get.2.example.awk "$filename.$kierros.xml" > $filename.$kierros.dat
		jatkumo=$(grep "ATTR|link|/feed/link|href|" $filename.$kierros.dat 2>/dev/null)
		[ "$jatkumo" = "" ] && jatka=0 && continue
		next=$(echo "$jatkumo" | awk -F '&' '{ print "&" $2 "&" $3 }')
		echo "seuraava $next"
		((kierros+=1))
	done

}




#########################################################################
maastotietokantalista()
{
	filename="xmldata/maastotietokannat"
	jatka=1
	cp -f "$xmlfile" backup 2>/dev/null
	rm -f "$xmlfile" 2>/dev/null
# uusi 2025.05 https://tiedostopalvelu.maanmittauslaitos.fi/tp/feed/mtp/maastotietokanta/avoin
# vanha https://tiedostopalvelu.maanmittauslaitos.fi/tp/feed/mtp/maastotietokanta/kaikki
	#url="/tp/feed/mtp/maastotietokanta/kaikki?api_key=$apikey"
	# 2025 05 muuttunut
	url="/tp/feed/mtp/maastotietokanta/avoin?api_key=$apikey"
	kierros=0
	atka=1
	next=""
	while ((jatka>0))
	do
		wget -O "$filename.$kierros.xml" "$host/$url$next"
		gawk -f lib/get.2.example.awk "$filename.$kierros.xml" > $filename.$kierros.dat
		jatkumo=$(grep "ATTR|link|/feed/link|href|" $filename.$kierros.dat 2>/dev/null)
		[ "$jatkumo" = "" ] && jatka=0 && continue
		next=$(echo "$jatkumo" | awk -F '&' '{ print "&" $2 "&" $3 }')
		echo "seuraava $next"
		((kierros+=1))
	done

}

#########################################################################
yhdista_kuntajako()
{
	filename="xmldata/kuntajako"
	all="xmldata/kuntajako.all.txt"
	# DAT|id|/feed/entry/id||urn:path:/tuotteet/orto/etrs-tm35fin/smk_v_15000_50/2024/S43/02m/1/S4322B.jp2
	grep "DAT|id|/feed/entry/id||.*\.zip" $filename.*.dat | \
	awk -F '|' '
		$3 == "/feed/entry/id" { 
					url=$5
					gsub(/^urn:path:/,"",url)
					lkm=split(url,kentat,"/")
					tiedosto=kentat[lkm]
		 			print tiedosto,url 
					}
	' > $all
}


#########################################################################
kuntajako()
{
	filename="xmldata/kuntajako"
	jatka=1
	cp -f "$xmlfile" backup 2>/dev/null
	rm -f "$xmlfile" 2>/dev/null
	# katso kaikki.txt tiedostosta mika on url
	url="/tp/feed/mtp/kuntajako/kuntajako_10k?api_key=$apikey"
	kierros=0
	atka=1
	next=""
	while ((jatka>0))
	do
		wget -O "$filename.$kierros.xml" "$host/$url$next"
		gawk -f lib/get.2.example.awk "$filename.$kierros.xml" > $filename.$kierros.dat
		jatkumo=$(grep "ATTR|link|/feed/link|href|" $filename.$kierros.dat 2>/dev/null)
		[ "$jatkumo" = "" ] && jatka=0 && continue
		next=$(echo "$jatkumo" | awk -F '&' '{ print "&" $2 "&" $3 }')
		echo "seuraava $next"
		((kierros+=1))
	done

}

#########################################################################
yhdista_kiinteistorekisterikartta()
{
        filename="xmldata/kiinteistorek/kiintrek"
        all="xmldata/xmldata/kiinteistorek/kiintrek.all.txt"
        # laser.0.dat:DAT|id|/feed/entry/id||urn:path:/tuotteet/laser/automaattinen/2024/20240207_Swissphoto_Vierema_kesa/Harvennettu/Q5121D4.laz
        # maastotietokannat.9.dat:DAT|id|/feed/entry/id||urn:path:/tuotteet/maastotietokanta/kaikki/etrs89/shp/Q3/Q34/Q3413R.shp.zip
        grep "DAT|id|/feed/entry/id||.*\.zip" $filename.*.dat | \
        awk -F '|' '
                $3 == "/feed/entry/id" {
                                        url=$5
                                        gsub(/^urn:path:/,"",url)
                                        lkm=split(url,kentat,"/")
                                        tiedosto=kentat[lkm]
                                        print tiedosto,url
                                        }
        ' > $all
}
	
#########################################################################
kiinteistorekisterikarttalista()
{
	mkdir -p xmldata/kiinteistorek 2>/dev/null
        filename="xmldata/kiinteistorek/kiintrek"
        jatka=1
        cp -f "$xmlfile" backup 2>/dev/null
        rm -f "$xmlfile" 2>/dev/null
#https://tiedostopalvelu.maanmittauslaitos.fi/tp/feed/mtp/kiinteistorekisterikartta/karttalehdittain?api_key=dnj8gjuj5ivci7tsb4r6m79qmo
        #url="/tp/feed/mtp/maastotietokanta/kaikki?api_key=$apikey"
        # 2025 05 muuttunut
        url="/tp/feed/mtp/kiinteistorekisterikartta/karttalehdittain?api_key=$apikey"
        kierros=0
        atka=1
        next=""
        while ((jatka>0))
        do
                wget -O "$filename.$kierros.xml" "$host/$url$next"
                gawk -f lib/get.2.example.awk "$filename.$kierros.xml" > $filename.$kierros.dat
                jatkumo=$(grep "ATTR|link|/feed/link|href|" $filename.$kierros.dat 2>/dev/null)
                [ "$jatkumo" = "" ] && jatka=0 && continue
                next=$(echo "$jatkumo" | awk -F '&' '{ print "&" $2 "&" $3 }')
                echo "seuraava $next"
                ((kierros+=1))
        done

}

#########################################################################
kiinteisto_avoin()
{
	dir=json/kiinteisto
	mkdir -p $dir
	jsonfile="$dir/kiinteisto.aineistot.json"
	echo wget -O "$jsonfile" "$host2/kiinteisto-avoin/simple-features/v3/collections?api_key=$apikey2"
	wget -O "$jsonfile" "$host2/kiinteisto-avoin/simple-features/v3/collections?api-key=$apikey2"
}

#########################################################################
kaikki_palvelut()
{
	xmlfile="xmldata/kaikki_palvelut.xml"
	datfile="xmldata/kaikki_palvelut.dat"
	txtfile="xmldata/kaikki_palvelut.txt"
	cp -f "$xmlfile" backup 2>/dev/null
	rm -f "$xmlfile" 2>/dev/null
	wget -O "$xmlfile" "$host/tp/feed/mtp/?api_key=$apikey"
	gawk -f lib/get.2.example.awk "$xmlfile" > "$datfile"
	awk  '
		BEGIN {
			FS="|"
			}
		/^ATTR\|link\|\/feed\/entry\/link\|href/ {
			print "linkki:",$5
			}
	' "$datfile" > "$txtfile"
	#grep "ATTR|link|/feed/link|href" "$datfile" > 	$txtfile
}
	





#######################################
# MAIN
#######################################

[ "$AWGEO" = "" ] && err "AWGEO env not set" && exit 1
[ "$AWMML" = "" ] && err "AWMML env not set" && exit 1

# where is your apikey.mm.txt ?
apikeyfile="apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$BINDIR/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWGEO/config/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWMML/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && err "no apikeyfile: apikey.mml.txt dir: . or $BINDIR or $AWGEO/config or $AWMML" && exit 2
. $apikeyfile

cd $AWMML

mkdir -p xmldata backup 
palvelutkaikki="kaikki_palvelut kuntajako yhdista_kuntajako maastotietokantalista laserlista ortokuvalista yhdista_maastotietokanta yhdista_laser yhdista_ortokuva"
palvelutkaikki+=" kiinteisto_avoin kiinteistorekisterikarttalista yhdista_kiinteistorekisterikartta"
#palvelut="laserlista"
#palvelut="yhdista_maastotietokanta"
#palvelut="yhdista_laser"
#palvelut="ortokuvalista"
#palvelut="yhdista_ortokuva"
#palvelut="maastotietokantalista yhdista_maastotietokanta"
#palvelut="kuntajako yhdista_kuntajako"
#palvelut="kiinteisto_avoin"
palvelut="kiinteistorekisterikarttalista"
palvelut=""
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		--all) palvelut="$palvelutkaikki"; break ;;
		--kaikki) palvelut="$palvelut kaikki_palvelut"; break ;;
		--laser) palvelut="$palvelut laserlista yhdistalaser"; break ;;
		--laseryhd) palvelut="$palvelut yhdistalaser"; break ;;
		--maasto) palvelut="$palvelut maastotietokantalista yhdista_maastotietokanta"; break ;;
		--maastoyhd) palvelut="$palvelut yhdista_maastotietokanta"; break ;;
		--orto) palvelut="$palvelut ortokuvalista yhdista_ortokuva"; break ;;
		--ortoyhd) palvelut="$palvelut yhdista_ortokuva"; break ;;
		--kuntajako) palvelut="$palvelut kuntajako yhdista_kuntajako"; break ;;
		--kuntajakoyhd) palvelut="$palvelut yhdista_kuntajako"; break ;;
		--kiinteisto) palvelut="$palvelut kiinteisto "; break ;;
		--kiinteistorek) palvelut="$palvelut kiinteistorekisterikarttalista yhdista_kiinteistorekisterikartta "; break ;;
		--kiinteistorekyhd) palvelut="$palvelut "; break ;;
	esac
	shift
done


echo "$palvelut"
echo "__________________________"
for p in $palvelut
do
	
	echo "$p"
	$p
done
