# Generic bash setup for Barbara & Terry on the Cambridge CSD3 cluster.

# Newly created files should be group writable.
umask 002

# Make things sort in a sensible way (by bytes).
export LC_ALL=C

case $(hostname) in
    login-e-[1-8]|gpu-e-*)
        HOST=csd3-gpu-$(hostname | cut -f3 -d-)
        gpu=1
    ;;
    login-e-*|cpu-e-*)
        HOST=csd3-cpu-$(hostname | cut -f3 -d-)
        gpu=0
    ;;
    *)
        echo "Warning: your hostname $(hostname) is not recognized!" >&2
    ;;
esac

export PS1="$HOST "'\w \$ '
export PS2="> "

BT=/rds/project/djs200/rds-djs200-acorg/bt
BT2=/rds/project/djs200/rds-djs200-acorg2/bt

ROOT=$BT/root

if [ ! -d $ROOT ]
then
    echo "Warning: could not find $ROOT directory!" >&2
fi

PATH="$HOME/bin:$BT/csd3/bin:$BT/projects/eske/voldemort-repo/bin:$BT2/projects/charite/bih-pipeline/bin:$ROOT/usr/local/bin:$ROOT/bin:$ROOT/usr/bin:$ROOT/usr/local/edirect:$PATH"
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$ROOT/usr/local/lib"

# Our virtual environments are shared.
export WORKON_HOME=$ROOT/share/virtualenvs

f=$ROOT/usr/local/bin/virtualenvwrapper.sh
if [ -f $f ]
then
    . $f
else
    echo "Could not find virtualenvwrapper script $f" >&2
fi

f=/etc/profile.d/modules.sh
if [ -f $f ]
then
    . $f

    module load beast2-2.4.6-gcc-5.4.0-czr4tw6
    module load beagle-lib-2.1.2-gcc-4.8.5-ti5kq5r

    if [ $gpu -eq 1 ]
    then
        module load cuda-8.0.61-gcc-5.4.0-qa4toca
    fi
else
    echo "Warning: Module setup script $f does not exist!" >&2
fi

# A function to get an RCS (Research Cold Store) equivalent directory given
# an RDS (Research Data Store) directory.
function rcs_equiv() {
    local cwd
    case $# in
        0)
            cwd=$(/bin/pwd)
        ;;
        1)
            case "$1" in
                /*) cwd="$1";;
                *) cwd="$(/bin/pwd)/$1";;
            esac
        ;;
        *)
            echo "Usage: rcs_equiv [dir]" >&2
            return 1
        ;;
    esac

    case "$cwd" in
        /rds/project/djs200/rds-djs200-acorg/bt*)
            echo "/rcs/project/djs200/rcs-djs200-acorg/bt"$(echo "$cwd" | cut -c40-)
            return 0
        ;;
        *)
            echo "I do not recognize $cwd as an RDS or /scratch directory." >&2
            # Echo a non-existent directory name to hopefully make whoever
            # called us fail if they don't check our return status and they
            # capture our stdout and try to use it to do a cd.
            echo /tmp/non-existent-directory-$$
            return 1
        ;;
    esac
}

export -f rcs_equiv

# A function to get an RDS (Research Data Store) equivalent directory given
# an RCS (Research Cold Store) directory.
function rds_equiv() {
    local cwd
    case $# in
        0)
            cwd=$(/bin/pwd)
        ;;
        1)
            case "$1" in
                /*) cwd="$1";;
                *) cwd="$(/bin/pwd)/$1";;
            esac
        ;;
        *)
            echo "Usage: rds_equiv [dir]" >&2
            return 1
        ;;
    esac

    case "$cwd" in
        /rcs/project/djs200/rcs-djs200-acorg/bt*)
            echo "/rds/project/djs200/rds-djs200-acorg/bt"$(echo "$cwd" | cut -c40-)
            return 0
        ;;
        *)
            echo "I do not recognize $cwd as an RCS or /scratch directory." >&2
            # Echo a non-existent directory name to hopefully make whoever
            # called us fail if they don't check our return status and they
            # capture our stdout and try to use it to do a cd.
            echo /tmp/non-existent-directory-$$
            return 1
        ;;
    esac
}

export -f rds_equiv

# A function to cd to the equivalent location in the 'other' storage type.
# I.e., to easily switch back and forth between RDS and RCS.
function cdo() {
    local cwd=$(/bin/pwd)
    case "$cwd" in
        /rcs/*) cd $(rds_equiv);;
        /rds/*) cd $(rcs_equiv);;
        *) echo "I do not recognize $cwd as an RDS or RCS directory." >&2;;
    esac
}

export -f cdo
