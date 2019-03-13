#!/bin/bash

set -Eeuo pipefail

simulate=0

while [ $# -gt 0 ]
do
    case "$1" in
        -n)
            simulate=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

function run()
{
    if test $simulate -eq 0
    then
        echo eval "$@"
    else
        echo "    $@"
    fi
}

run date

for path in "$@"
do
    echo "Processing $path"
    dir=$(dirname "$path")
    file=$(basename "$path")

    cd "$dir"
    rcsdir="$(rcs_equiv)"

    if [ -L "$file" ]
    then
        echo "    Is a link. Nothing to do."
    elif [ -f "$file" ]
    then
        if [ -f "$rcsdir/$file" ]
        then
            echo "    Is a normal file and is also present in cold storage. Removing and creating link."
            run rm -f "$file"
            run ln -s "$rcsdir/$file"
        else
            echo "    Is a normal file but is not in cold storage. Moving to RCS and creating link."
            if [ ! -d "$rcsdir" ]
            then
                echo "    RCS dir doesn't exist. Creating."
                run mkdir -p "$rcsdir"
            fi
            run mv "$file" "$rcsdir/$file"
            run ln -s "$rcsdir/$file"
        fi
    else
        echo "    WARNING! $file is apparently not a file or link"
    fi

    cd "$OLDPWD"
done
