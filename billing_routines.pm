
package billing_routines;
use strict;
use warnings;
use Exporter qw( import );
our @EXPORT_OK = qw( get_data_type get_number binary_search get_index_data build_index_data );
our @ISA = qw( Exporter );
chomp (my $DIR = `pwd`); 

sub get_number {

    my $_in_number = shift;

    my $_out_number = ++$_in_number;
    return $_out_number;
}


sub build_index_data {
    my ($key, $data_type) = @_;
    my $debug = 1;
    my $prev_acct  = 0;
    my $cntr       = 0;
    my $cntr_sufix = 0;;
    my $acct_col   = `grep $key $DIR/data/common/list_${data_type}_filenames.txt | cut -d, -f2`;
    my @indx_data  = `cat $DIR/data/${data_type}/${key}* |sed 's/\|\|//g' | sort --parallel=4 -S 75% -n -t"" -k${acct_col}`;
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
       $_ =~ s//||/g;
    }
    if ($debug ) {
       print "$indx_key[415]  $indx_data[415]\n";
       print "$indx_key[416]  $indx_data[416]\n";
       print "$indx_key[417]  $indx_data[417]\n";
       print "$indx_key[418]  $indx_data[418]\n";
       print "$indx_key[419]  $indx_data[419]\n";
       print "$indx_key[420]  $indx_data[420]\n";
       print "$indx_key[421]  $indx_data[421]\n";
       print "$indx_key[422]  $indx_data[422]\n";
       print "$indx_key[423]  $indx_data[423]\n";
       print "$indx_key[424]  $indx_data[424]\n";
       print "$indx_key[425]  $indx_data[425]\n";
       print "$indx_key[426]  $indx_data[426]\n";
       print "$indx_key[427]  $indx_data[427]\n";
       print "$indx_key[428]  $indx_data[428]\n";
       print "$indx_key[429]  $indx_data[429]\n";
       print "$indx_key[430]  $indx_data[430]\n";
       print "$indx_key[431]  $indx_data[431]\n";
       print "$indx_key[432]  $indx_data[432]\n";
       print "$indx_key[433]  $indx_data[433]\n";
       print "$indx_key[434]  $indx_data[434]\n";
       print "$indx_key[435]  $indx_data[435]\n";
       print "$indx_key[436]  $indx_data[436]\n";
       print "$indx_key[437]  $indx_data[437]\n";
       print "$indx_key[438]  $indx_data[438]\n";
       print "$indx_key[439]  $indx_data[439]\n";
    }

}


sub get_index_data {
    my $file_name_key = shift;

    my $data_type_ref = &get_data_type;
    my $data_type = $data_type_ref->{$file_name_key};

    chomp (my $common_data = `grep $file_name_key $DIR/data/common/list_${data_type}_filenames.txt`);
    (my $acct_col = $common_data) =~ s/.*,(.*),.*,.*/$1/;

    $acct_col--;

    my @file_names = `ls -1 $DIR/data/$data_type/$file_name_key* `;


    open (INDX,">$DIR/data/${file_name_key}_TMP") || die "can't open file $!\n";

    foreach my $file_name (@file_names) {
       my $cntr=0;
       chomp $file_name;
#       print "$file_name_key $file_name $common_data $acct_col\n";
       my @file_name_data = `cat $file_name`;
       foreach (@file_name_data) {
          chomp $_;
          my @data_row = split /\|\|/,$_;
          print INDX "$data_row[$acct_col],$cntr,$file_name\n";
          $cntr++;
       }
    }

    `sort -t"," -k1,1n -k2,2n -k3,3  $DIR/data/${file_name_key}_TMP > $DIR/data/${file_name_key}_INDX`;
    unlink "$DIR/data/${file_name_key}_TMP";

    close INDX;

}

sub binary_search {
#   send a ref to missing account array and the account to search for - will retun the subscript of the array
#
    my ($data_accts, $acct_to_find) = @_;

    my ($low, $high) = (0, @$data_accts - 1);

    while ( $low <= $high ) {
       my $found_sub = int(($low + $high)/2);
       $low = $found_sub+1, next if $data_accts->[$found_sub] lt $acct_to_find;
       $high = $found_sub-1, next if $data_accts->[$found_sub] gt $acct_to_find;
#       print "match $found_sub $acct_to_find\n"; 
       return $found_sub;
    }
    return;

}

sub get_data_type {

    my %type_hash;
    my @type_data = ('source', 'core', 'noncore');

    foreach my $type (@type_data) {
       my @a = `cat $DIR/data/common/list_${type}_filenames.txt | sed 's/,.*//'`;
       foreach (@a) {
          chomp $_;
          $type_hash{$_} = $type;
       }
    }
    return \%type_hash;
}



1;
