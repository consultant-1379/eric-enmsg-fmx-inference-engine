#!/bin/bash

if [ -f "/var/tmp/init_complete.txt" ]; then
    exit 0
else
    exit 1
fi
