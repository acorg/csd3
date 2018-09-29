#!/usr/bin/env python

import sys
import os
from os.path import basename
from tempfile import mkstemp
import argparse

from dark.process import Executor


parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='Run commands using sbatch')

parser.add_argument(
    'args', nargs='*',
    help='The command to run')

parser.add_argument(
    '--exclusive', action='store_true', default=False,
    help='If given, run on an exclusive machine.')

parser.add_argument(
    '--dryRun', action='store_true', default=False,
    help=('If given, do not actually execute the sbatch script. '
          'Implies --keep.'))

parser.add_argument(
    '--keep', action='store_true', default=False,
    help='If given, keep the sbatch submission file and print its path.')

parser.add_argument(
    '--job', default=basename(sys.argv[0]),
    help='The job id passed with -J to sbatch.')

parser.add_argument(
    '--account', default='ACORG-SL2-CPU',
    help='The account name, passed with -A to sbatch.')

parser.add_argument(
    '--out', default='slurm-%A.out',
    help='The SLURM output file name, passed with -o to sbatch.')

parser.add_argument(
    '--partition', default='skylake',
    help='The SLURM partition, passed with -p to sbatch.')

parser.add_argument(
    '--time', default='1:00:00',
    help='The SLURM time limit, passed with --time to sbatch.')

args = parser.parse_args()

if args.dryRun:
    args.keep = True

(fd, filename) = mkstemp(prefix='sbatch-commands-', suffix='.txt', text=True)
fp = os.fdopen(fd, 'w')

try:
    print('#!/bin/bash -e', file=fp)
    print('#SBATCH -J', args.job, file=fp)
    print('#SBATCH -A', args.account, file=fp)
    print('#SBATCH -o', args.out, file=fp)
    print('#SBATCH -p', args.partition, file=fp)
    print('#SBATCH --time=%s' % args.time, file=fp)
    if args.exclusive:
        print('#SBATCH --exclusive', file=fp)

    print(file=fp)

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

executor.execute('sbatch ' + filename)

if args.dryRun:
    print('\n'.join(executor.log))

if args.keep:
    print('sbatch script saved to %s' % filename)
else:
    os.unlink(filename)
