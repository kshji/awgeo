#!/bin/bash
#
# Shell Parameter Expansion
# some examples
x=123_456_789
echo $x '${x##*_}': ${x##*_} # last  
# 789
echo $x '${x#*_}':  ${x#*_}  # not 1st
# 456_789
echo $x '${x%%_*}': ${x%%_*} # 1st 
# 123
echo $x '${x%_*}':  ${x%_*}  # not last
# 123_456

# korvaa alusta
x="123456123456123"
echo $x '${x/#123/8888}' ${x/#123/8888}
# korvaa lopusta
echo $x '${x/%123/9999}'  ${x/%123/9999}

x="path/abc/file.names"
echo $x '${x##*/}': ${x##*/}  # last
filename=${x##*/}
echo $filename '${filename%.name*}': ${filename%.name*}  # not last = basename accept also .name* ex. .names
echo $filename '${filename%.name}':  ${filename%.name}  # before .name = basename   accept only ending .name


prosnum="processes=4"
echo ${prosnum##*=}  # last fld, delimiter =


# Look Parameter Expansion:
# https://github.com/ksh93/ksh/tree/dev/docs/ksh
# https://www.gnu.org/software/bash/manual/bash.html#Command-Substitution
# https://www.ibm.com/docs/en/aix/7.1.0?topic=shell-parameter-substitution-in-korn-posix
# https://pubs.opengroup.org/onlinepubs/9799919799.2024edition/utilities/V3_chap02.html  
# https://www.oreilly.com/library/view/korn-shell-unix/0201675234/0201675234_app05lev1sec12.html

# getopts or ...
while [[ $1 == -* ]]
do
        arg="$1"
        case "$arg" in
                -d) DEBUG=$2;shift;;
                --originE) OriginE=$2;shift;;
                --originN) OriginN=$2;shift;;
                -E) E=$2;shift;;
                -N) N=$2;shift;;
                --scale|-s) scalestr=$2;shift;;
                --angle|-a) AngleDeg=$2;shift;;
                --lat) latDeg=$2;shift;;
                --lon) lonDeg=$2;shift;;
                --cmd|-c) Cmd=$2;shift;;
		-*) usage ;;
        esac
        shift
done
# $* is data if there is something left
#
#
: '/*
LC_ALL	The LC_ALL value takes precedence over the values of all the other environment variables, and if set, determines the language, character set, sort order, and data formats.
LC_COLLATE	This environment variable defines the collating sequence (or sort order).
LC_CTYPE	This environment variable defines the character classification and case conversion.
LC_MESSAGES	This environment variable defines the language and character set for messages.
LC_MONETARY	This environment variable defines the format for monetary numeric information.
LC_NUMERIC	This environment variable defines numeric, non-monetary formatting.
LC_TIME	This environment variable defines the date and time formats.
LANG	If LC_ALL is not set, the LANG value determines the language, character set, and sort order. Different elements of the LANG value can be overridden by setting the LC_COLLATE, LC_CTYPE, LC_MESSAGE, and LC_TIME environment variables.
*/'
