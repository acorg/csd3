# Generic bash setup for Barbara & Terry on the Cambridge CSD3 cluster.

case $(hostname) in
    login-e-[1-8])
        HOST=csd3-gpu-$(hostname | cut -f3 -d-)
        gpu=1
        loadModules=1
    ;;
    login-e-*)
        HOST=csd3-cpu-$(hostname | cut -f3 -d-)
        gpu=0
        loadModules=1
    ;;
    *)
        HOST=biocloud
        gpu=0
        loadModules=0
    ;;
esac

export PS1="$HOST "'\w \$ '
export PS2="> "

ROOT=/rds/project/djs200/rds-djs200-acorg/bt/root

if [ ! -d $ROOT ]
then
    # This is only temporary, for biocloud.
    ROOT=/scratch/tcj25/root
fi

if [ ! -d $ROOT ]
then
    echo "Warning: could not find $ROOT directory!" >&2
fi

PATH="$HOME/bin:$ROOT/usr/local/bin:$ROOT/bin:$ROOT/usr/bin:$PATH"
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$ROOT/usr/local/lib"

# Our virtual environments are shared.
export WORKON_HOME=$ROOT/share/virtualenvs

# I don't think this is needed.
# export VIRTUALENVWRAPPER_PYTHON=$ROOT/usr/local/bin/python

f=$ROOT/usr/bin/virtualenvwrapper.sh
[ -f $f ] && . $f

if [ $loadModules -eq 1 ]
then
    f=/etc/profile.d/modules.sh
    [ -f $f ] && . $f

    module load rhel7/default-csd3
    module load beast2-2.4.6-gcc-5.4.0-czr4tw6

    if [ $gpu -eq 1 ]
    then
        module load rhel7/default-gpu
        module load cuda-8.0.61-gcc-5.4.0-qa4toca

        # Don't use the system BEAGLE module because it will not detect the
        # GPU(s).
        export BEAGLE_EXTRA_LIBS=$ROOT/usr/local/lib
    else
        module load beagle-lib-2.1.2-gcc-5.4.0-fmn7glx
    fi
fi

# A function to get an RCS (Research Cold Store) equivalent directory given
# an RDS (Research Data Store) or biocloud /scratch directory.
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
        /scratch/tcj25/projects*)
            echo "/rcs/project/djs200/rcs-djs200-acorg/bt"$(echo "$cwd" | cut -c15-)
            return 0
        ;;
        /biocld1/tcj25/projects*)
            echo "/rcs/project/djs200/rcs-djs200-acorg/bt"$(echo "$cwd" | cut -c15-)
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
# an RCS (Research Cold Store) or biocloud /scratch directory.
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
        /scratch/tcj25/projects*)
            echo "/rds/project/djs200/rds-djs200-acorg/bt"$(echo "$cwd" | cut -c15-)
            return 0
        ;;
        /biocld1/tcj25/projects*)
            echo "/rds/project/djs200/rds-djs200-acorg/bt"$(echo "$cwd" | cut -c15-)
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
