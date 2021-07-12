#!/usr/bin/env bash

paths+=('/var/log/apt/history.log')
paths+=('/var/log/dpkg.log')
paths+=('/etc/apt/sources.list')
paths+=(/etc/apt/sources.list.d/*)
version+=("$(apt --version | cut -d' ' -f2)")
