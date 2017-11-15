#! /bin/bash

ls -1 validate_columns* | sed 's/validate_columns_//' | sed 's/_/-/2' | sed 's/-.*//' | sort -u | while read i;do

echo $i

cat validate_columns_$i* > R1M4x_$i

rm validate_columns_$i*
echo ""






done
