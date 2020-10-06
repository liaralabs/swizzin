#!/bin/bash

if [[ ! -f /install/.scrutiny.lock ]]; then
  echo "Scurtiny doesn't appear to be installed. What do you hope to accomplish by running this script?"
  exit 1
fi

bash /etc/swizzin/scripts/remove/scrutiny.sh

bash /etc/swizzin/scripts/install/scrutiny.sh