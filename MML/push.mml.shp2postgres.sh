#!/usr/local/bin/awsh
# push.mml.shp2postgres.sh *_kiint.shp
# push shp files from some dir to the postgresql database
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
        dbg ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" "$Yshpfile" -nln $PGSCHEMA.tmp_$Ytable -lco GEOMETRY_NAME=geom -dialect postgresql -sql "SELECT CAST(id AS BIGINT) AS keyid,'$Yarea' AS area,* FROM $Ylayer " -lco FID=keyid -overwrite
        ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" "$Yshpfile" -nln $PGSCHEMA.tmp_$Ytable -lco GEOMETRY_NAME=geom -dialect postgresql -sql "SELECT CAST(id AS BIGINT) AS keyid,'$Yarea' AS area,* FROM $Ylayer " -lco FID=keyid -overwrite
        Cstat=$?
        (( Cstat > 0 )) && dbg "  table $Ytable adding to the temp table not success status:$Cstat" && return 1 # can't create/add ???
	dbg "table_add_recs: add to temp done"
	log "table_add_recs: $PGSCHEMA.tmp_$Ytable  - $Ylayer - $Yshpfile - $Yarea"

	dbg "table_add_recs: to table $PGSCHEMA.$Ytable from $PGSCHEMA.tmp_$Ytable  "
	# tmp_XXX table include loaded recs
	# delete same id's from table = old value
	# and then insert from tmp-table same id = new updated value
        # this way no need to UPDATE fld by fld
	value=$(dosql <<EOF
		BEGIN;
		-- DELETE from table those ID's which are in the tmp-table
		DELETE FROM  $PGSCHEMA.$Ytable t
		USING $PGSCHEMA.$Ytable AS u
		LEFT OUTER JOIN $PGSCHEMA.tmp_$Ytable d ON u.keyid=d.keyid
		WHERE
        		t.keyid = u.keyid
		;

		-- ADD from tmp-table to the table and check that it's not there even why have jut deleted those ...
		INSERT INTO $PGSCHEMA.$Ytable
		SELECT u.* FROM  $PGSCHEMA.tmp_$Ytable  u
		LEFT OUTER JOIN $PGSCHEMA.$Ytable t2 ON u.keyid=t2.keyid
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
	value=$(dosql <<EOF
		SELECT count(*) FROM $PGSCHEMA.$Ytable LIMIT 1
		;
EOF
)
	dbg "table_create: check $PGSCHEMA.$Ytable $value"
	[ "$value"  != "" ] && dbg "  table $Ytable exists" && return 0 # table exists
	dbg "  table $Ytable not exists"

	export PG_USE_COPY=YES

	dbg ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" "$Yshpfile" -nln $PGSCHEMA.$Ytable -lco GEOMETRY_NAME=geom -dialect postgresql -sql "SELECT CAST(id AS BIGINT) AS keyid,'CREATE' AS area,* FROM $Ylayer LIMIT 1" -lco FID=keyid -overwrite
	ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" "$Yshpfile" -nln $PGSCHEMA.$Ytable -lco GEOMETRY_NAME=geom -dialect postgresql -sql "SELECT CAST(id AS BIGINT) AS keyid,'CREATE' AS area,* FROM $Ylayer LIMIT 1" -lco FID=keyid -overwrite
	Cstat=$?
	(( Cstat > 0 )) && dbg "  table $Ytable creating not success status:$Cstat" && return 1 # can't create ???

	# remove that 1st created line, later add all recs
	value=$(dosql <<EOF
		DELETE FROM $PGSCHEMA.$Ytable
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
errf=$PWD/tmp/$SESID.$PRG.err
lf=$PWD/tmp/$SESID.$PRG.log
PGSCHEMA=public
verbose=0

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
		--verbose|-v) verbose="$2"; shift ;;
		-*) usage ; exit 2 ;;
		*) break ;; # datavalue list
	esac
	shift
done


[ $# -lt 1 ] && usage && exit 1

log "$PRG start"
for Xshpfile in $*
do
	Xlayer=${Xshpfile%%.*}	
	Xarea=${Xlayer%_*}
	Xtable=${Xlayer##*_}
	dbg "$(timestamp)"
	dbg "Xlayer:$Xlayer Xarea:$Xarea Xtable:$Xtable"
	((verbose > 0 && verbose < 2 )) && continue
	# verbose >1 dbg message, not do SQL insert
	table_create "$Xtable" "$Xlayer" "$Xshpfile" 
	table_add_recs "$Xtable" "$Xlayer" "$Xshpfile" "$Xarea"
done 

log "$PRG end"


