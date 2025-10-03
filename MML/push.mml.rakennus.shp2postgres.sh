#!/usr/local/bin/awsh
# push.mml.rakennus.shp2postgres.sh  *.zip
# Ver 2025-03-10 b
# push r_NNNNN_p.shp files from some dir to the postgresql database
# r_NNNNN_p 
#
# Ensin haettu MML aineisto
#   $AWMML/get.mml.karttadata.sh -l lahdedata/pk.txt -o maastotietokanta -v 0
#
# ja sitten kantaan talla scriptilla
#   cd maastotietokanta
#   $AWMML/push.mml.rakennus.shp2postgres.sh -v 0 -d 1 -m 0 --pgdb gis --pgschema mml *.shp.zip
#
# em. maastotietokanta kansiossa haettuna maastotietokannan tiedostoja Xnnnn.shp.zip tiedostot
#
#

# env variable to have been set
#export PGHOST=localhost
#export PGPORT=5432
#export PGUSER=myusername
#export PGPASSWORD=mypassword
#export PGDATABASE=mydatabase
#export PGCLIENTENCODING=UTF-8
# or give those using options
# or set those values in the $HOME/.pgpass

PRG=$0
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


#######################################################
usage()
{
cat <<EOF >&2
usage:$PRG [ --options ] list_of_shapefiles
      $PRG *_kiinteistoraja.shp
      $PRG --pgdb gis  --pguser myusername *_kiinteistoraja.shp


EOF
}

#######################################################
timestamp()
{
	printf "%(%Y-%m-%d_%H%M%S)T" now 
}

#######################################################
log()
{
	echo "$(timestamp) $*" >> $lf
}

#######################################################
err()
{
	echo "$(timestamp) err: $*" >> $errf
}

#######################################################
msg()
{
	((MSG<1)) && return
	echo "$*" >&2
}

#######################################################
dbg()
{
	((DEBUG<1)) && return
	echo "dbg:$*" >&2
	log "dbg:$*"
}

#######################################################
dosql()
{
	flag=""
	erotisn=";"
	[ "$1" = "-t" ] && flag=" -t " && shift
	# get sql from stdin
	SQL=$(<&0)
	dbg "SQL: $SQL"
	echo "
	\a
        \\f '$erotin'
        \pset footer off
	$SQL
	;" | psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER"  -q $flag "$PGDATABASE" 2>>$errf 
	pgstat=$?
	return $pgstat
	###(( pgstat>0 )) && err "dosql status:$pgstat" && exit 10
}

#######################################################
table_add_recs()
{

        Ytable="$1"
        Ylayer="$2"
        Yshpfile="$3"
        Yarea="$4"
        dbg "table_add_recs:$Ytable - $Ylayer - $Yshpfile - $Yarea"
	((verbose > 0 )) && return 0

        export PG_USE_COPY=YES
	# to tmp db
	ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" "$Yshpfile" -nln $PGSCHEMA.tmp_$Ytable -lco GEOMETRY_NAME=geom  \
        -dialect postgresql -sql "SELECT '$Yarea' AS area, $dbfields  FROM $Ylayer "  -lco FID=keyid  -overwrite

        Cstat=$?
        (( Cstat > 0 )) && dbg "  table $Ytable adding to the temp table not success status:$Cstat" && return 1 # can't create/add ???
	dbg "table_add_recs: add to temp done"
	log "table_add_recs: $PGSCHEMA.tmp_$Ytable  - $Ylayer - $Yshpfile - $Yarea"

	dbg "table_add_recs: to table $PGSCHEMA.$Ytable from $PGSCHEMA.tmp_$Ytable  "
	# tmp_XXX table include loaded recs
	# delete same geom's from table = old value
	# and then insert from tmp-table same geom = new updated value
        # this way no need to UPDATE fld by fld
	# no keyvalue, except geom ....
	value=$(dosql -t <<EOF
		BEGIN;
		-- DELETE from table those geom are same

		DELETE FROM $PGSCHEMA.$Ytable t
		USING $PGSCHEMA.tmp_$Ytable tmp
		WHERE t.geom = tmp.geom AND t.area = tmp.area;

		-- ADD from tmp-table to the table and check that it's not there even why have jut deleted those ...
		INSERT INTO $PGSCHEMA.$Ytable
		SELECT u.* FROM  $PGSCHEMA.tmp_$Ytable  u
		LEFT OUTER JOIN $PGSCHEMA.$Ytable t2 ON u.geom=t2.geom
		WHERE t2.keyid IS NULL
		;
		END;
EOF
)
	dbg "after sql:$value"
	log "table_add_recs: $PGSCHEMA.$Ytable  done - $Ylayer - $Yshpfile - $Yarea"
	dbg "table_add_recs: $PGSCHEMA.$Ytable  done - $Ylayer - $Yshpfile - $Yarea"
	dbg "table_add_recs: end $Ylayer - $Yshpfile - $Yarea"



}

#######################################################
table_create()
{
	
	Ytable="$1"
	Ylayer="$2"
	Yshpfile="$3"
	dbg "table_create:$Ytable - $Ylayer - $Yshpfile"
	((verbose > 0 )) && return 0
	value=$(dosql -t <<EOF
		SELECT count(*) FROM $PGSCHEMA.$Ytable LIMIT 1
		;
EOF
)
	dbg "table_create: check $PGSCHEMA.$Ytable "
	dbg "              <$value>"
	[ "$value"  != "" ] && dbg "  table $Ytable exists" && return 0 # table exists
	dbg "  table $Ytable not exists"

	export PG_USE_COPY=YES

	dbg "  add temp table $PGSCHEMA.$Ytable using $Yshpfile"

	ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" "$Yshpfile" -nln $PGSCHEMA.$Ytable -lco GEOMETRY_NAME=geom  \
	-dialect postgresql -sql "SELECT '$Yarea' AS area, $dbfields  FROM $Ylayer LIMIT 1"  -lco FID=keyid  -overwrite

	Cstat=$?
	(( Cstat > 0 )) && dbg "  table $Ytable creating not success status:$Cstat" && return 1 # can't create ???

	# remove that 1st created line, later add all recs
	# remove ogr2ogr pkkey and create our own
	value=$(dosql -t <<EOF
		DELETE FROM $PGSCHEMA.$Ytable;
		ALTER TABLE IF EXISTS $PGSCHEMA.$Ytable DROP CONSTRAINT IF EXISTS ${Ytable}_pkey;
		--ALTER TABLE IF EXISTS $PGSCHEMA.$Ytable ADD CONSTRAINT ${Ytable}_pkey PRIMARY KEY (keyid, area);
		;
EOF
)
	log "table_created $Ytable - $Ylayer - $Yshpfile"
	dbg "table_create: end"
}

#######################################################
# MAIN
#######################################################
mitka=""
verbose=0
mkdir -p tmp
chmod 1777 tmp 2>/dev/null
SESID=$$
MSG=1
errf=$PWD/tmp/$SESID.$PRG.err
lf=$PWD/tmp/$SESID.$PRG.log
PGSCHEMA=public
verbose=0
# select only some fields, not all
dbfields="syntyhetki, kuolhetki, ryhma, luokka, CAST(kohdeoso AS bigint) AS kohdeoso, korkeus"

while [ $# -gt 1 ]
do
	arg="$1"
	case "$arg" in
		--pguser) export PGUSER="$2"; shift ;;
		--pghost) export PGHOST="$2"; shift ;;
		--pgdatabase|--pgdb) export PGDATABASE="$2"; shift ;;
		--pgport) export PGPORT="$2"; shift ;;
		--pgpass) export PGPASSWORD="$2"; shift ;;
		--pgencode) export PGCLIENTENCODING="$2"; shift ;;
		--pgschema) PGSCHEMA="$2"; shift ;;
		--debug|-d) DEBUG="$2"; shift ;;
		--message|-m) MSG="$2"; shift ;;
		--verbose|-v) verbose="$2"; shift ;;
		-*) usage ; exit 2 ;;
		*) break ;; # datavalue list
	esac
	shift
done


[ $# -lt 1 ] && usage && exit 1

log "$PRG start"
msg "log:$lf err:$errf" 


NOW=$PWD
rm -rf tmpshp 2>/dev/null
mkdir -p tmpshp

for Xzipfile in $*
do
	cd $NOW
	unzip -qq -oj -d tmpshp "$Xzipfile" 
	mkdir -p tmpshp
	cd tmpshp

	Xarea=${Xzipfile%%.shp.zip*}
	Xshpfile="r_${Xarea}_p.shp"
	Xlayer="r_${Xarea}_p"
	Xtable=rakennus
	dbg "$(timestamp)"
	msg "Xlayer:$Xlayer Xarea:$Xarea Xtable:$Xtable"
	dbg "Xlayer:$Xlayer Xarea:$Xarea Xtable:$Xtable"
	((verbose > 0 && verbose < 2 )) && continue
	# verbose >1 dbg message, not do SQL insert
	table_create "$Xtable" "$Xlayer" "$Xshpfile" 
	table_add_recs "$Xtable" "$Xlayer" "$Xshpfile" "$Xarea"

	cd $NOW
	rm -rf tmpshp 2>/dev/null
done 

log "$PRG end"
msg "log:$lf err:$errf" 


