#! /bin/perl -w
use strict;

my $DIR = `pwd`;
chomp $DIR;
my $filename = $ARGV[0];

if ( ($#ARGV + 1) == 0) {
   print "ERROR: must run program with RMS filename to convert\n";
   exit;
}

#@file_dir = ('core', 'noncore', 'source');
my @file_dir = ('source');
(my $file_key = $filename) =~ s/_20.*$//;



print "$file_key	$filename\n";


foreach my $file_dir (@file_dir) {

print "$file_dir	$filename\n";
print "$DIR/data/$file_dir/$filename $DIR/data/storage/${filename}_ORIG\n";

   rename "$DIR/data/$file_dir/$filename", "$DIR/data/storage/${filename}_ORIG";
   open (INFILE, "<$DIR/data/storage/${filename}_ORIG") || die "can't find file $DIR/data/storage/${filename}_ORIG $!\n";
   open (OUTFILE, ">$DIR/data/$file_dir/${filename}") || die "can't create file $DIR/data/$file_dir/${filename} $!\n";
   my @data_row = (<INFILE>);
   close INFILE;

   if ( $file_key eq 'RMS_ETRACS_0010' ) {
      foreach (@data_row) {
          chomp $_;
          $_ =~ s/ +/,/;
	  my $aci = substr($_,0,1);
          my($in_acct,$rest_of_row) = split /,/,$_;
             $in_acct =~ s/^.//;
          my $acct = sprintf("%09d", $in_acct);
	  my $coll_dt = substr($rest_of_row,0,8);
	  my $oca_dt = substr($rest_of_row,8,8);
             $oca_dt = '20000101' if $oca_dt eq '00000000';
	  my $oca_stat = substr($rest_of_row,16,3);
	  my $oca_id = substr($rest_of_row,19,4);
	  my $oca_stat_dt = substr($rest_of_row,23,8);
	  my $prev_oca_stat = substr($rest_of_row,31,4);
	  my $prev_oca_id = substr($rest_of_row,35,4);
	  my $rms_stat = substr($rest_of_row,39,3);
	  my $str_inst_cd = substr($rest_of_row,42,4);
 	  my $write_off = substr($rest_of_row,46,13);

          $coll_dt = '19000101' if $coll_dt eq '00000000';
	  $write_off =~ s/^.//;

print OUTFILE "RMS||0010||||||||||$acct   ||||$aci||||||||||||||||||||||||||$coll_dt||||||||||||||||||||||||||||||||||||||||||||||$oca_dt||$oca_stat||$oca_id||$oca_stat_dt||||||||||||||||||$prev_oca_stat||||$prev_oca_id||||||$rms_stat||||||||||||||||||||||||$str_inst_cd    ||||||||||||||||||$write_off||||\n";

     }

   }elsif ( $file_key eq 'RMS_ETRACS_0030' ) {
      foreach (@data_row) {
          chomp $_;
          $_ =~ s/ +/,/;
          my($in_acct,$rest_of_row) = split /,/,$_;
          my $acct = sprintf("%09d", $in_acct);
	  my $actvy_dt = substr($rest_of_row,0,8);
	  my $hist_txt = substr($rest_of_row,8);
	  my $hist_txt_100 = sprintf "%-100s", $hist_txt;
#  print "$hist_txt	-$hist_txt_100- \n";
          print "RMS||0030||$acct           ||||$actvy_dt||$hist_txt_100||\n";
          print OUTFILE "RMS ||0030||$acct           ||||$actvy_dt||$hist_txt_100||\n";
      }
   }else{
 
      print "						INVALID FILE NAME $filename\n";

   }

}

close OUTFILE;
