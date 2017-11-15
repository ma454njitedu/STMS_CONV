#! /bin/bash

DIR=`pwd`

X='andy|'

for i in {1..3};do


sleep 5
cp find_accts.pl -c  test_$i.sh
chmod 777 test_$i.sh
mintty -h always $DIR/test_$i.sh &

done
echo "finished"
