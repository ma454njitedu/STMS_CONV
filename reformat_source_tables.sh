#! /bin/bash


cat AAJ_unsorted_data.txt | sed 's///' | sed -e 's/^  *//' -e 's/   */|/g' | sed "/^$/d" | perl -e '
  my $first_time = 'Y';
  my $line;

  while (<>) {
  chomp $_;
  ($first, $rest) = split(/,/,$_);
  if ($first =~ /^[0-9]+/ ) {
    $first_time = 'N';
    print "$line\n";
    $line = $_ ;
  }else{
     if ($first_time eq 'Y') {
        $first_time = 'N';
        $line = $_ ;
     }else{
        $line = $line . "|" . $_ ;
     }
  }
}
'
