#! /usr/bin/perl
#
use strict;
use warnings;
#use billing_routines qw( build_index );

chomp (my $DIR=`pwd`);

my $key = 'RIO_CUST_0075';

my $prev_acct  = 0;
my $cntr       = 0;
my $cntr_sufix = 0;;
my $acct_col   = `grep $key $DIR/data/common/list_source_filenames.txt | cut -d, -f2`;
my @indx_data  = `cat $DIR/data/source/${key}* |sed 's/\|\|//g' | sort --parallel=4 -S 75% -n -t"" -k${acct_col}`;
my @indx_key   = ();
chomp @indx_data;

$acct_col--;

foreach (@indx_data) {
   my @cols = split //,$_;
   if ($cols[$acct_col] == $prev_acct) {
       $cntr_sufix = sprintf("%03d", ++$cntr);
   }else{
       $prev_acct = $cols[$acct_col];
       $cntr_sufix = '000';
       $cntr = 0;
   }
   $cols[$acct_col] .= $cntr_sufix;
   push @indx_key, $cols[$acct_col];
}

#print "$indx_key[415]	$indx_data[415]\n";
#print "$indx_key[416]	$indx_data[416]\n";
#print "$indx_key[417]	$indx_data[417]\n";
#print "$indx_key[418]	$indx_data[418]\n";
#print "$indx_key[419]	$indx_data[419]\n";
#print "$indx_key[420]	$indx_data[420]\n";
#print "$indx_key[421]	$indx_data[421]\n";
#print "$indx_key[422]	$indx_data[422]\n";
#print "$indx_key[423]	$indx_data[423]\n";
#print "$indx_key[424]	$indx_data[424]\n";
#print "$indx_key[425]	$indx_data[425]\n";
#print "$indx_key[426]	$indx_data[426]\n";
#print "$indx_key[427]	$indx_data[427]\n";
#print "$indx_key[428]	$indx_data[428]\n";
#print "$indx_key[429]	$indx_data[429]\n";
#print "$indx_key[430]	$indx_data[430]\n";
#print "$indx_key[431]	$indx_data[431]\n";
#print "$indx_key[432]	$indx_data[432]\n";
#print "$indx_key[433]	$indx_data[433]\n";
#print "$indx_key[434]	$indx_data[434]\n";
#print "$indx_key[435]	$indx_data[435]\n";
#print "$indx_key[436]	$indx_data[436]\n";
#print "$indx_key[437]	$indx_data[437]\n";
#print "$indx_key[438]	$indx_data[438]\n";
#print "$indx_key[439]	$indx_data[439]\n";
