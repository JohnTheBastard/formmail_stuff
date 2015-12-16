#!/usr/bin/perl -w
#
# delete_phpbb_users.pl
#
# Script reads comma-separated username and encrypted password from
# a file and creates profiles in phpbb messageboard via insertion 
# into mysql database.
#
# jhearn, 5/15/07

use strict;
use DBI;

die("No file specified. See usage notes.\n") unless($ARGV[0]);
open(DEAD_USERS,$ARGV[0])||die("Cannot open file: $!");

#my ($username,$password,$id)=('','',0);
my $dead_user = '';

my $database='phpbb';
my $db_host='improv.ac.hmc.edu';
my $db_user='root';
my $db_pass='tribute7';
my $db_table='phpbb_users';
my $regdate=time;
#my %attr => (PrintError => 1, RaiseError => 1);

my $dbh=DBI->connect("dbi:mysql:dbname=$database:$db_host", "$db_user",
		     "$db_pass") or die("Error: $DBI::errstr");

# user_id is the table's primary key, so we get the 
# max to insert uniquely at the end of the table. 
my $sql="SELECT MAX(user_id) FROM $db_table";
my $sth=$dbh->prepare($sql);
$sth->execute;
my $record=$sth->fetch;
$id="@$record";
$sth->finish;

while(<DEAD_USERS>) {
  chomp;
#  ($username)=($1,$2) if (/(\w+),(\w+)/);
  $username=$1 if (/(\w+)/);
#  $id++;
#  $sql="INSERT INTO $db_table (user_id, username, user_password, user_regdate) 
#        VALUES ('$id', '$username', '$password', '$regdate')";
  
  $sql="DELETE FROM $db_table WHERE username='$dead_user'";

 $sth=$dbh->prepare_cached($sql);
  $sth->execute;
}

$sth->finish;
$dbh->disconnect;
close(DEAD_USERS);
exit;
