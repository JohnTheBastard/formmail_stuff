#!/usr/bin/perl -w

use strict;

die("No file specified. See usage notes.\n") unless $ARGV[0];
open(USERPASS,"<",$ARGV[0])||die("Cannot open file: $!");
my ($username,$password);

while(<USERPASS>) {
  chomp;
  ($username, $password)=($1,$2) if (/(\w+),(\w+)/);
  print "username: $username\npassword: $password\n\n";
}
close(USERPASS);
exit;
