#!/usr/bin/perl

use Getopt::Long;


use strict;
require "sql.pl";

my %opts;
GetOptions(\%opts,
	   "help!",
	   "user=s",
	   "password=s"
	   );

my $sql;
main();

sub main {
    $sql  = sql->new("host" => "localhost",
			"db"   => "sbook_sync",
			"user" => $ENV{'USER'},
			);

    if($opts{'user'} && $opts{'password'}){
	set_password($opts{'user'},$opts{'password'});
    }
    
}


sub set_password {
    my($u,$p) = @_;
    print "Setting ${u}'s password to $p\n";
    my @res = $sql->select("select userid from users where username like '$u'");
    if(@res){
	my $id = $res[0][0];
	$sql->send("update users set password_md5=password('$p') where userid=$id");
    }
    else {
	$sql->send("insert into users (username,password_md5) values ('$u',password('$p'))");
    }
}
