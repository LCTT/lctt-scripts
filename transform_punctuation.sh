#!/bin/bash
sed -i 's/,[[:blank:]]*/，/g' "$@"
sed -i 's/?[[:blank:]]*/？/g' "$@"
sed -i 's/![[:blank:]]*/！/g' "$@"
sed -i 's/\.[[:blank:]]+/。/g' "$@"
sed -i 's/\.$/。/g' "$@"
sed -i 's/\.\([^[:alpha:][:blank:][:cntrl:][:punct:][:digit:]]\)/。\1/g' "$@"
