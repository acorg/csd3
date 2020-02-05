#!/usr/bin/env python

from __future__ import print_function

import sys
import os
from os.path import basename, exists
from tempfile import mkstemp
import argparse

from dark.process import Executor

BT = '/rds/project/djs200/rds-djs200-acorg/bt'

parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='Run commands using sbatch')

parser.add_argument(
    'args', nargs='*',
    help='The command to run')

parser.add_argument(
    '--exclusive', action='store_true',
    help=('If given, run on an exclusive machine. Defaults to False, unless '
          '--gpu is given.'))

parser.add_argument(
    '--dryRun', action='store_true', default=False,
    help=('If given, do not actually execute the sbatch script. '
          'Implies --keep.'))

parser.add_argument(
    '--keep', action='store_true', default=False,
    help='If given, keep the sbatch submission file and print its path.')

parser.add_argument(
    '--force', action='store_true', default=False,
    help='If given, use -overwrite when calling beast2 (via --beast2).')

parser.add_argument(
    '--job', default=basename(sys.argv[0]),
    help='The job id passed with -J to sbatch.')

parser.add_argument(
    '--account',
    help=('The account name, passed with -A to sbatch. Default is '
          'DSMITH-SL2-GPU if --gpu is given, else ACORG-SL2-CPU.'))

parser.add_argument(
    '--out', default='slurm-%A.out',
    help='The SLURM output file name, passed with -o to sbatch.')

parser.add_argument(
    '--partition',
    help=('The SLURM partition, passed with -p to sbatch. Default is pascal '
          'if --gpu is given, else skylake.'))

parser.add_argument(
    '--time',
    help=('The SLURM time limit, passed with --time to sbatch. Default is '
          '11:50:00 if --gpu is given, else 1:00:00'))

parser.add_argument(
    '--gpu', action='store_true', default=False,
    help=('If given, schedule on a GPU machine (causes --partition to become '
          'pascal, --exclusive to be set, --account to be DSMITH-SL2-GPU.'))

parser.add_argument(
    '--beast2', action='store_true', default=False,
    help=('If given, set default --time to be 11:50:00. Best used with --gpu. '
          'If you only supply one command-line argument it will be taken as '
          'an XML file and given to beast2.'))

args = parser.parse_args()

if args.dryRun:
    args.keep = True

if args.beast2 and len(args.args) == 1:
    # Take the single argument to be an XML filename to give to Beast.
    filename = args.args[0]
    if not exists(filename):
        print('The file %r (used with --beast2) does not exist.',
              file=sys.stderr)
        sys.exit(1)

    args.args = [
        BT + '/packages/beast2-gpu/beast/bin/beast',
        '-threads',
        '4',
        '-beagle_order',
        '1,2,3,4',
        '-beagle',
        '-beagle_GPU',
    ]

    if args.force:
        args.args.append('-overwrite')

    args.args.append(filename)

if args.gpu:
    args.exclusive = True
    args.account = args.account or 'DSMITH-SL2-GPU'
    args.partition = args.partition or 'pascal'
    args.time = args.time or '11:50:00'
else:
    args.account = args.account or 'ACORG-SL2-CPU'
    args.partition = args.partition or 'skylake'
    args.time = args.time or '1:00:00'

(fd, filename) = mkstemp(prefix='sbatch-commands-', suffix='.sh', text=True)
fp = os.fdopen(fd, 'w')

try:
    print('#!/bin/bash', end='\n\n', file=fp)
    print('#SBATCH -J', args.job, file=fp)
    print('#SBATCH -A', args.account, file=fp)
    print('#SBATCH -o', args.out, file=fp)
    print('#SBATCH -p', args.partition, file=fp)
    print('#SBATCH --time=%s' % args.time, file=fp)
    if args.exclusive:
        print('#SBATCH --exclusive', file=fp)
    if args.gpu:
        print('#SBATCH --nodes=1', file=fp)
        print('#SBATCH --gres=gpu:4', file=fp)

    print(file=fp)

    print('set -Eeuo pipefail', end='\n\n', file=fp)

    # Export these two variables in any case as they cannot do any harm (in
    # face can only help) and are required for --beast2 runs.
    lib = BT + '/root/usr/local/lib'
    print('export BEAGLE_EXTRA_LIBS=%s' % lib, file=fp)
    print('export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%s' % lib, end='\n\n',
          file=fp)

    if args.args:
        print(' '.join(args.args), file=fp)
    else:
        if os.isatty(0):
            print('Enter commands, ending input with a control-d',
                  file=sys.stderr)
        for line in sys.stdin:
            print(line, end='', file=fp)

finally:
    fp.close()

# Make the file executable else sbatch won't run it.
os.chmod(filename, 0o755)

executor = Executor(args.dryRun)

result = executor.execute('sbatch ' + filename)

if args.dryRun:
    print('\n'.join(executor.log))
else:
    print(result.stdout, end='')

if args.keep:
    print('sbatch script saved to %s' % filename)
else:
    os.unlink(filename)
