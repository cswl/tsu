#!/data/data/com.termux/files/usr/bin/sh

# Copyright (c) 2018, Cswl Coldwind <cswl1337@gmail.com
# This software is licensed under the ISC Liscense.
# https://github.com/cswl/tsu/blob/master/LICENSE.md

show_usage() {
  echo 'tsudo - run Termux commands as other users: default root'
  echo
  echo 'Usage: tsudo cmd'
}

# TODO: add ability to change user / group via:
# [-u user|-g group]
while getopts ':ug:' opt; do
  case $opt in
    u)
      REQ_USER=$OPTARG
      ;;
    g)
      REQ_GRP=$OPTARG
      ;;
  esac
done

test -z "$PREFIX" && PREFIX=/data/data/com.termux/files/usr

"$PREFIX/bin/tsu" -c "$@"
