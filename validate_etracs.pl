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
   'ETRACS'  => 'noncore',
   'CACS_ETRACS'=> 'source',
   'EDW_ETRACS' => 'source',
   'RIO_ETRACS' => 'source',
   'RMS_ETRACS' => 'source',
   'STMS_ETRACS'=> 'source',
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


   if ( $its_a_dup{$_}++ ) {
      my $partial_data = substr($_,0,50);
      chomp $partial_data;
      &error_process ($data_row_cnt, "N/A", "duplicate row (${partial_data}...)");
   }


   my ($map_col_name, $map_col_spc_allow, $map_col_format, $map_col_valid_val, $map_col_src_system, $map_col_spec_length, $map_col_justify);
   my $data_col;


   if ($num_map_cols == $num_data_cols) {
       foreach $data_col (@data_row) {
          ($map_col_name, $map_col_spc_allow, $map_col_format, $map_col_valid_val, $map_col_src_system, $map_col_spec_length, $map_col_justify) = split /	/,$map_file[$cnt];
          chomp  $map_col_justify;
          chomp  $data_col;

	  print LOG_FILE "--------- Start New Column -------------------------------------------------------------------------------\n\n" if ( $debug eq 'Y' );
          print LOG_FILE "-${data_col}- $map_col_name, $map_col_spc_allow, $map_col_format, $map_col_valid_val, $map_col_src_system, ${map_col_spec_length}, $map_col_justify\n" if ( $debug eq 'Y' );
          $cnt++;

	  (my $map_col_format_type = $map_col_format) =~ s/\(.*//;
          (my $map_col_format_size = $map_col_format) =~ s/^.*\((.*)\).*$/$1/;
          chomp $map_col_format_size;
          $map_col_format_size = 8 if ($map_col_format_size eq 'DATE');

          next unless &validate_source_system ($data_col,$map_col_name);
          next unless &validate_null_values($data_col,$map_col_name, $map_col_src_system);
          next unless &validate_valid_value($data_col,$map_col_name, $map_col_valid_val);
          next unless &check_length($data_col, $map_col_name, $map_col_format, $map_col_format_size, $map_col_spec_length); 
          next unless &validate_spaces($data_col, $map_col_name, $map_col_spc_allow, $map_col_src_system); 
          next unless &validate_numeric_data($data_col,$map_col_name, $map_col_format);
          next unless &validate_date($data_col, $map_col_name, $map_col_format_type);
          &validate_alphanumeric_data($data_col, $map_col_name, $map_col_justify) if ( $map_col_format =~ "CHAR");



          print LOG_FILE "\n" if ( $debug eq 'Y' );
       }
   }else{
      print LOG_FILE "-${data_row_cnt}- map cols $num_map_cols doesnt match data cols $num_data_cols\n" if ( $debug eq 'Y' );
      &error_process ($data_row_cnt, "N/A", "map cols $num_map_cols doesnt match data cols $num_data_cols");
   }

}

my $end_dt=`date`;
print LOG_FILE "$err_cnt Errors	end time: $end_dt\n" if ( $debug eq 'Y' );
print RPT_FILE "$err_cnt Errors\n";
close LOG_FILE if ( $debug eq 'Y' );

#========================================= subroutines begin here ===============================================

sub validate_source_system () {
    print LOG_FILE "\nsub validate_source_system\n" if ( $debug eq 'Y' );
    print LOG_FILE "=================\n" if ( $debug eq 'Y' );
    my ($_data_col,$_map_col_name) = @_;

    if ($_map_col_name eq 'SOURCE_SYSTEM') {
       if ($_data_col ne $source) {
          print LOG_FILE "-${data_row_cnt}- the value of $_map_col_name does not match the source part of the file $source\n" if ( $debug eq 'Y' );
          &error_process ($data_row_cnt, $_map_col_name, "$_data_col does not match the source part of the file ($source)");
       }
       return 0;
    }else{
       return 1;
    }

}


sub validate_null_values () {
    print LOG_FILE "\nsub validate_null_values\n" if ( $debug eq 'Y' );
    print LOG_FILE "=================\n" if ( $debug eq 'Y' );
    my ($_data_col,$_map_col_name, $_map_col_src_system) = @_;
#    chomp $_data_col;
    print LOG_FILE "source $source	map source $_map_col_src_system		-${_data_col}-\n" if ( $debug eq 'Y' );

    if ($source eq "") {
       print LOG_FILE "	file is a Target file so disregard null check\n" if ( $debug eq 'Y' );
       return 1;
    }elsif ($source ne $_map_col_src_system && $_data_col eq "") {
       print LOG_FILE "	data($_data_col) is null but OK since $source is Not mandatory in map $_map_col_src_system\n" if ( $debug eq 'Y' );
       return 0;	
    }elsif ($source eq $_map_col_src_system && $_data_col eq "") {
       print LOG_FILE "	data($_data_col) is null and $source is mandatory in map $_map_col_src_system\n" if ( $debug eq 'Y' );
       &error_process ($data_row_cnt, $_map_col_name, "$_data_col is null and  $_map_col_src_system  is mandatory");
       return 0;	
    }

    return 1;
}


sub validate_valid_value () {
    print LOG_FILE "\nsub validate_valid_value\n" if ( $debug eq 'Y' );
    print LOG_FILE "=================\n" if ( $debug eq 'Y' );
    my ($_data_col,$_map_col_name, $_map_col_valid_val) = @_;

    chomp $_data_col;
    return 1 if ($_map_col_valid_val eq ""); 

    my @_valid_value_array = split /,/,$_map_col_valid_val;
    my %_valid_value_hash  = map { $_, 1 } @_valid_value_array;

    if (exists($_valid_value_hash{$_data_col})) {
       print LOG_FILE "	data($_data_col) is a valid map value($_map_col_valid_val)\n" if ( $debug eq 'Y' );
    }else{
       print LOG_FILE "	data is NOT a valid value\n" if ( $debug eq 'Y' );
       &error_process ($data_row_cnt, $_map_col_name, "$_data_col is not a valid value in ($_map_col_valid_val)");
    }

    return 0;
}


sub validate_spaces{
    print LOG_FILE "\nsub validate_spaces\n" if ( $debug eq 'Y' ); 
    print LOG_FILE "================\n" if ( $debug eq 'Y' ); 
    my ($_data_col,$_map_col_name, $_map_col_spc_allow, $_map_col_src_system) = @_; 

    if  ( $_data_col =~ /^ +$/ ) {
        if ( $_map_col_spc_allow eq 'Y') {
           print LOG_FILE "	Data is all spaces and spaces are allowed $_map_col_spc_allow\n" if ( $debug eq 'Y' );
	   return 0;
	}elsif ($_map_col_src_system eq $source){
           print LOG_FILE "	Data is all spaces and spaces are not allowed $_map_col_spc_allow when map source $_map_col_src_system = $source\n" if ( $debug eq 'Y' );
           &error_process ($data_row_cnt, $_map_col_name, "$_data_col is all spaces which are NOT allowed ($_map_col_spc_allow) when map source $_map_col_src_system = $source");
	   return 0;
	}else{
           print LOG_FILE "	Data is all spaces and spaces are allowed $_map_col_spc_allow because map source $_map_col_src_system not equal $source\n" if ( $debug eq 'Y' );
	   return 0;
        }
    }else{
        print LOG_FILE "	Continue: Data is not all spaces \n" if ( $debug eq 'Y' );
        return 1;
    }
}


sub check_length () {
    print LOG_FILE "\nsub check_length\n" if ( $debug eq 'Y' ); 
    print LOG_FILE "================\n" if ( $debug eq 'Y' ); 
    my ($_data_col, $_map_col_name, $_map_col_format, $_map_col_format_size, $_map_col_spec_length) = @_;
    chomp $_data_col;


    if ($_map_col_spec_length > 0 && $_map_col_format =~ 'CHAR') {
        my $_data_col_tmp = $_data_col;
	$_data_col_tmp =~ s/ +$//; 
	my $_length_data_col_tmp = length($_data_col_tmp);
        if ($_length_data_col_tmp != $_map_col_spec_length) {
           &error_process ($data_row_cnt, $_map_col_name, "spcial length of $_data_col should be $_map_col_spec_length and data is $_length_data_col_tmp)");
        }
#        $_map_col_format_size = $_map_col_spec_length;
    }
    

    my $_length_data_col = length($_data_col);
    if ( $_length_data_col != $_map_col_format_size) {
       &error_process ($data_row_cnt,$_map_col_name, "Data length $_length_data_col does not match exactly with map($_map_col_format_size)");
       print LOG_FILE "	length of data is $_length_data_col  map length is $_map_col_format_size\n" if ( $debug eq 'Y' );
       return 0;
    }elsif ( $_length_data_col != $_map_col_format_size && $_length_data_col != 0 ) {
       &error_process ($data_row_cnt,$_map_col_name, "Data length $_length_data_col is not null and does not match exactly with map($_map_col_format_size)");
       print LOG_FILE "	length of data is $_length_data_col  map length is $_map_col_format_size while not mandatory, it is not null\n" if ( $debug eq 'Y' );
       return 0;
    }else{
       print LOG_FILE "	length of data is $_length_data_col  map length is $_map_col_format_size\n" if ( $debug eq 'Y' );
       return 1;
    }


}


sub validate_numeric_data () {
    print LOG_FILE "\nsub validate_numeric_data\n" if ( $debug eq 'Y' );
    print LOG_FILE "=========================\n" if ( $debug eq 'Y' );
 
    my ($_data_col, $_map_col_name, $_map_col_format) = @_;
    chomp $_data_col;

    if ($_map_col_format =~ "DATE") {
       if ( $_data_col !~ /^[+|-]?\d+$/ ) {
          &error_process ($data_row_cnt, $_map_col_name, "$_data_col is not numeric)");
          return 0;
       }else{
          print LOG_FILE "	$_map_col_name is Valid Numeric Data\n" if ( $debug eq 'Y' );
          return 1;
       }
    }elsif ($_map_col_format =~ "NUMBER" || $_map_col_format =~ "DECIMAL" ) {
       if ( $_data_col !~ /^[+|-]?\d+$/ ) {
          &error_process ($data_row_cnt, $_map_col_name, "$_data_col is not numeric)");
       }else{
          print LOG_FILE "	$_map_col_name is Valid Numeric Data\n" if ( $debug eq 'Y' );
       }
       return 0;
    }else{
       print LOG_FILE "	$_map_col_format, Skipping numeric check\n" if ( $debug eq 'Y' );
       return 1;
    }

}


sub validate_date () {
    print LOG_FILE "\nsub validate_date\n" if ( $debug eq 'Y' );
    print LOG_FILE "=================\n" if ( $debug eq 'Y' );

    my ($_data_col, $_map_col_name, $_map_col_format_type, $_map_col_spc_allow, $_map_col_valid_val) = @_;
    my $_last_day;
    chomp $_data_col;

    if ( $_map_col_format_type !~ "DATE") {
       print LOG_FILE "	$_map_col_format_type skipping Date check\n" if ( $debug eq 'Y' );
       return 1;
    }


    my $_YYYY = substr($_data_col,0,4);
    my $_MM = substr($_data_col,4,2);
    my $_DD = substr($_data_col,6,2);
    my $leap_year_check = $_YYYY % 4;


    if ($_MM > 12 || $_MM < 1 ) {
       print LOG_FILE "dd $_DD  mm $_MM  yyyy $_YYYY\n" if ( $debug eq 'Y' );
       &error_process ($data_row_cnt,$_map_col_name, "$_map_col_format_type is invalid $_data_col");
       return 0;
    }

    $_last_day = $last_day{$_MM};
    if ($_MM == 2 ) {
       if ($leap_year_check == 0 ) {
          $_last_day = 29;
       }
    }

    if ($_DD > $_last_day || $_DD < 1 ) {
       print LOG_FILE "dd $_DD  mm $_MM  yyyy $_YYYY $_last_day\n" if ( $debug eq 'Y' );
       &error_process ($data_row_cnt,$_map_col_name, "$_map_col_format_type is invalid $_data_col");
       return 0;
    }

    return 1;
}



sub validate_alphanumeric_data () {
    print LOG_FILE "\nsub validate_alphanumeric_data\n" if ( $debug eq 'Y' );
    print LOG_FILE "==============================\n" if ( $debug eq 'Y' );
    my ($_data_col, $_map_col_name, $_map_col_justify) = @_;
    chomp $_data_col;
    print LOG_FILE "$_data_col\n" if ( $debug eq 'Y' );

    $_data_col =~  s/\xD1/N/; 
    $_data_col =~  s/\xD4/O/;
    if ( $_data_col !~ /^[[:print:]]+$/ ) {
       print LOG_FILE "	Invalid or unprintable characters\n" if ( $debug eq 'Y' );
       &error_process ($data_row_cnt, $_map_col_name, "Invalid or unprintable characters($_data_col)");
       return 0;
    }
    
    if ($_map_col_justify eq 'Y') {
       if ($_data_col =~ /^ +.*/) { 
          print LOG_FILE "	Invalid justification, data has leading spaces ($_data_col)\n" if ( $debug eq 'Y' );
          &error_process ($data_row_cnt, $_map_col_name, "Invalid justification, data has leading spaces ($_data_col)");
          return 0;
       }
    }

    return 1;

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
#    print "seg number $_segment_numbers, full_file_type $_full_file_type, $file_type{$_full_file_type}, rec_type $_rec_type, file_name_Rec_type $file_name_rec_type\n";

    if ( $_source eq '' ) {
       $_map_name = $_target . "_" . $_rec_type . "X" . '.map';
    }else{
       $_map_name = $_target . "_" . $_rec_type . '.map';
    }
#    print "map - source -${_source}- $file_name_rec_type mapname $_map_name\n";



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
