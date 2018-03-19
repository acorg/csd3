# Generic bash setup for Barbara & Terry on the Cambridge CSD3 cluster.

case $(hostname) in
    login-e-[1-8]) HOST=csd3-gpu-$(hostname | cut -f3 -d-);;
    login-e-*) HOST=csd3-cpu-$(hostname | cut -f3 -d-);;
    *) HOST=biocloud;;
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

export VIRTUALENVWRAPPER_PYTHON=$ROOT/bin/python

f=$ROOT/usr/bin/virtualenvwrapper.sh
[ -f $f ] && . $f
