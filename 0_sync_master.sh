#!/bin/bash
set -e
source base.sh

cd $(get-lctt-path)
git fetch LCTT
git pull LCTT master
