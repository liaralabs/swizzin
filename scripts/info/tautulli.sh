#!/usr/bin/env bash

# TODO clashes with journalctl for panel...???
commands+=('journalctl -u tautuli')
paths+=("/opt/tautulli/logs/tautulli.log") # TODO is it?
