#!/usr/local/bin/awsh
#get.mml.data.sh

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

host="https://tiedostopalvelu.maanmittauslaitos.fi"

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
palvelut="kaikki_palvelut kuntajako yhdista_kuntajako maastotietokantalista laserlista ortokuvalista yhdista_maastotietokanta yhdista_laser yhdista_ortokuva"
#palvelut="laserlista"
#palvelut="yhdista_maastotietokanta"
#palvelut="yhdista_laser"
#palvelut="ortokuvalista"
#palvelut="yhdista_ortokuva"
#palvelut="maastotietokantalista yhdista_maastotietokanta"
palvelut="kuntajako yhdista_kuntajako"

for p in $palvelut
do
	
	echo "$p"
	$p
done
