#!/usr/bin/env perl -w
#
# This script generates passwords for HMC students and encrypts them for use
# with htaccess. The script expects three arguments.  The first should be the
# name of a file containing the student usernames for whom passwords are to be
# generated. The second and third arguments should be the desired names for the
# output files; one containing unecrypted passwords and one encrypted, 
# respectively.  Be aware that any existing file with the name specified in the
# second and third argument will be over-written.
#
# jhearn, 3/22/07
#

use strict;

unless($ARGV[0] && $ARGV[1] && $ARGV[2]){
  die("This script expects three arguments. See usage notes.\n");
}

my ($pw,$salt,$crypt_pw);

#RNG seed based on time from epoch and process ID.
srand((time() ^ (time() % $])) ^ exp(length($0))**$$);

open(USERS,"<",$ARGV[0])||die("Cannot open file: $!");
open(PWORD,">",$ARGV[1])||die("Cannot create file: $!");
open(CRYPT,">",$ARGV[2])||die("Cannot create file: $!");

while(<USERS>) {
  chomp;
  
  #Generate password.
  $pw=join '',('.','/',0..9,'A'..'Z','a'..'z')
    [rand 64,rand 64,rand 64,rand 64,rand 64,rand 64];
  print PWORD "Username: $_\nPassword: $pw\n\n";

  #Encrypt for use with Apache basic authentication.
  $salt=substr($pw, 0, 2);
  $crypt_pw=crypt($pw, $salt);
  print CRYPT "$_:$crypt_pw\n";
}

close(USERS);
close(PWORD);
close(CRYPT);

exit;
