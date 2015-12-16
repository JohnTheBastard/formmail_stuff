#!/usr/bin/env perl -w
#
#

use strict;

die("Needs 2 args!\n") unless($ARGV[0] && $ARGV[1]);

my ($in,$out);

open(INPUT,"<",$ARGV[0])||die("Cannot open file: $!");
open(OUTPUT,">",$ARGV[1])||die("Cannot create file: $!");

while(<INPUT>) {
  chomp;
  if (/\s*(\$masked\w+\W+\w+\W+),\s*/) {
    print OUTPUT "   push \@vars $1;\n   \$fmt.=\"\@\".rep(\">\",);\n";
  } elsif (/\s+undef,/) {
    print OUTPUT "   push \@vars undef;\t\t\t\t## \n   \$fmt.=\"\@\".rep(\">\",);\n";
  }
}

close(INPUT);
close(OUTPUT);
exit;
