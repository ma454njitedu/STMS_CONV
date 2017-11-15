#! /bin/bash

target='/home/conversion/data/storage/TEST/source'
target='/cygdrive/s/ProcessedFiles'
if find "$target" -mindepth 1 -print -quit | grep -q .; then
    echo not empty, do something
else
    echo The directory $target is empty '(or non-existent)'
fi
