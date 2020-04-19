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
        eval "$@"
    else
        echo "    $@"
    fi
}

for path in "$@"
do
    echo "Processing $path"
    dir=$(dirname "$path")
    file=$(basename "$path")

    cd "$dir"

    if [ -L "$file" ]
    then
        dest=$(readlink "$file")

        if [ -f "$dest" ]
        then
            # Check the first char of $dest to see whether we should make
            # an absolute or relative link.
            case "$dest" in
                /*) rFlag= ;;
                *) rFlag=-r ;;
            esac

            run rm "$file"
            run ln $rFlag -s "$dest" "$file"
        else
            echo "    Is a symbolic link to '$dest', which doesn't exist! Skipping."
        fi
    else
        echo "    Is not a symbolic link. Nothing to do."
    fi

    cd "$OLDPWD"
done
