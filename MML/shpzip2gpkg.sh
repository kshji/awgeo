#!/usr/local/bin/awsh
# shpzip2gpkg.sh
# ver 2025-10-09 a
#
# shpzip2gpkg.sh -d 1 -t 0 -o somedir6 -a -10.6 N5424L.shp.zip  N5424?.zip
# shpzip2gpkg.sh -d 1 -o gpkg -t 0 xxx.shp.zip yyy.shp.zip
#   -t 0|1  tiledir or not  
#
# mml2ocad call like
# $AWGEODEV/shpzip2gpkg.sh -t 0 -o mmltst -a -10.6 -n N5424L --mapname koti sourcedata/N5424L/N5424*.*
#
# You can use ex. 
# $AWMML/get.mml.maastotietokanta.sh -d 1 -p 0 -g 0 -t 0 -o mml N5424L  N5424R
# to get MML shp files to dir mml
#
# To get "kiinteistodata" - Cadastral index map
# $AWMML/get.mml.kiinteistokartta.sh -u 0 -o mml N5424L N5424R
#
# To get "hakkuuilmoitukset" - Forest cutting notice 
# $AWMML/get.metsa.sh -y "2020" -o "mml" -t 0 N5424L    N5424R
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
usage:$PRG [ -o outdir ] [ -d 0|1 ] some1.shp.zip [ some.shp.zip ... ]
	-o outdir # default is $outdir/tilename
	-d 0|1    # debug, default 0
	list of shp.zip files
EOF

}

########################################################
msg()
{
	((DEBUG>0)) && return
        echo "$*" >&2
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
	Xdir="${str%/*}" 
	[ "$Xdir" = "$str" ] && Xdir="."
        echo "$Xdir"
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

################################################################
countour_symbols()
{
        Cinf="$1"
	Cdb="$2"

	dbg "countour_symbols $Cinf $Cdb"


        #ogrinfo $Cinf  $quit -sql "ALTER TABLE $Cdb ADD COLUMN SYMBOL INTEGER"
        ########################################################################
        ####-- contour begin
        # contour 20m , 5m, 2.5 m - use column KORARV
        # 0-level special case
        ogrinfo  $Cinf   $quit -dialect SQLite -sql " UPDATE  $Cdb SET symbol=0 WHERE luokka IN (52100, 54100) "
        # 20m
        ogrinfo  $Cinf $quit  -dialect SQLite -sql " UPDATE  $Cdb SET symbol=LUOKKA+1 WHERE  KORARV*10 % 200 = 0 AND luokka=52100 AND KORARV<>0 AND symbol=0 " 
        # 5m
        ogrinfo  $Cinf  $quit -dialect SQLite -sql " UPDATE  $Cdb SET symbol=LUOKKA+2 WHERE  KORARV*10 % 50 = 0 AND luokka=52100 AND  KORARV<>0 AND symbol=0 "
        # 2.5m
        ogrinfo  $Cinf $quit  -dialect SQLite -sql " UPDATE  $Cdb SET symbol=LUOKKA+3 WHERE  KORARV*10 % 25 = 0 AND luokka=52100 AND  KORARV<>0 AND symbol=0 "
	# rest set if there is
        ogrinfo  $Cinf $quit  -dialect SQLite -sql " UPDATE  $Cdb SET symbol=LUOKKA+4 WHERE  luokka=52100 AND symbol=0 "
        # water area - lakes ...
        # 1.5 m
        ogrinfo  $Cinf $quit  -dialect SQLite -sql " UPDATE  $Cdb SET symbol=LUOKKA+1 WHERE  KORARV*10 = 15 AND luokka=54100  AND symbol=0 "
        # 3.0 m
        ogrinfo  $Cinf $quit  -dialect SQLite -sql " UPDATE  $Cdb SET symbol=LUOKKA+2 WHERE  KORARV*10 = 30 AND luokka=54100  AND symbol=0 "
        # 6.0 m
        ogrinfo  $Cinf  $quit -dialect SQLite -sql " UPDATE  $Cdb SET symbol=LUOKKA+3 WHERE  KORARV*10 = 60 AND luokka=54100  AND symbol=0 "
        # 5 m rest
        ogrinfo  $Cinf $quit  -dialect SQLite -sql " UPDATE  $Cdb SET symbol=LUOKKA+4 WHERE  KORARV*10 % 50 = 0 AND luokka=54100 AND KORARV<>0 AND symbol=0 "
	# rest set if there is 5m ...
        ogrinfo  $Cinf $quit  -dialect SQLite -sql " UPDATE  $Cdb SET symbol=LUOKKA+5 WHERE  luokka=54100 AND  symbol=0 "

        ###-- countour end
        ########################################################################
}

#########################################################################
update_some_symbols_s()
{
	# update_some_symbols_s "$destfile" "$table"
	# update symbol table some symbol 
        Xfile="$1"
        Xdb="$2"
	dbg "update_some_symbols_s BEGIN $Xfile $Xdb"

	# pienet avokalliot, pisteina - erottava aluekallioista
	dbg "   " ogrinfo  "$Xfile"  $quit  -dialect SQLite -sql " UPDATE  $Xdb SET symbol=34101 WHERE symbol=34100 "
	ogrinfo  "$Xfile"  $quit  -dialect SQLite -sql " UPDATE  $Xdb SET symbol=34101 WHERE symbol=34100 "

	dbg "update_some_symbols_s END "
}

#########################################################################
update_some_symbols_v()
{
	# update_some_symbols_v "$destfile" "$table"
	# update vector table some vectors and remove some vectors
        Xfile="$1"
        Xdb="$2"
	dbg "update_some_symbols_v BEGIN $Xfile $Xdb"

        # rantaviiva
        dbg "   " ogrinfo  "$Xfile"   $quit -dialect SQLite -sql " UPDATE  $Xdb SET symbol=42300 WHERE kartoglk=36200 "
        ogrinfo  "$Xfile"   $quit -dialect SQLite -sql " UPDATE  $Xdb SET symbol=42300 WHERE kartoglk=36200 "
        # kuvioraja
        dbg "   " ogrinfo  "$Xfile"  $quit  -dialect SQLite -sql " UPDATE  $Xdb SET symbol=30212 WHERE kartoglk=39110 "
        ogrinfo  "$Xfile"  $quit  -dialect SQLite -sql " UPDATE  $Xdb SET symbol=30212 WHERE kartoglk=39110 "
        # ei nayteta kumpaakaan kuviorajaa tiettyjen alueiden reunalla (suo, kallio, ... yms)
        dbg "   " ogrinfo  "$Xfile"   $quit -dialect SQLite -sql " UPDATE  $Xdb SET symbol=0 WHERE symbol IN (30211,30212) AND kartoglk IN (32111,32112,32500,32900,34100,34300,34700,35300,35400,35411,35412,35421,35422,38300,38600,38700)        " 
        ogrinfo  "$Xfile"   $quit -dialect SQLite -sql " UPDATE  $Xdb SET symbol=0 WHERE symbol IN (30211,30212) AND kartoglk IN (32111,32112,32500,32900,34100,34300,34700,35300,35400,35411,35412,35421,35422,38300,38600,38700)        " 

	# countours - korkeus- ja syvyyskayrat
	countour_symbols "$Xfile" "$Xdb"

	dbg "update_some_symbols_v END $Xfile $Xdb "
}


########################################################
shp2gpkg()
{
	#shp2gpkg "$zipf" "$outdir" "$dir" "$zipfile" "$tilename" "$mapname"
	Xzip="$1"
	Xoutdir="$2"

	Xdir="$3"
	Xzipfile="$4"
	Xshpfile=$(getbase "$Xzipfile" ".zip")
	Xtilename="$5"
	Xmapname="$6"

	cd $NOW
	dbg "  shp2gpkg begin: now:$PWD zip:$Xzip zipfile:$Xzipfile shpfile:$Xshpfile tilename:$Xtilename"

	[ ! -f "$Xzip" ] && echo "can't open file:$Xzip" >&2 && exit 3
	rm -f "$TEMP"/*.shp 2>/dev/null  # there are also some other extrafiles, but don't care ... 
	unzip -oqj "$Xzip" -d "$TEMP"

	#for t in v p s #t
	cd $TEMP
	resultfile=""
	oifs="$IFS"

	# kiinteistodatasta kiinnostaa vain palstatiedot, joten muut roskiin , ei  ole Xtype maaritysta niille
	#rm -f *_kiinteisto*.* *_raja*.* 2>/dev/null
	rm -f *_palstaalue*.* *_raja*.* 2>/dev/null


	for shp in *.shp
	do

	  	#msg " $shp"	
		Xbasename=$(getbase "$shp" ".shp")
		IFS="_" Xflds=($Xbasename)
		IFS="$oifs"
		Xnumflds=${#Xflds[*]}

		Xsrclayer="$Xbasename"
		((Xlastfld=Xnumflds-1))
		Xtype=${Xflds[$Xlastfld]}  # last fld
		# s = symbol = POINT
		# v = vektori
		# t = text
		# p = polygon = alue
		dbg "    $shp Xtype:$Xtype Xsrclayer:$Xsrclayer"

		# keep on the own database Cadastral index map - FI: Kiinteistot 
		#case "$Xtype" in
			#kiinteistoraja) Xtype="v" ;;    	# LINE
			#palstaalue) Xtype="p" ;;    	# polygon
			#palstatunnus) Xtype="t" ;;	# text
			#rajamerkki) Xtype="s" ;;	# symbol POINT
		#esac
		# Palstatunnus
		#    TPTEKSTI 
		#    Geometry (POINT)
		# lisattava kentta TEKSTI = TPTEKSTI = kiinteiston tunnus mjono
		# lisattava kentta LUOKKA = 99001
		# lisattava kentta SYMBOL = LUOKKA
		# lisattava kentta SUUNTA = 0
		# KTUNNUS olisi kuntanumero
		#
		# Palstaalue
		#    TPTEKSTI 
		#    Geometry (POLYGON)
		# lisattava kentta LUOKKA = 99002
		# lisattava kentta SYMBOL = LUOKKA
		# KTUNNUS olisi kuntanumero
		# TPTEKSTI = kiinteiston tunnus mjono

		
		dbg "   shp:$shp layer/table:$Xsrclayer type:$Xtype"
		# normalisoidaan vastaamaan maastokartta tauluja  LUOKKA+TEKSTI
		case "$Xtype" in
			palstaalue) continue ;;
			kiinteistoraja) # set LUOKKA value
				dbg ""
				dbg "    - add fields for $Xtype"
				ogrinfo "$shp" $quit -sql "ALTER TABLE $Xsrclayer ADD COLUMN LUOKKA integer"   
				ogrinfo "$shp" $quit -sql "ALTER TABLE $Xsrclayer ADD COLUMN KARTOGLK integer"   

                        	ogrinfo  "$shp" $quit -dialect SQLite -sql "
                                		UPDATE  $Xsrclayer
                                		SET LUOKKA=99002, KARTOGLK=0
                                		"
				;;
			palstatunnus) # set LUOKKA value
				dbg ""
				dbg "    - add fields for $Xtype"
				ogrinfo "$shp" $quit -sql "ALTER TABLE $Xsrclayer ADD COLUMN LUOKKA integer"   
				ogrinfo "$shp" $quit -sql "ALTER TABLE $Xsrclayer ADD COLUMN KARTOGLK integer"   
                        	ogrinfo "$shp" $quit -sql "ALTER TABLE $Xsrclayer ADD COLUMN TEKSTI TEXT(250)"
                        	ogrinfo "$shp" $quit -sql "ALTER TABLE $Xsrclayer ADD COLUMN SUUNTA integer"
                        	ogrinfo  "$shp" $quit -dialect SQLite -sql "
                                		UPDATE  $Xsrclayer
                                		SET LUOKKA=99001, TEKSTI=TPTEKSTI, KARTOGLK=0, SUUNTA=0
                                		"
				;;
			v|t|s|p) # no add on
				;;
			*) continue ;;  # Xtype not needed
		esac

		
		
		# every type of geometry data to the own database
		db=$Xtype
		#resultfile=$Xtilename.$Xtype.gpkg   # every type in the own gpkg  s p t v kiinteistorajapalstaalue palstatunnus
		resultfile=$Xtilename.gpkg   # every type in the own table  in the db file: s p t v kiinteistoraja palstatunnus
		dbg "db:$db Xtype:$Xtype shp:$shp"
		if [ ! -f "$resultfile"  ] ; then # create
			dbg "  - create $resultfile "
			case "$Xtype" in
				palstatunnus|t|s)  # s ei kayttoa tekstilla, mutta menkoon samassa ...
					dbg "   " ogr2ogr -f "GPKG" "$resultfile" "$shp"  $quit -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,TEKSTI,SUUNTA,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					ogr2ogr -f "GPKG" "$resultfile" "$shp"  $quit -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,TEKSTI,SUUNTA,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					;;
				
				v)
					dbg "   " ogr2ogr -f "GPKG" "$resultfile" "$shp"  $quit -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,KORARV,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					ogr2ogr -f "GPKG" "$resultfile" "$shp"  $quit -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,CAST(KORARV AS REAL(8.1) AS KORARV,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					;;
				*)
					dbg "   " ogr2ogr -f "GPKG" "$resultfile" "$shp"  $quit -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					ogr2ogr -f "GPKG" "$resultfile" "$shp"  $quit -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					;;
			esac
		else # append
			dbg "  - update $resultfile "
        		#dbg ogr2ogr -f "GPKG" "$resultfile" -append -update "$shp" -nln "$db" 
        		#ogr2ogr -f "GPKG" "$resultfile" -append -update "$shp" -nln "$db" 2>/dev/null
			case "$Xtype" in
				palstatunnus|t|s) 
					dbg "    " ogr2ogr -f "GPKG" "$resultfile" $quit -append -update "$shp"  -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,TEKSTI,SUUNTA,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					ogr2ogr -f "GPKG" "$resultfile" $quit -append -update "$shp"  -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,TEKSTI,SUUNTA,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					;;
				
				v)
					dbg "    " ogr2ogr -f "GPKG" "$resultfile" $quit -append -update "$shp"  -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,KORARV,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					ogr2ogr -f "GPKG" "$resultfile" $quit -append -update "$shp"  -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,CAST(KORARV AS REAL(8.1)) AS KORARV,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					;;
				*)
					dbg "    " ogr2ogr -f "GPKG" "$resultfile" $quit -append -update "$shp"  -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					ogr2ogr -f "GPKG" "$resultfile" $quit -append -update "$shp"  -dialect sqlite -sql "SELECT LUOKKA,KARTOGLK,FALSE AS DONE, Geometry FROM $Xsrclayer" -nln "$db"
					;;
			esac
		fi
	done 


	dbg "     "
	dbg "   - GPKG done"

}



####################################################################################
data2ocad()
{
	# data2ocad -f "$destfile" -t "$Ytilename" -o "$Ydestdir"  -m "$mapname"
	Zinf=""
	Ztilename=""
	Zdestdir=""
	Zmapname=""
	# loop tables v,t,s,p, palstatunnus, kiinteistoraja, ... 
	# tables s,t,palstatunnus => DXF

	while [ $# -gt 0 ]
	do
        	arg="$1"
        	case "$arg" in
                	-t) Ztilename="$2" ; shift ;;
                	-o) Zdestdir="$2" ; shift ;;
                	-f) Zinf="$2" ; shift ;;
                	-m) Zmapname="$2" ; shift ;;
		esac
		shift
	done
	dbg "data2ocad $Zinf $Ztilename $Zdestdir"

	usagestr="data2ocad usage: -f inoutfile -t tilename -o outdir "
	[ "$Ztilename" = "" ] && err "$usagestr" && return 1
	[ "$Zdestdir" = "" ] && err "$usagestr" && return 1
	[ "$Zinf" = "" ] && err "$usagestr" && return 1
	[ ! -f "$Zinf" = "" ] && err "can't read $Zinf" && return 1


	dbg "          dir:$PWD"

	dbg "             $AWGEO/gptk2csv.sh $Zinf $Ztilename" 
	$AWGEO/gptk2csv.sh -d $DEBUG "$Zinf" "$Ztilename"  
	# result 0-n csv files  $Ztilename.table.csv AND $Ztilename.table.symbols.csv
	
	dbg "data2ocad  CSV2DXF $Ztilename $Zinf"

	dbg "             ogrinfo $quit  -so -ro $Zinf" 
	ogrinfo $quit  -so -ro "$Zinf" | while read Xid tablename Xdescription	
	do

		dbg "          table $tablename"
		case "$tablename" in
                        s)  # symbol = POINT
				[ -f "$Ztilename.$tablename.csv" ] && $AWGEO/csv2dxf.sh --type s --csv "$Ztilename.$tablename.csv" -d $DEBUG   > "$Ztilename.$tablename.dxf"
				# drop this table from gpkg
				dbg "       " ogrinfo "$Zinf" -sql "DROP TABLE $tablename"
				ogrinfo $quit "$Zinf" -sql "DROP TABLE $tablename"
                                ;;
                        t|palstatunnus) # TEXT
				outtable="$tablename"
				[ "$tablename" = "palstatunnus" ] && outtable="kiinteistotunnus"
				[ -f "$Ztilename.$tablename.csv" ] && $AWGEO/csv2dxf.sh --type t --csv "$Ztilename.$tablename.csv" -d $DEBUG  > "$Ztilename.$outtable.dxf"
				# drop this table from gpkg
				dbg "      " ogrinfo "$Zinf" -sql "DROP TABLE $tablename"
				ogrinfo $quit "$Zinf" -sql "DROP TABLE $tablename"
                                ;;
                        *) continue ;;  # table not used
                 esac
	done
	dbg ""
	dbg "DXF done"
}


####################################################################################
gpkg_metsa()
{
	# gpkg_metsa -f "$g" -o "$outdir" -t "$tilename" -m "$mapname"
	dbg "GPKG forest BEGIN "
	Gtilename=""
	Ginf=""
	Gdestdir=""
	Gmapname=""

	while [ $# -gt 0 ]
        do
                arg="$1"
                case "$arg" in
                        -f) Ginf="$2" ; shift ;;
                        -t) Gtilename="$2" ; shift ;;
                        -o) Gdestdir="$2" ; shift ;;
                        -m) Gmapname="$2" ; shift ;;
                esac
                shift
        done
        dbg "         tilename:$Ytilename destdir:$Ydestdir angle:$Yangle "

	Gerrstr="gpkg_metsa usage: -f input.gpkg -t tilename -o outdir "
        [ "$Ginf" = "" ] && err "$Gerrstr" >&2 && return 1
        [ "$Gtilename" = "" ] && err "$Gerrstr" >&2 && return 2
        [ "$Gdestdir" = "" ] && err "$Gerrstr" >&2 && return 3
        [ ! -f "$Ginf" = "" ] && err "Can't read $Ginf" >&2 && return 4

	Xoutf="$Gdestdir/$Gmapname$Gtilename.forestcutting.gpkg"

	Xappend=" -append -update "
	[ ! -f "Xoutf" ] && Xappend=""

	ogr2ogr -f "GPKG" "$Xoutf" "$Ginf" $quit $Xappend -dialect sqlite -sql "SELECT SYMBOL, Geometry FROM metsa WHERE symbol IS NOT NULL AND symbol<>'' " -nln forest


	dbg "GPKG forest END"
}


####################################################################################
gpkg_update()
{
	# gpkg_update -t "$tilename" -o "$outdir" -a "$angle" -m "$mapname"
	# init table changes
	dbg "GPKG update tables ... in dir $PWD"
	Ytilename=""
	Ydestdir=""
	Yangle=""
	Ymapname=""

	while [ $# -gt 0 ]
	do
        	arg="$1"
        	case "$arg" in
                	-t) Ytilename="$2" ; shift ;;
                	-o) Ydestdir="$2" ; shift ;;
                	-a) Yangle="$2" ; shift ;;
                	-m) Ymapname="$2" ; shift ;;
		esac
		shift
	done
	dbg "         tilename:$Ytilename destdir:$Ydestdir angle:$Yangle "

	[ "$Ytilename" = "" ] && err "gpkg_update usage: -t tilename -o outdir [ -a angle ]" && return 1
	[ "$Ydestdir" = "" ] && err "gpkg_update usage: -t tilename -o outdir [ -a angle ]" && return 1
	# angle could be empty, 0, 0.0 or some value
	[ "$Yangle" = "" ] && Yangle=0	

	for destfile in *.gpkg
	do
		
	  	msg " $destfile"	
		Xbasename=$(getbase "$destfile" ".gpkg")


		# loop tables v,t,s,p, palstatunnus, kiinteistoraja, ...
		ogrinfo -q -so -ro "$destfile" | while read Xid tablename Xdescription	
		do
			#tablename=${Xbasename##*.}
			dbg "   GPKG update $destfile table:$tablename "
			ogrinfo "$destfile" $quit -sql "ALTER TABLE $tablename ADD COLUMN SYMBOL INTEGER"
			ogrinfo "$destfile" $quit -sql "ALTER TABLE $tablename ADD COLUMN ANGLE TEXT(250)"
			ogrinfo "$destfile" $quit -sql "ALTER TABLE $tablename ADD COLUMN TEXT TEXT(250)"
		
			ogrinfo  "$destfile" $quit -dialect SQLite -sql "
                			UPDATE  $tablename
                			SET SYMBOL=LUOKKA
                			"
			dbg "      SET extra field values $destfile table:$tablename"
			# update angle
			case "$tablename" in
				s)  # symbol = POINT
					ogrinfo  "$destfile" $quit   -dialect SQLite -sql "
          					UPDATE  $tablename
                					SET ANGLE=CAST(SUUNTA*1.0/10000.0/3.14159*180.0 + $Yangle AS  TEXT(100) )
          					WHERE SUUNTA IS NOT NULL
        					"
					update_some_symbols_s "$destfile" "$tablename"
					;;
				t|palstatunnus) # TEXT
					ogrinfo  "$destfile" $quit  -dialect SQLite -sql "
          					UPDATE  $tablename
                					SET text=TEKSTI  
          					WHERE TEKSTI IS NOT NULL
        				"
					ogrinfo  "$destfile"  $quit   -dialect SQLite -sql "
          					UPDATE  $tablename
                					SET ANGLE=CAST(SUUNTA*1.0/10000.0/3.14159*180.0 + $Yangle AS  TEXT(100) )
          					WHERE SUUNTA IS NOT NULL
        					"
					;;
				v)  # need some symbol setup fixing for Ocad
					update_some_symbols_v "$destfile" "$tablename"
					;;  
				p) ;;
				*) continue ;;  # table not used
			esac

			
		done

		[ -f "$gpkg" ] && ((makeocad > 0 )) && cp -f "$destfile" "$Xbasename.full.gpkg" && dbg "done:$Xbasename.full.gpkg"

		# make dxf from text and symbol, handle angle DXF 
		((makeocad > 0)) && data2ocad -f "$destfile" -t "$Ytilename" -o "$Ydestdir"  -m "$Ymapname"

		dbg "   GPKG update $destfile table:$tablename done"
		dbg ""
	done


	dbg "GPKG update tables DONE"
	#
	cd $NOW
	dbg "     - copy $TEMP/*.gpkg to the dir:$Xoutdir"
	for gpkg in "$TEMP"/*.gpkg
	do
		[ ! -f "$gpkg" ] && continue
		dbg "resultfile:$gpkg"
		Xfname=$(getfile "$gpkg")
		Xbasename=$(getbase "$Xfname" ".gpkg")
		[ -f "$gpkg" ] && cp -f "$gpkg" "$Ydestdir"/"$Ymapname$Xfname" && dbg "done:$Ydestdir/$Xfname"
	done

	#((makeocad > 0 )) && cp -f "$TEMP"/*.dxf  "$Ydestdir" 2>/dev/null
	dbg "     - copy $TEMP/*.dxf to the dir:$Xoutdir"
	for dxf in "$TEMP"/*.dxf
	do
		[ ! -f "$dxf" ] && continue
		dbg "resultfile:$dxf"
		Xfname=$(getfile "$dxf")
		Xbasename=$(getbase "$Xfname" ".dxf")
		[ -f "$dxf" ] && cp -f "$dxf" "$Ydestdir"/"$Ymapname$Xfname" && dbg "done:$Ydestdir/$Xfname"
	done


	cp -f $AWGEO/config/FIshp2ISOM2017.v2.crt "$Ydestdir" 2>/dev/null
	cp -f $AWGEO/config/awot_ocadisom2017_mml.v2.ocd "$Ydestdir"/"$Ymapname$Ytilename".ocd 2>/dev/null
	dbg "      done"

	(( DEBUG<1)) && rm -rf "$TEMP" 2>/dev/null
	dbg "TEMP:$TEMP"
}


######################################################################################
# MAIN
######################################################################################
url=""
outputdir="gpkg"
tiledir=1
id=$$
quit=" -q "
tilename=""
makeocad=1
angle=0
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

[ "$apikey" = "" ] && err "no apikey?" && exit 2
[ "$apihost" = "" ] && err "no apihost?" && exit 3

while [ $# -gt 0 ] 
do
	arg="$1"
	case "$arg" in
		-d) DEBUG="$2" ; shift ;;
		-a|--angle) angle="$2" ; shift ;;
		-o|--outputdir) outputdir="$2" ; shift ;;
		-i|--id) id="$2" ; shift ;;
		-t|--tiledir|--tile) tiledir=$2; shift ;;
		-n|--tilename|--name) tilename=$2; shift ;;
		-m|--makeocad|--ocad) makeocad=$2; shift ;;
		--mapname) mapname="$2" ; shift ;;
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
NOW=$PWD

((DEBUG>1)) && quit=" "

mapname="${mapname%.}"  # remove last dot if exists

[ "$mapname" != "" ] && mapname="$mapname."

zipcnt=0

# shape to gpkg

# loop zip files
for zipf in $*
do

	cd $NOW
	[ ! -f "$zipf" ] && continue
	end=${zipf##*.}
	[ "$end" != "zip" ] && continue

	((zipcnt++))
	msg "$zipf"
        dir=$(getdir "$zipf")
        zipfile=$(getfile "$zipf")
        shpfile=$(getbase "$zipfile" ".zip")
        Xtilename=$(getbase "$shpfile" ".shp")
	# 1st file give the tilename if not set
	[ "$tilename" = "" ] && tilename="$Xtilename"
	outdir="$outputdir/$tilename"
	(( tiledir < 1 )) && outdir="$outputdir"  # no tilename subdir

	#rm -rf "$TEMP"
	dbg "mkdir -p $TEMP $outdir"
	mkdir -p "$TEMP" "$outdir"

	# if exist old, rm it
	((zipcnt<2)) && rm -f "$outdir"/"$mapname$tilename".gpkg "$outdir"/"$mapname$tilename".*.gpkg 2>/dev/null
	((zipcnt<2)) && rm -f "$outdir"/"$mapname$tilename".*.dxf 2>/dev/null

	dbg shp2gpkg "zipf:$zipf" "outdir:$outdir" "sourcedir:$dir" "zipfile:$zipfile" "tilename:$tilename mapname:$mapname"
	shp2gpkg "$zipf" "$outdir" "$dir" "$zipfile" "$tilename" "$mapname"
done

# update gpkg db and make dxf
# TEMP is still dir ...
dbg "gpkg_update ..."
gpkg_update -t "$tilename" -o "$outdir" -a "$angle"  -m "$mapname"

# now in the dir where we started this program
# metsa files ???
# and all other gpkg files, ready to load
cd $NOW

# loop gpkg files
# if there is old, remove it
Forestoutf="$outdir/$mapname$tilename.forestcutting.gpkg"
[ -f "$Forestoutf" ] && rm -f "$Forestoutf" 2>/dev/null

for g in $*
do
	[ ! -f "$g" ] && continue
	end=${g##*.}
	[ "$end" != "gpkg" ] && continue

	gpkg_metsa -f "$g" -o "$outdir" -t "$tilename" -m "$mapname"

done


dbg "done:$outdir"

