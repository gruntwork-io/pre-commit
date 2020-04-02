#!/usr/bin/env python
import re
import sys
import argparse
import logging


logging.basicConfig(format='%(asctime)s [%(levelname)s] %(message)s', level=logging.INFO)


def has_setenv_skip(fpath):
    with open(fpath) as f:
        for line in f:
            if re.match(r'^\s+os.Setenv\(\"(SKIP_|TERRATEST_REGION)', line):
                return True
    return False


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            'A CLI for checking to make sure no uncommented os.Setenv calls are '
            'committed in test golang files. Each positional argument should be a golang source file.'
        ),
    )
    parser.add_argument(
        'files',
        metavar='FILE',
        type=str,
        nargs='+',
        help='The file to check.',
    )
    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    files_with_setenv_skip = [fpath for fpath in args.files if has_setenv_skip(fpath)]
    if files_with_setenv_skip:
        logging.error('Found files with os.Setenv calls setting terratest SKIP environment variables.')
        for f in files_with_setenv_skip:
            logging.error('- {}'.format(f))
        sys.exit(1)


if __name__ == '__main__':
    main()
