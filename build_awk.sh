#! /bin/bash

echo -n "awk '{print "
for i in {1..12};do

	echo -n "\$$i||"

done

echo "}'"
