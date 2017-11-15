#! /bin/bash



for i in filea fileb;do
   echo $i
   ls -l $i
   cat $i




done




exit















function try () {



   echo "Hi"
   
    echo "inside function \"$1\" path \"$2\";"
   
echo "$2"
}



A="bye"

B="good luck"

 

try $A $B
