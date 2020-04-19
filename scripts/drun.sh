#!/bin/sh

cwd="$(pwd)/out/bin"

rm "$HOME/tsu"

cp "$cwd/tsu" "$HOME/tsu"

chmod +x "$HOME/tsu"

exec "$HOME/tsu"  "$@"