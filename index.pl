#! /usr/bin/perl -w
#
use strict;

chomp(my $DIR = `pwd`);
my $key = 'STMS_INVC_0110';


my @files = `sort -t"|" -k7,7n $DIR/data/source/$key*`;



foreach my $file (@files) {
    chomp $file;
    print "$file\n";



}
