#! /usr/bin/perl -w 

use strict;

my $data_type = 'source';
chomp (my $DIR=`pwd`);
chomp (my $file_name_key = $ARGV[0]);
chomp (my $common_data = `grep $file_name_key $DIR/data/common/list_source_filenames.txt`);
(my $acct_col = $common_data) =~ s/.*,(.*),.*,.*/$1/;

$acct_col--;  
my @file_names = `ls -1 $DIR/data/$data_type/$file_name_key* `;


open (INDX,">$DIR/data/${file_name_key}_TMP") || die "can't open file $!\n";

foreach my $file_name (@file_names) {
   my $cntr=0;
   chomp $file_name;
   print "$file_name_key $file_name $common_data $acct_col\n";
   my @file_name_data = `cat $file_name`;
   foreach (@file_name_data) {
      chomp $_;
      my @col = split /\|\|/,$_;
      print INDX "$col[$acct_col],$cntr,$file_name\n";
      $cntr++;
   }
}

`sort -t"," -k1,1n -k2,2n -k3,3  $DIR/data/${file_name_key}_TMP > $DIR/data/${file_name_key}_INDX`;
unlink "$DIR/data/${file_name_key}_TMP";

close INDX;
