#!/bin/bash
source base.sh

cd $(get-lctt-path)
git add .
git commit -m "update at $(date)"
git push

git checkout master
