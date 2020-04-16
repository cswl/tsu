#!/bin/bash

TERMUX_INSTALL="$1"

if [ -z "$TERMUX_INSTALL" ]; then
    ON_DEVICE=1
    INSTALL="$PWD/out"
else
   INSTALL="$TERMUX_INSTALL"
fi 

cmake -Hlibs/docopt -Bbuild/docopt -DCMAKE_INSTALL_PREFIX=$INSTALL

cmake --build build/docopt --target install

cmake -Hsrc/ -Bbuild/tsu/ -DCMAKE_INSTALL_PREFIX=$INSTALL -DCMAKE_PREFIX_PATH=$INSTALL

cmake --build build/tsu --target install