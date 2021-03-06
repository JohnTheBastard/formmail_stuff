#!/usr/bin/env perl -w

use strict;

die("Needs 2 args!\n") unless($ARGV[0] && $ARGV[1]);

open(INPUT,"<",$ARGV[0])||die("Cannot open file: $!");
open(OUTPUT,">",$ARGV[1])||die("Cannot create file: $!");

while(<INPUT>) {
  chomp;
  if (/(\W+)/) {
    print OUTPUT length($1),"\n";
  }
}

close(INPUT);
close(OUTPUT);
exit;
