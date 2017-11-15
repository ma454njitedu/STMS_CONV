#! /usr/bin/perl -w
use strict;
use Getopt::Long qw(GetOptions);
use Term::ANSIColor;
#
#	1. file find_accts.txt needs to have the accounts added to it
#	2. @dir_type needs to be modified for core, noncore, source
#

my $DEBUG = 0;
#my $search_type = 'X';

my $DIR=`pwd`;
my $DAT = `date '+%N'`;
my $start = `date '+%Y%m%d-%H%M%S'`;
chomp $DIR;
chomp $DAT;
chomp $start;

my $input_acct_file = "$DIR/data/accounts/find_accts.txt";

my $data_accts_by_key = "$DIR/data/output/find_accts_by_key_${start}.dat";
my $tmp_data_accts_by_key = "$DIR/data/find_accts_by_key_${start}.dat";


my %key_col;
my $common_key;
my $data_file_name;
my @common_data = ();
my @data_accts_by_file = ();
my @sorted_data_acct = ();
my @data_line = ();
my @sorted_data_line = ();
my @log_data = ();
my @sorted_log_data = ();
my $data_key;
my @input_acct = ();
my @tmp_acct = ();
my @dir_type = ();
my $file_name;
my $accts;
my $core;
my $noncore;
my $source;
my $err_cnt=0;

###########################################################################################

GetOptions(
        'f:s' => \$file_name,
        'a=s' => \$accts,
	'c'   => \$core,
	'n'   => \$noncore,
	's'   => \$source,
) or die &usage;


if (defined $file_name) {
    if ($file_name) {
       my @tmp_acct = `cat $file_name`;
       foreach (@tmp_acct){
           chomp $_;
            push @input_acct, sprintf("%09d",$_);
       }
    }else{
#       @tmp_acct = `cat $DIR/data/accounts/find_accts.txt`;
       @tmp_acct = `cat $input_acct_file`;
       foreach (@tmp_acct){
           chomp $_;
            push @input_acct, sprintf("%09d",$_);
       }
    }
}else{
    $err_cnt++;
}


if (defined $accts) {
   chomp $accts;
   my @tmp_acct = split(",",$accts);
   foreach (@tmp_acct) {
      push @input_acct, sprintf("%09d",$_);
   }
}else{
   $err_cnt++;
}


if ( ! $core && ! $noncore && ! $source) {
   $err_cnt = 2;
}else{
   push @dir_type,'core' if $core;
   push @dir_type,'noncore' if $noncore;
   push @dir_type,'source' if $source;
}

if ( $err_cnt != 1 ) {
   &usage;
}


   foreach (@input_acct) {
      print "$_\n";
}
   foreach (@dir_type) {
      print "$_\n";
}


###########################################################################################

open (TMPFILE, ">$tmp_data_accts_by_key") || die "can't open out_acct_file.dat $!\n";
open (LOGFILE, ">$DIR/data/logs/find_accts_${start}.log") || die "can't open out_acct_file.dat $!\n";

foreach my $_dir_type (@dir_type) {
   @common_data = `cat "$DIR"/data/common/list_${_dir_type}_filenames.txt` ;

   &build_acct_col_hash;
   
   foreach (@common_data) {
      print "foreach common file\n" if ( $DEBUG == 1 );
      my @_data_files = ();
#      (my $_common_key = $_) =~ s/,.*//;
      my ($_common_key, $acct_col) = split /,/,$_;
      $acct_col--;
      @_data_files = `ls -1 $DIR/data/$_dir_type/$_common_key*`;
      chomp @_data_files;

      foreach (@_data_files) {
         chomp $_;
         ($data_file_name = $_) =~ s/.*\///;
         my @_data_rows = `cat $_`;
         foreach my $data_row (@_data_rows) {
	    chomp $data_row;
	    my @data_cols = split /\|\|/,$data_row;
            (my $acct_num  = $data_cols[$acct_col]) =~ s/ //g;
	    my $data_line = "$acct_num,$data_file_name,$data_row";
#            print "==> $data_line\n";
	    push @data_accts_by_file, $acct_num;
            push @data_line, $data_line;
	 }
         print "------------------ end of file -------- $data_file_name\n";
      }
      @sorted_data_acct = sort @data_accts_by_file;
      @data_accts_by_file = ();
      @sorted_data_line = sort @data_line;
      @data_line = ();
      &find_acct;
      print "------------------ end of file key ---- $_common_key\n\n";
   }
}
close TMPFILE;

&process_log_file;

`cat $tmp_data_accts_by_key | sort > $data_accts_by_key`;

`rm $tmp_data_accts_by_key`;

my $finish = `date '+%Y%m%d-%H%M%S'`;
print "Start $start\n";
print "End   $finish\n";

###################### Subroutines #####################################################################

	
sub build_acct_col_hash {

    my $_acct_col;

    foreach my $_line (@common_data) {
       chomp($_line);
       ($common_key, $_acct_col) = split /,/,$_line;
       $key_col{$common_key} = $_acct_col;
    }
}



sub find_acct {
#   print "find_acct\n" if ( $DEBUG == 1 );
   foreach (@input_acct) {
      chomp $_;
      my $data_acct_sub = &binary_search(\@sorted_data_acct, $_);
      if ($data_acct_sub) {
##adh         print "$_ found in $data_file_name	[$data_acct_sub] $sorted_data_acct[$data_acct_sub]\n";
         print TMPFILE "$_ found in $data_file_name	[$data_acct_sub] $sorted_data_acct[$data_acct_sub]\n";
	 push @log_data,"$sorted_data_line[$data_acct_sub]$data_file_name\n";
      }else{
#         print "	acct $_ not found in $data_file_name\n";
      }
   }
}


sub binary_search {
#     print "binary search\n" if ( $DEBUG == 1 );
     my ($_sorted_data_acct, $_input_acct) = @_;
     my ($low, $high) = (0, @$_sorted_data_acct - 1);
     while ( $low <= $high ) {
#           print TMPFILE "low $low             high $high\n";
            my $try = int(($low + $high)/2);
            $low = $try+1, next if $_sorted_data_acct->[$try] lt $_input_acct;
            $high = $try-1, next if $_sorted_data_acct->[$try] gt $_input_acct;
            return $try;
     }
     return;
	
}


sub process_log_file {
    my $_prev_acct_no = "";

    @sorted_log_data = sort @log_data;
    @log_data = ();

    foreach (@sorted_log_data){
       chomp $_;
       my ($_acct_no, $_data, $_file) = split //,$_;
       if ( $_acct_no ne $_prev_acct_no ) {
           print LOGFILE "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
	   $_prev_acct_no = $_acct_no;
       }
       print LOGFILE "$_acct_no	$_file\n	$_data\n\n";
    }



}


sub usage {
   system("clear");
   print "\n\n";
   print "run with one of these options:                ";
   print colored ['yellow on_red'], "./find_accts.pl [ -c -n -s ] { (-f)  (-f file_name)  (-a actnum1,acctnum2,acctnumN) } ";
   print "\n\n\n";
   print "                                  |  -f             will use the default file $input_acct_file\n";
   print "                  Only one of     |  -f file_name   file_name must include the path ( ./file_name /home/conversion/file_name)\n";
   print "                                  |  -a acct_nbrs   comma separated acct numbers\n";
   print "\n";          
   print "                                  |  -c	core target\n";
   print "                  One or more of  |  -n	noncore target\n";
   print "                                  |  -s	source\n";
   print "\n\n\n";
   exit(1)
}

