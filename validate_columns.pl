#! /usr/bin/perl -w
#
# executeion is:         ./vaidate_columns.pl file_name   or use ./validate_columns.sh (to execute against multiple files_names)
#
#
# step1. loop through files
#        determine the file location
#        determine map name from each file and load that map into array
#        load file data into an array
# step2. loop through data rows
#        check for ending delimiters (||)
#        check that number of data columns match number of map columns
#        check for duplicates
# step3. loop through each column against the map
#        check if column rec_type matches the map rec_type
#        check if column is mandatory based on source system
#        check if column matches maps valid values
#        check if column must be an exact size other then map size (ex. account_numbers)
#        check if column length is within map format range
#        validate date, datetime, and datetimestamp
#        validate data does not contain non printable characters
#        validate numeric data, with or without decimals and +/-
# 
#        program creates log file
#        program creates output error file
#
#
#
# MODIFICATION HISTORY:
#	20170905 #1  modified dup check to now include MEMO_0400 
#
#
 
use strict;

my $debug = 'N';

my $NET_DIR='/cygdrive/y/Data/FileTransfer-2017-01-27';
my $DIR = `pwd`;
chomp $DIR;
my @col_val;
my $num_cols;
my $err_msg;
my $err_cnt = 0;
my $row;
my $trail_delim = 1;
my $tot_cols = 16;
my $file_name = $ARGV[0];
my $DAT = `date '+%Y%m%d-%H%M%S'`;
chomp $DAT;
my $file_type;
chomp $file_name;
my $data_row_cnt = 0;
my $data_row;
my @data_row;
my %its_a_dup;
my $file_rec_type;
my $file_name_rec_type_seq;
my $file_name_rec_type;
my $num_map_cols;
my $start_dt=`date`;
chomp $start_dt;

#$DAT='X';

my %file_type= (
   'CUST'  => 'core',
   'EVNT'  => 'core',
   'INVC'  => 'core',
   'MEMO'  => 'core',
   'BBNMS' => 'noncore',
   'BDS'   => 'noncore',
   'CCDM'  => 'noncore',
   'ECDW'  => 'noncore',
   'EDGE'  => 'noncore',
   'ORACLE11I'  => 'noncore',
   'UDAS'       => 'noncore',
   'EDW_BBNMS'  => 'source',
   'EDW_CCDM'   => 'source',
   'EDW_CUST'   => 'source',
   'EDW_ECDW'   => 'source',
   'EDW_UDAS'   => 'source',
   'RIO_BBNMS'  => 'source',
   'RIO_CUST'   => 'source',
   'RIO_EDGE'   => 'source',
   'RIO_MEMO'   => 'source',
   'RIO_UDAS'   => 'source',
   'STMS_BBNMS' => 'source',
   'STMS_BDS'   => 'source',
   'STMS_CUST'  => 'source',
   'STMS_EVNT'  => 'source',
   'STMS_INVC'  => 'source',
   'STMS_UDAS'  => 'source',
   'TAOS_CUST'  => 'source',
   'TRS_INVC'   => 'source',
   'TRS_CUST'   => 'source',
);
	
my %last_day = (
   '01' => '31',
   '02' => '28',
   '03' => '31',
   '04' => '30',
   '05' => '31',
   '06' => '30',
   '07' => '31',
   '08' => '31',
   '09' => '30',
   '10' => '31',
   '11' => '30',
   '12' => '31',
);

#======================================== Main Loop ==================================================================


my ($map_name, $source) = &determine_map_name($file_name);
my @map_file = &get_map_file ($map_name);


open (RPT_FILE, ">>$DIR/data/output/validate_columns_${file_name_rec_type_seq}-${DAT}.csv") || die "can't find file $file_name in $DIR/data/ $!\n";
open (FILENAME, "<$DIR/data/$file_type/$file_name") || die "can't find file $file_name in $DIR/data/ $!\n";
my @file_row = (<FILENAME>);
close FILENAME;

print RPT_FILE "\n$file_name,start time: $start_dt\n";

foreach (@file_row) {
   print LOG_FILE "\n-----------------------------------------------\n" if ( $debug eq 'Y' );
   print LOG_FILE"===============================================\n" if ( $debug eq 'Y' );
   print LOG_FILE "-----------------------------------------------\n" if ( $debug eq 'Y' );
   $data_row_cnt++;
   print LOG_FILE "row count => $data_row_cnt\n" if ( $debug eq 'Y' );

   if ( $_ =~ /\|\|$/) {
      $_ =~ s/\|\|$//;
   }else{
      &error_process ($data_row_cnt,"N/A", "Missing delimiter(||) at end of file");
   }


   @data_row = split /\|\|/,$_;
   my $num_data_cols = @data_row;
   my $cnt = 0;

   my $check_for_dups = &special_handling (2,$file_name_rec_type);

   if ( 'Y' eq $check_for_dups ) {
      if ( $its_a_dup{$_}++ ) {
         my $partial_data = substr($_,0,50);
         chomp $partial_data;
         &error_process ($data_row_cnt, "N/A", "duplicate row (${partial_data}...)");
      }
   }

#   @data_row = split /\|\|/,$_;
#   my $num_data_cols = @data_row;
#   my $cnt = 0;


   my ($map_col_name, $map_col_mand, $map_col_format, $map_col_valid_val, $map_col_src_system, $map_col_spec_length);
   my $data_col;
    
   if ($num_map_cols == $num_data_cols) {
       foreach $data_col (@data_row) {
          ($map_col_name, $map_col_mand, $map_col_format, $map_col_valid_val, $map_col_src_system, $map_col_spec_length) = split /	/,$map_file[$cnt];
          chomp  $map_col_spec_length;
#	  if ('AMT_IND' ne $map_col_name && 'ORIG_AMT_IND' ne $map_col_name) {
	  if ($data_col !~ m/^ +$/) {
             $data_col =~ s/^ +//;
             $data_col =~ s/ +$//;
          }
          print LOG_FILE "--------- Start New Column -------------------------------------------------------------------------------\n\n" if ( $debug eq 'Y' );
          print LOG_FILE "-${data_col}- $map_col_name, $map_col_mand, $map_col_format, $map_col_valid_val, $map_col_src_system, ${map_col_spec_length}\n" if ( $debug eq 'Y' );
          $cnt++;
          (my $map_col_format_type = $map_col_format) =~ s/\(.*//;
          (my $map_col_format_size = $map_col_format) =~ s/^.*\((.*)\).*$/$1/;
          chomp $map_col_format_size;
          chomp $data_col;

          if ($map_col_mand eq 'Y' && $source ne "") {
             $map_col_mand = &validate_mandatory_value($map_col_src_system, $map_col_name);
          }

          if ($map_col_name eq 'RECORD_TYPE' ) {
             &validate_rec_type($data_col, $map_col_name); 
#	  }elsif ($map_col_valid_val ne "" && $map_col_mand eq 'Y') {
	  }elsif ($map_col_valid_val) {
             &validate_valid_value($data_col,$map_col_name, $map_col_valid_val, $map_col_mand);
             print LOG_FILE "valid_val\n" if ( $debug eq 'Y' );
          }elsif ($map_col_spec_length > 0) {
             &validate_numeric_data($data_col,$map_col_name, $map_col_spec_length, "Y", $map_col_mand, $map_col_valid_val);
             print LOG_FILE "$map_col_format_type $map_col_format_size\n" if ( $debug eq 'Y' );
             print LOG_FILE "specific value\n" if ( $debug eq 'Y' );
          }elsif ( $map_col_format =~ "DATE") {
             &validate_date($data_col,$map_col_name, $map_col_format_type, "Y", $map_col_mand, $map_col_valid_val);
             print LOG_FILE "$map_col_format_type $map_col_format_size\n" if ( $debug eq 'Y' );
             print LOG_FILE "date\n" if ( $debug eq 'Y' );
          }elsif ( $map_col_format =~ "CHAR") {  
             &validate_alphanumeric_data($data_col,$map_col_name, $map_col_format_size, "N", $map_col_mand, $map_col_valid_val);
             print LOG_FILE "$map_col_format_type $map_col_format_size\n" if ( $debug eq 'Y' );
             print LOG_FILE "char\n" if ( $debug eq 'Y' );
          }elsif ( $map_col_format =~ "NUMBER" || $map_col_format =~ "DECIMAL") {
             &validate_numeric_data($data_col,$map_col_name, $map_col_format_size, "N", $map_col_mand, $map_col_valid_val);
             print LOG_FILE "$map_col_format_type $map_col_format_size\n" if ( $debug eq 'Y' );
          }else{
             print LOG_FILE "ERROR ????\n" if ( $debug eq 'Y' );
             &error_process ($data_row_cnt, $map_col_name, "CODE ISSUE: Unknown data format($map_col_format)");
          }

          &special_handling (4, $map_col_name, $data_col);
       }
   }else{
         &error_process ($data_row_cnt,"N/A", "Data columns($num_data_cols) does not match map columns($num_map_cols)");
   }

#   &special_handling (4, $map_col_name, $data_col);

   print LOG_FILE "\n" if ( $debug eq 'Y' );

}

my $end_dt=`date`;
print LOG_FILE "$err_cnt Errors	end time: $end_dt\n" if ( $debug eq 'Y' );
print RPT_FILE "$err_cnt Errors\n";
close LOG_FILE;

#========================================= subroutines begin here ===============================================

sub special_handling () {
    print LOG_FILE "\nsub special_handling\n" if ( $debug eq 'Y' ); 
    print LOG_FILE "================\n" if ( $debug eq 'Y' ); 
    my ($_test_number, $_value0, $_value1) = @_;

    if (1 == $_test_number) {
       my $_map_col_name = $_value0; 
       chomp $data_row[-1];

       if ('B' ne $data_row[-1] && $file_name_rec_type =~ "INVC_0110" && ($_map_col_name eq 'COVERAGE_PERIOD_START_DATE' || $_map_col_name eq 'COVERAGE_PERIOD_END_DATE' || $_map_col_name eq 'INV_DUE_DATE')) {
          print LOG_FILE "$file_name_rec_type	$_map_col_name column is NOT mandatory becasue Billed_indicator is $data_row[-1]\n\n"   if ( $debug eq 'Y' );
          return 'N';
       }else{
          return 'Y';
       } 

    }elsif (2 == $_test_number) {
#      don't check for dups if the following is true
       my $_file_name_rec_type = $_value0;

#1       if ($_file_name_rec_type =~ 'MEMO_0400' || 'RIO_BBNMS_0040' eq $_file_name_rec_type || 'RIO_BBNMS_0050' eq $_file_name_rec_type) {
       if ('RIO_BBNMS_0040' eq $_file_name_rec_type || 'RIO_BBNMS_0050' eq $_file_name_rec_type || $_file_name_rec_type =~ "UDAS_0(090|140|170|180)") {
          return 'N';
       }elsif ($_file_name_rec_type =~ 'INVC_0160' && $data_row[-3] =~ 'F-' ) { 
	      print  LOG_FILE "N dup check $data_row[-3]\n" if ($debug eq 'Y');
          return 'N';
       }else{ 
	      print  LOG_FILE "Y dup check $data_row[-3]\n" if ($debug eq 'Y');
          return 'Y';
       }

#1       print LOG_FILE "	test number $_test_number Dont Test for Dups if: MEMO_400, RIO_BBNMS_0040 & 0050, also if INVC_0180 has 'F-' in column -3" if ($debug eq 'Y');
       print LOG_FILE "	test number $_test_number Dont Test for Dups if: RIO_BBNMS_0040 & 0050, also if INVC_0180 has 'F-' in column -3" if ($debug eq 'Y');


    }elsif (3 == $_test_number) {
#      use special map (with X for file_name_types that return 'S')
       my $_file_name_rec_type = $_value0;

       if ($_file_name_rec_type eq 'STMS_UDAS_0130' || $_file_name_rec_type eq 'STMS_UDAS_0140' || $_file_name_rec_type eq 'RIO_EDGE_0010' || $_file_name_rec_type eq 'TAOS_CUST_0070' || $_file_name_rec_type eq 'EVNT_0900') {
          return 'S';
       }

       print LOG_FILE "	test number $_test_number Use special map with acct_num if: STMS_UDAS_0140" if ($debug eq 'Y'); 

    }elsif (4 == $_test_number) {
#      validate IND = 'CR' if AMT < 0
       my $_map_col_name = $_value0; 
       my $_data_col = $_value1; 

       if ($file_name_rec_type =~ 'BDS_0020' || $file_name_rec_type =~ 'BDS_0030' || $file_name_rec_type =~ 'BDS_0040') {
	  my $_legacy_charge_id = $data_row[0];
	  my $_amt_ind = $data_row[7];
	  my $_orig_amt_ind = $data_row[9];

	  if ('AMT' eq $_map_col_name && $_data_col < 0 && $data_row[7] ne 'CR') {
             print LOG_FILE "A. $_test_number $_map_col_name ( $_data_col ) is < 0 but col-7 ( $_amt_ind ) ne CR \n" if ($debug eq 'Y');
             &error_process ($data_row_cnt,$_map_col_name, "$_map_col_name ( $_data_col ) is less than 0 but IND ( $_amt_ind ) is not CR ");
          }elsif ('ORIG_AMT' eq $_map_col_name && $_data_col < 0 && $data_row[9] ne 'CR') {
             print LOG_FILE "B. $_test_number $_map_col_name is < 0 but col-4 ( $_orig_amt_ind ) ne CR \n" if ($debug eq 'Y');
             &error_process ($data_row_cnt,$_map_col_name, "$_map_col_name ( $_data_col ) is less than 0 but IND ( $_orig_amt_ind ) is not CR ");
          }elsif ('AMT' eq $_map_col_name && $_data_col >= 0 && $data_row[7] ne '  ' && $data_row[7] ne ' ') {
             print LOG_FILE "C. $_test_number $_map_col_name ( $_data_col ) is > 0 but col-4 ( $_amt_ind ) ne blank \n" if ($debug eq 'Y');
             &error_process ($data_row_cnt,$_map_col_name, "$_map_col_name ( $_data_col ) is greater than 0 but IND ( $_amt_ind ) is not blank ");
          }elsif ('ORIG_AMT' eq $_map_col_name && $_data_col >= 0 && $data_row[9] ne '  ' && $data_row[9] ne ' ') {
             print LOG_FILE "D. $_test_number $_map_col_name ( $_data_col ) is > 0 but col-4 ( $_orig_amt_ind ) ne blank \n" if ($debug eq 'Y');
             &error_process ($data_row_cnt,$_map_col_name, "$_map_col_name ( $_data_col ) is greater than 0 but IND ( $_orig_amt_ind ) is not blank ");
          }elsif ('PURCHASE_ID' eq $_map_col_name && $file_name_rec_type =~ 'BDS_0030') {
  	     chomp $_data_col;
	     (my $_id_part = substr($_data_col,16)) =~ s/-//g;
             if ( 'CONVERTN-ONCO-RE' eq substr($_data_col,0,16)  && $_legacy_charge_id eq $_id_part ) {
                print LOG_FILE "Egood. $_test_number $_map_col_name ( $_data_col ) $_id_part  legacyChargeID $_legacy_charge_id\n" if ($debug eq 'Y');
	     }else{
                print LOG_FILE "Ebad. $_test_number $_map_col_name ( $_data_col ) idPart $_id_part  legacyChargeID $_legacy_charge_id\n" if ($debug eq 'Y');
                &error_process ($data_row_cnt,$_map_col_name, "$_map_col_name ( $_data_col ) does not match Legacy Charge ID ( $_legacy_charge_id )");
	     }
          }
       }
    }elsif (5 == $_test_number) {
#adh      remove leading/trailing spaces as well as multiple spaces while leaving single space from valid_values 
       my $_modified_data_col = $_value0; 
       
#       if ('CUST_0020' eq $file_name_rec_type ) {
       if ($file_name_rec_type =~ 'CUST_0020') {
          $_modified_data_col = ' ' if $_modified_data_col =~ '^ +$';
          if ($_modified_data_col ne ' ') {
             $_modified_data_col =~ s/ //g;
          }
       }
       return $_modified_data_col;
    }
}

	
sub validate_mandatory_value() {
    print LOG_FILE "\nsub validate_mandatroy_value\n" if ( $debug eq 'Y' ); 
    print LOG_FILE "================\n" if ( $debug eq 'Y' ); 

    my ($_map_col_src_system, $_map_col_name) = @_;

    if (! defined $_map_col_src_system) {
       $_map_col_src_system = "";
    }


    my $_map_col_mand = &special_handling(1, $_map_col_name);
    print LOG_FILE "AFTER spcl_hand	map_col_mand $_map_col_mand source = $source" if ($debug eq 'Y');
    if ($_map_col_mand eq 'N') {
       return 'N';
    }



    my @_map_targets = split /,/,$_map_col_src_system;
    foreach (@_map_targets) {
       print LOG_FILE "	map_col_mand $_map_col_mand source = $source compared with $_" if ($debug eq 'Y');
       if ( $source eq $_ || "" eq $_ ) {
          print LOG_FILE "	its mandatory" if ($debug eq 'Y');
	  return 'Y';
       }
    }
    print LOG_FILE "	its not mandatory" if ($debug eq 'Y');
    return 'N';
}


sub validate_rec_type{
    print LOG_FILE "\nsub validate_rec_type\n" if ( $debug eq 'Y' ); 
    print LOG_FILE "================\n" if ( $debug eq 'Y' ); 
    my ($_data_col,$_map_col_name) = @_; 

    if ( $_data_col ne $file_rec_type ) {
       &error_process ($data_row_cnt,$_map_col_name, "$_map_col_name $_data_col does not match $file_rec_type");
    }  
}

sub check_length () {
    print LOG_FILE "\nsub check_length\n" if ( $debug eq 'Y' ); 
    print LOG_FILE "================\n" if ( $debug eq 'Y' ); 
    my ($_data_col, $_map_col_name,$_map_col_format_size, $_exact_size_req) = @_;
    chomp $_data_col;

    my $_data_col_mod;

    ($_data_col_mod = $_data_col) =~ s/^ *[+|-]? *//;

    my $_length_data_col = length($_data_col_mod);

    print LOG_FILE "exact size=$_exact_size_req  len data col-$_length_data_col map_col_size-$_map_col_format_size\n" if ( $debug eq 'Y' );

    if ( $_exact_size_req eq "Y" && $_length_data_col != $_map_col_format_size) {
       &error_process ($data_row_cnt,$_map_col_name, "Data length $_length_data_col does not match exactly with map($_map_col_format_size)");
#    }elsif ($_length_data_col == 0 || $_length_data_col > $_map_col_format_size) {
    }elsif ($_length_data_col > $_map_col_format_size) {
       &error_process ($data_row_cnt,$_map_col_name, "$_data_col Data length $_length_data_col is not in range of map($_map_col_format_size)  $_data_col_mod");
    }


    print LOG_FILE "length of data is $_length_data_col\n" if ( $debug eq 'Y' );

}


sub validate_valid_value () {
    print LOG_FILE "\nsub validate_valid_value\n" if ( $debug eq 'Y' );
    print LOG_FILE "=================\n" if ( $debug eq 'Y' );
    my ($_data_col,$_map_col_name, $_map_col_valid_val, $_map_col_mand) = @_;
    chomp $_data_col;
# my $_modified_data_col = $_data_col;

    if ( $_map_col_mand eq 'Y' || $_data_col ) {

       my @_valid_value_array = split /,/,$_map_col_valid_val;
       my %_valid_value_hash  = map { $_ => 1 } @_valid_value_array;

#adh
       my $_modified_data_col = &special_handling (5,$_data_col);

       if (exists($_valid_value_hash{$_modified_data_col})) {
          print LOG_FILE "data is a valid value\n" if ( $debug eq 'Y' );
       }else{
          print LOG_FILE "data is NOT a valid value\n" if ( $debug eq 'Y' );
          &error_process ($data_row_cnt, $_map_col_name, "$_modified_data_col is not a valid value in ($_map_col_valid_val)");
       }
    }
}


sub validate_date () {
    print LOG_FILE "\nsub validate_date\n" if ( $debug eq 'Y' );
    print LOG_FILE "=================\n" if ( $debug eq 'Y' );
    my ($_data_col, $_map_col_name, $_map_col_format_type, $_exact_match, $_map_col_mand, $_map_col_valid_val) = @_;
    chomp $_data_col;

    $_data_col =~ s/ //g;
    my $_length_data_col = length($_data_col);
    my $_last_day;

    if ( $_map_col_mand eq 'Y' and $_length_data_col == 0) {
       &error_process ($data_row_cnt, $_map_col_name, "No data in a mandatory column");
       return;
    }elsif ( $_length_data_col == 0 ) {
       print LOG_FILE "date is empty but not mandatory\n" if ( $debug eq 'Y' );
       return;
    }elsif ( ($_map_col_format_type =~ /DATETIME/ && $_length_data_col != 14) || ($_map_col_format_type eq 'DATE' && $_length_data_col != 8) ){
       &error_process ($data_row_cnt,$_map_col_name, "$_map_col_format_type ($_data_col) has invalid length of $_length_data_col mandatory = $_map_col_mand");
       return;
    }

    print LOG_FILE "after length check : length is $_length_data_col\n" if ( $debug eq 'Y' ); 
    print LOG_FILE "_data_col $_data_col\n" if ( $debug eq 'Y' ); 
    my $_YYYY = substr($_data_col,0,4);
    my $_MM = substr($_data_col,4,2);
    my $_DD = substr($_data_col,6,2);

    my $leap_year_check = $_YYYY % 4;


    if ( $_map_col_format_type =~ /DATETIME/ ) {
       my $_HH = substr($_data_col,8,2);
       my $_MI = substr($_data_col,10,2);
       my $_SS = substr($_data_col,12,2);
       if ($_HH > 23 || $_MI > 59 || $_SS > 59) {
          &error_process ($data_row_cnt,$_map_col_name, "$_map_col_format_type time is invalid $_length_data_col");
          return;
       }
    } 


    if ($_MM > 12 || $_MM == 0 ) {
       &error_process ($data_row_cnt,$_map_col_name, "$_map_col_format_type date is invalid $_data_col is $_length_data_col");
       return;
    }else{
       $_last_day = $last_day{$_MM};
       if ($_MM == 2 ) {
          if ($leap_year_check == 0 ) {
             $_last_day = 29;
          }else{
             $_last_day = 28;
          }
       }
    }

    if ($_DD > $_last_day || $_DD == 0 ) {
       &error_process ($data_row_cnt,$_map_col_name, "$_map_col_format_type date is invalid $_data_col is $_length_data_col");
       print LOG_FILE "dd $_DD  mm $_MM  yyyy $_YYYY $_last_day\n" if ( $debug eq 'Y' );
    }

}



sub validate_alphanumeric_data () {
    print LOG_FILE "\nsub validate_alphanumeric_data\n" if ( $debug eq 'Y' );
    print LOG_FILE "==============================\n" if ( $debug eq 'Y' );
    my ($_data_col, $_map_col_name, $_map_col_format_size, $_exact_match, $_map_col_mand, $_map_col_valid_val) = @_;
    chomp $_data_col;

    print LOG_FILE "$_data_col\n" if ( $debug eq 'Y' );

    if ($_map_col_mand eq "Y"  &&  length($_data_col) == 0 ) {
       &error_process ($data_row_cnt,$_map_col_name, "No data in a mandatory column");
    }elsif (length($_data_col) > 0) {
       $_data_col =~  s/\xD1/N/; 
       $_data_col =~  s/\xD4/O/;
       if ( $_data_col !~ /^[[:print:]]+$/ ) {
          &error_process ($data_row_cnt,$_map_col_name, "Invalid or unprintable characters($_data_col)");
       }
       &check_length ($_data_col, $_map_col_name, $_map_col_format_size, 'N');
    }
    
}



sub validate_numeric_data () {
    print LOG_FILE "\nsub validate_numeric_data\n" if ( $debug eq 'Y' );
    print LOG_FILE "=========================\n" if ( $debug eq 'Y' );
    my ($_data_col, $_map_col_name, $_map_col_format_size, $_exact_match, $_map_col_mand, $_map_col_valid_val) = @_;
    my $_num_part = 0;
    my $_dec_part = 0;
    my $_num_part_mod = 0;
    chomp $_data_col;

    $_data_col =~ s/^ +//;
    my $_data_col_mod = $_data_col;

    if ($_map_col_mand eq "Y"  &&  length($_data_col) == 0 ) {
       &error_process ($data_row_cnt,$_map_col_name, "No data in a mandatory column");
    }elsif (length($_data_col) > 0) {
       ($_num_part = $_map_col_format_size) =~ s/,.*$//;
       $_num_part_mod = $_num_part;
       if ($_map_col_format_size =~ /,/) {
          ($_dec_part = $_map_col_format_size) =~ s/^.*,//;
#          $_num_part_mod++;
       }
    
       $_data_col_mod =~ s/\.//;
       &check_length ($_data_col_mod, $_map_col_name, $_num_part_mod, $_exact_match);
       print LOG_FILE "data $_data_col, name $_map_col_name, size $_map_col_format_size, exact $_exact_match, mand $_map_col_mand, valid value $_map_col_valid_val\n" if ( $debug eq 'Y' );
       print LOG_FILE "$_data_col     num part mod $_num_part_mod   num $_num_part dec $_dec_part\n" if ( $debug eq 'Y' );

#       $_data_col =~ s/^ +//;
#       my $_data_col_mod = $_data_col;
#       $_data_col_mod =~ s/\.//;

       if ( $_data_col_mod !~ /^ *[+|-]? *\d\d*$/ ) {
          &error_process ($data_row_cnt,$_map_col_name, "Invalid or non numeric data($_data_col)");
       }elsif ( $_dec_part == 0  &&  $_exact_match eq "Y" && $_data_col !~ /^\d{$_num_part_mod}$/ ) {
          &error_process ($data_row_cnt,$_map_col_name, "$_data_col should have no decimals and be an exact match to map size($_map_col_format_size)");
       }elsif ( $_dec_part == 0 &&  $_data_col !~ /^ *[-|+]? *\d\d*$/ ) {
          &error_process ($data_row_cnt,$_map_col_name, "$_data_col should have no decimals and be wihtin the range of the map size($_map_col_format_size)");
       }elsif ( $_dec_part > 0  &&  $_exact_match eq "Y"  &&  $_data_col !~ /^[-|+]?\d{$_num_part_mod}\.\d{$_dec_part}$/ ) {
          &error_process ($data_row_cnt,$_map_col_name, "$_data_col should have $_dec_part decimals and be an exact match to map size($_map_col_format_size)");
       }elsif ( $_dec_part > 0  &&  $_data_col !~ /^[-|+]?\d\d*\.\d{$_dec_part}$/ ) {
          &error_process ($data_row_cnt,$_map_col_name, "$_data_col should have $_dec_part decimals and within the range of the map size($_map_col_format_size)");
       }

    }

  
}


sub determine_map_name () {
   
    my $_file_name = shift;
       $_file_name =~ s/.*\/// ;
    my $_target;
    my $_source;
    my $_map_name;
    my $_rec_type;
    my $_file_date; 
    my $_full_file_type; 
    my $_file_number;
    my $_release;
    my $_x;
    my $_y;

    my @_segment = split /_/,$_file_name;
    my $_elements = @_segment;
    my $_segment_numbers = @_segment;

    if ($_segment_numbers == 5 ) {
       ($_target, $_rec_type, $_file_date, $_file_number, $_release) = @_segment;
       $_source = "";
       $_full_file_type = $_target;
    }elsif ($_segment_numbers == 6 ) {
       ($_source, $_target, $_rec_type, $_file_date, $_file_number, $_release) = @_segment;
       $_full_file_type = "${_source}_${_target}";
    }
  
    $file_rec_type = $_rec_type;
#    ($file_name_rec_type_seq = $_map_name) =~ s/.map$//;
    $file_name_rec_type = "${_full_file_type}_${_rec_type}";
    $file_name_rec_type_seq = "${_full_file_type}_${_rec_type}_${_file_number}";

    if ( $debug eq 'Y' ) {
       open (LOG_FILE, ">>$DIR/data/logs/validate_columns_${file_name_rec_type_seq}-${DAT}.log") || die "can't find file $file_name in $DIR/data/ $!\n" 
    }

    print LOG_FILE "\ndetermine_map_name\n" if ( $debug eq 'Y' );
    print LOG_FILE "==============\n" if ( $debug eq 'Y' );

    $file_type = $file_type{$_full_file_type};

    my $_check_for_spcl_map = &special_handling (3,$file_name_rec_type, $_source);
    if ('S' eq $_check_for_spcl_map) {
       $_map_name = $_target . "_" . $_rec_type . "X" . '.map';
    }else{
       $_map_name = $_target . "_" . $_rec_type . '.map';
    }



    my $_file_size = `wc -l $DIR/data/$file_type/$_file_name | sed 's/ .*//'`;

    print LOG_FILE "\ndetermine_map_name\n" if ( $debug eq 'Y' );
    print LOG_FILE "====================\n" if ( $debug eq 'Y' );
    print LOG_FILE "$_target 	$_rec_type	$_file_date	$_file_number	$_release \n" if ( $debug eq 'Y' );
    print LOG_FILE "full file type is $_full_file_type\n" if ( $debug eq 'Y' );
    print LOG_FILE "map_name $_map_name \n" if ( $debug eq 'Y' );
    print LOG_FILE "full file type $file_type{$_full_file_type}\n" if ( $debug eq 'Y' );
    print LOG_FILE "file type is $file_type\n" if ( $debug eq 'Y' );
    print LOG_FILE "file size is $_file_size\n" if ( $debug eq 'Y' );



    return ($_map_name, $_source);
}



sub get_map_file () {
    print LOG_FILE "\nget_map_file\n" if ( $debug eq 'Y' );
    print LOG_FILE "==============\n" if ( $debug eq 'Y' );

    my $_map_name = shift;
    print LOG_FILE "-${_map_name}-\n" if ( $debug eq 'Y' );

    open (MAPFILE, "<$DIR/data/maps/$_map_name") || die "can't find file in $DIR/data/maps/$_map_name $!\n";
    my @_map_row = (<MAPFILE>);
    close MAPFILE;

    print LOG_FILE "map data ${_map_row[0]}\n" if ( $debug eq 'Y' );
    $num_map_cols = @_map_row;
    print LOG_FILE "elements in map_data $num_map_cols\n" if ( $debug eq 'Y' );


    return @_map_row;

}


sub error_process {
    print LOG_FILE "\n error_process\n" if ( $debug eq 'Y' );
    print LOG_FILE "================\n" if ( $debug eq 'Y' );
    my ($_row_num, $_col_name, $_msg) = @_;

    print LOG_FILE "$file_name\n" if ( $debug eq 'Y' );
    $err_cnt++;
    print LOG_FILE "	Row $_row_num, Column $_col_name, $_msg error count($err_cnt)\n" if ( $debug eq 'Y' );
    print RPT_FILE ",Row $_row_num,Column $_col_name,$_msg error count($err_cnt)\n";

}
