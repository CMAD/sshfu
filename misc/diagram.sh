#!/bin/sh

if [ $# != 1 ]; then
  echo "Usage sshfu_diagram diagram.png"
  exit 1
fi

{
echo "digraph routes {"
cat ~/.ssh/sshfu/routes | sed -E \
  -e '/^#/d;/^$/d' \
  -e 's/host ([^ ]+)/"\1"/' \
  -e 's/gw ([^ ]+)/-> "\1"/' \
  -e 's/(user|key|port|address) [^ ]+ ?//g' \
  -e 's/$/;/'
echo "}"
} | dot -Tpng > "$1"

