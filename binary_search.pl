#! /usr/bin/perl

use warnings;
use strict;

#my $x = &binary_search(\@data_acct, $_);

sub binary_search {

    my ($data_acct, $word) = @_;
    my ($low, $high) = (0, @$data_acct - 1);

    while ( $low <= $high ) {
#           print "low $low             high $high\n";
            my $try = int(($low + $high)/2);
            $low = $try+1, next if $data_acct->[$try] lt $word;
            $high = $try-1, next if $data_acct->[$try] gt $word;
            return $try;
    }
    return;

}

