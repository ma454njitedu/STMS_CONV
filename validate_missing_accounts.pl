#! /usr/bin/perl -w
 
use strict;
use lib ('/home/conversion');
use billing_routines qw( get_data_type binary_search get_index_data );

chomp (my $DIR = `pwd`);
my @error_files = `find . -name validate_mstr\*_in_data.log -size +0`;
my @missing_acct;
chomp(@error_files);
#my %data_type;
#my $data_type;
my $data_type = get_data_type;

open (OUTFILE, ">$DIR/data/output/validate_missing.dat") || die "can't open OUTFILE $!\n";
open (LOGFILE, ">$DIR/data/logs/validate_missing.log") || die "can't open LOGFILE $!\n";


foreach my $error_file (@error_files) {
        (my $key = $error_file) =~ s/.*validate_mstr_(.*)_(source|target).*/$1/;
#        $data_type = get_data_type($key);
#        $data_type = $data_type{$key};
	print "data type is $data_type->{$key}  for $key\n";

	&print_msg ("key $key	$error_file");

        ($key =~ /EDW_BBNMS_0010/)  && &check_other_files($key, $error_file, 'EDW_CUST_0010,EDW_UDAS_0100','N','N');
        ($key =~ /RIO_MEMO_0400/)   && &check_other_files($key, $error_file, 'RIO_MEMO_0410','N','N');
        ($key =~ /EDW_UDAS_0100/)   && &check_other_files($key, $error_file, 'EDW_CUST_0010,EDW_BBNMS_0010','N','N');
##        ($key =~ /TAOS_CUST_0070/)  && &check_other_files($key, $error_file, 'TAOS_CUST_0075','N','N');
##        ($key =~ /TAOS_CUST_0075/)  && &check_other_files($key, $error_file, 'TAOS_CUST_0070','N','N');
        ($key =~ /RIO_BBNMS_0040/)  && &check_other_files($key, $error_file, 'STMS_BBNMS_0040','Y','N');
##        ($key =~ /RIO_UDAS_0010/)   && &check_other_files($key, $error_file, 'RIO_MEMO_0400','Y','N');
##        ($key =~ /EDW_CUST_0010/)   && &check_other_files($key, $error_file, 'STMS_CUST_0010','Y','N');
        ($key =~ /RIO_BBNMS_0030/)  && &check_other_files($key, $error_file, 'STMS_BBNMS_0030','Y','N');
        ($key =~ /STMS_INVC_0160/)  && &check_other_files($key, $error_file, 'STMS_INVC_0110', 'Y','Y',21,'TAX_AMOUNT'); 
        ($key =~ /STMS_INVC_0140/)  && &check_other_files($key, $error_file, 'STMS_INVC_0110', 'Y','Y',19,'PREV_BALANCE'); 
        ($key =~ /STMS_BDS_0040/)   && &check_other_files($key, $error_file, 'STMS_INVC_0120', 'Y','Y',13,'SERVICE_CODE'); 

}

close OUTFILE;
close LOGFILE;

###########################################################################################################################

sub check_other_files {
    my ($_in_key, $_in_file_name, $_in_outfile_keys, $_in_should_be_found, $_in_special, $_in_col_num, $_in_col_name) = @_;
    my $_match_sub;
    my @_outfile_keys = split /,/,$_in_outfile_keys;
    my $_acct;
    my $err = "";

    my @missing_acct = `cat $_in_file_name`;
    chomp @missing_acct;

    foreach my $_outfile_key (@_outfile_keys) {
#       `$DIR/build_index.pl ${_outfile_key}`;
       get_index_data($_outfile_key); 
       my @_compare_file = `cat $DIR/data/${_outfile_key}_INDX | sed 's/,.*//' `;
       chomp @_compare_file;

       foreach $_acct (@missing_acct) {
          $_match_sub = binary_search(\@_compare_file,$_acct);

#	 print "match data $_match_sub\n"; 
          if ( $_match_sub  &&  $_in_special eq 'Y') { 
             my $spcl_err = &check_for_special($_in_key, $_outfile_key, $_acct, $_in_col_num, $_in_col_name, $_match_sub);
	     $err = 'Y' if $spcl_err eq 'Y';
	  }elsif ( $_match_sub  &&  $_in_should_be_found eq 'N') { 
             &print_msg ("	ERROR: account $_acct is missing in $_in_key, but it is present in $_outfile_key"); 
	     print LOGFILE "$_match_sub\n";
             $err = 'Y';
	  }elsif ( ! $_match_sub  &&  $_in_should_be_found eq 'Y') { 
             &print_msg ("	ERROR: account $_acct is missing in $_in_key, and it is missing in $_outfile_key"); 
	     print "match_sub $_match_sub\n";
	     print LOGFILE "$_match_sub\n";
             $err = 'Y';
          }
       }

       if ( ! $err  &&  $_in_should_be_found eq 'Y') { 
          &print_msg ("	OK: All missing accounts from log file $_in_key are found in $_outfile_key");
       }elsif ( ! $err  &&  $_in_should_be_found eq 'N') { 
          &print_msg ("	OK: All missing accounts from log file $_in_key are also missing in $_outfile_key");
       }
       $err = "";
    }
    &print_msg ("");
}


sub check_for_special {
    my ($_infile_key, $_outfile_key, $_missing_acct, $_col_num, $_col_name, $_match_sub) = @_;

#      REPORT ERRORS:
#      if present in STMS_INVC_0110 and TAX_AMOUNT > 0
#      if present in STMS_INVC_0110 and PREV_BALANCE > 0
#      if present in STMS_INVC_0120 and substr SERVICE_CODE = 'F'

    my $_err='';
    my @_match_data;
#    my @_data_file_accts = `cat $DIR/data/$data_type/${_outfile_key}*`;
    my @_data_file_accts = `cat $DIR/data/$data_type->{$_outfile_key}/${_outfile_key}*`;
    my $_value = 0.00;
    @_match_data = grep { $_ =~ /\|\|$_missing_acct\|\|/ } @_data_file_accts;


    if ($_infile_key eq 'STMS_BDS_0040' ) {
       foreach (@_match_data) {
          my @_data_row = split /\|\|/,$_;
          $_value = substr($_data_row[$_col_num],0,1);
	  if ($_value eq 'F') {
             &print_msg ("	ERROR: Account $_missing_acct is missing in $_infile_key but has a $_col_name value of $_data_row[$_col_num] in $_infile_key which should not begin with 'F'");
	     $_err = 'Y';
          }
       }
       return "Y" if $_err eq 'Y';

    }elsif ($_infile_key eq 'STMS_INVC_0160'  ||  $_infile_key eq 'STMS_INVC_0140') {

       foreach (@_match_data) {
          my @_data_row = split /\|\|/,$_;
          $_value += $_data_row[$_col_num];
       }
 
       if ( $_value > 0 ) {
          &print_msg ( "	ERROR: Account $_missing_acct is missing in $_infile_key but has a $_col_name of $_value in $_infile_key which should be 0");
          print LOGFILE "@_match_data";
          return "Y";
       }
    }

}

sub print_msg {
    my $_msg = shift @_;

    print "$_msg\n";
    print OUTFILE "$_msg\n";
    print LOGFILE "$_msg\n";
}

