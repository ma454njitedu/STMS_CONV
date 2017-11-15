#! /usr/bin/perl -w
#
#   this compares 2 files and lists items that are missing as well as what is in common
#
use strict;

my $debug = 0;
my $match_cnt=0;
my $in1not2_cnt = 0;
my $in2not1_cnt = 0;

open (FILE1, "<$ARGV[0]") || die "can't find file $ARGV[0] $!\n";
open (FILE2, "<$ARGV[1]") || die "can't find file $ARGV[1] $!\n";
open (T1, ">in1not2.csv") || die "can't find file $ARGV[0] $!\n";
open (T2, ">in2not1.csv") || die "can't find file $ARGV[1] $!\n";
open (T3, ">inboth.csv") || die "can't find file $ARGV[1] $!\n";

my @file1 = sort (<FILE1>);
my @file2 = (<FILE2>);

my $sub1 = 0;
my $sub2 = 0;
my $last1=$#file1;
my $last2=$#file2;
close FILE1;
close FILE2;




while ($sub1 <= $last1 && $sub2 <= $last2) {
   chomp $file1[$sub1];
   chomp $file2[$sub2];
   if ($debug == 1) {print "==> file1 $file1[$sub1] file2 $file2[$sub2]  sub1 $sub1  sub2 $sub2  last1 $last1 last2 $last2 ";}

   if ($file1[$sub1] eq $file2[$sub2]) {
       if ($debug == 1) {print "match $file1[$sub1] $file2[$sub2]\n";}
       print T3 "$file1[$sub1]\n";
       $match_cnt++;
       $sub1++;
       $sub2++;
   }elsif ($file1[$sub1] gt $file2[$sub2]) {
       if ($debug == 1) {print "write T2 $file2[$sub2]\n";}
       $in2not1_cnt++;
       print T2 "$file2[$sub2]\n";
       $sub2++;
   }else{
       if ($debug == 1) {print "write T1 $file1[$sub1]\n";}
       $in1not2_cnt++;
       print T1 "$file1[$sub1]\n";
       $sub1++;
   }
}

while ($sub1 <= $last1) {
       chomp $file1[$sub1];
       if ($debug == 1) {print "write T1 $file1[$sub1]\n";}
       print T1 "$file1[$sub1]\n";
       $in1not2_cnt++;
       $sub1++;
}

while ($sub2 <= $last2) {
       chomp $file2[$sub2];
       if ($debug == 1) {print "write T2 $file2[$sub2]\n";}
       print T2 "$file2[$sub2]\n";
       $in2not1_cnt++;
       $sub2++;
}

print "Total Rows matched:			$match_cnt\n";
print "Total Rows from file 1 not in file 2: 	$in1not2_cnt\n";
print "Total Rows from file 2 not in file 1: 	$in2not1_cnt\n";

close T1;
close T2;
close T3;
