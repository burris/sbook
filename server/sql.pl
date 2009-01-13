#!/usr/local/bin/perl
#
# Vineyard.NET's SQL library
#
# $Id: sql.pl,v 1.22 2001/08/30 19:43:24 theqblas Exp $
# Revision 1.4  1998/04/22 01:55:29  simsong
# added logging to header
#
#

use strict;
use English;
use Time::Local;
use DBI;

package sql;

#
# Globals
#


#
# new: create a new sql object
#
# paramaters: 'engine' - database engine to use. should be mysql or postgresql.
#             'db'     - name of database to use.
#             'safe'   - if 1, return 0 if we cannot connect. Otherwise die.
#

sub new {
    my $type = shift;
    my %params = @_;
    my $self = {};

    # Read the configuration file

    bless $self,$type;

    $self->{'engine'}	= $params{'engine'} ? $params{'engine'} : "mysql";
    $self->{'db'}	= $params{'db'};
    $self->{'safe'}	= $params{'safe'};
    $self->{'user'}	= $params{'user'};
    $self->{'pass'}	= $params{'pass'};
    $self->{'host'}     = $params{'host'} || 'localhost';

    if($self->connect){
	return $self;
    }
    else{
	return undef;
    }
}

################
#
# MySQL Password System
#

sub getmysqlpassword {
    my $self = shift;
    my $user;

    if(!$self->{'user'}){
	$user = getpwuid($>);
	$self->{'user'} = $user;
    }

    if(!$self->{'pass'}){
	if($ENV{'MP'}){
	    $self->{'pass'} = $ENV{'MP'};
	}
	else{
	    open(MP,"/usr/local/etc/dbpasswords/$user") || return undef;
	    die "Cannot open /vni/adm/dbpasswords/$user, $!, " .
		"\n$user is not a valid mySQL user," ;
	    $self->{'pass'} = <MP>;
	    chomp $self->{'pass'};
	    close(MP);
	}
    }
}



### some utility methods
# returns the first column of the first row
sub corner {
    my($self, $cmd) = @_;
    my @ref = $self->select($cmd);
    return $ref[0][0] if $ref[0];
    return undef;
}

# turns an SQL date into a unix timestamp
sub date_to_timestamp {
    my($self,$date) = @_;
    return undef unless $date;
    return $self->corner("select UNIX_TIMESTAMP(" . $self->stringquote($date) . ")");
}

# turns a unix timestamp into a date/time field
sub timestamp_to_time {
    my($self, $time) = @_;
    return undef unless $time =~ /^\d+$/;
    return $self->corner("select FROM_UNIXTIME($time)");;
}
	
# turns a unix timestamp into a date
sub timestamp_to_date {
    my($self, $time) = @_;
    return undef unless $time =~ /^\d+$/;
    my $pf = $self->timestamp_to_time($time);
    return (split /\s+/, $pf)[0];
}

sub debug {
    my $self = shift;
    $self->{'debug'} = $_[0];
}

# ctype - transform into a column type
# ctype(type,value)
sub ctype {
    my $self = shift;
    my ($type,$value) = @_;

    if($type eq "UINT" || $type eq "INT" || $type eq "NUMERIC"){
	$value =~ s/\s//g;
	$value = 0 if($value eq "");
	return $value;
    }
    elsif($type eq "CHAR"){
	return $self->stringquote($value);
    }
    elsif($type eq "TEXT"){
	return $self->stringquote($value);
    }
    elsif($type eq "UID"){
	return $self->userid($value) ||
	    die "SQL: no userid for username '$value', program $0, ",caller();
    }
    elsif($type eq "ENUM"){
	return $self->stringquote($value);
    }
    elsif($type eq "DATETIME"){
	if($self->{"engine"} eq "mysql"){
	    return "FROM_UNIXTIME($value)";
	}
	my($sec,$min,$hours,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($value);
	$mon	+=1;
	$year	+=1900;		# Y2K okay!
	return "'$year-$mon-$mday $hours:$min:$sec'";
    }
    else{
	die "sql.pl: no SQL type defined for type '$type' ,";
    }
}


# SQL quoting of strings
sub stringquote {
    my $self = shift;
    my $val  = $_[0];
    $val =~ s/\\/\\\\/g;
    $val =~ s/'/\\'/g;
    return "'$val'";
}

#################################################################
# 
# Connection with DBI comes here.
#

sub fatal {
    my $self = shift;
    open(ERR,">>/vni/log/mysql.err");
    print ERR scalar(localtime(time())),"\n";
    print ERR "$0: $_[0]\n";
    close(ERR);
    print $_[0];
    die $_[0];
}

sub connect {
    my $self = shift;

    $self->getmysqlpassword;
    my $engine = $self->{'engine'};
    my $host = $self->{'host'};
    my $db   = $self->{'db'};
    my $user = $self->{'user'} || $ENV{'USER'};
    my $pass = $self->{'pass'};

    my $dbi;

    if($engine eq 'mysql'){
	$dbi = "dbi:$engine:$db:$host";
    }
    if($engine eq 'Pg'){
	$dbi = "dbi:$engine:dbname=$db";
    }

    $self->{'dbh'} = DBI->connect($dbi,$user,$pass);
    if(!$self->{'dbh'}){
	# Connect failed
	return 0 if($self->{'safe'});
	$self->fatal("SQL: $0 cannot connect to DBI source '$dbi' as user '$user': $DBI::errstr\n\n");
    }
    return $self;
}


sub send {
    my $self = shift;
    my $debug = $self->{'debug'};
    my($sql,$ignoreerr) = @_;


    print "$sql\n" if $debug;
    my $dbh = $self->{'dbh'} || die "dbh not defined,";
    my $sth = $dbh->prepare($sql);
    if(!$sth){
	return if $ignoreerr;
	die "SQL Failure in prepare (1).\n  $0 Statement: $sql\n  Error: " . $dbh->errstr . "\n";
    }
    if(!$sth->execute){
	return if $ignoreerr;
	die "SQL Failure in execute (1).\n  $0 Statement: $sql\n  Error: " . $sth->errstr . "\n";
    }
    $self->{'insertid'} = $sth->{'mysql_insertid'};
    $sth->finish;
}

#
# return the insertid from last autoincrement
#

sub insertid {
    my $self = shift;

    return $self->{'insertid'};
}

#
# do an SQL select and return a doubly-indexed array of the results
#

sub select {
    my $self = shift;
    my($sql,$ignoreerr) = @_;
    my @ary;
    my $conn   = $self->{'conn'};

    print "$sql\n" if $self->{'debug'};

    my $dbh = $self->{'dbh'} || die "dbh not defined,";
    my $sth = $dbh->prepare($sql);
    if(!$sth){
	return if $ignoreerr;
	die "SQL Failure in prepare (2).\n  $0 Statement: $sql\n  Error: " . $dbh->errstr . "\n";
    }
    if(!$sth->execute){
	return if $ignoreerr;
	die "SQL Failure in execute (2).\n  $0 Statement: $sql\n  Error: " . $sth->errstr . "\n";
    }

    my $numFields = $sth->{'NUM_OF_FIELDS'};

    my @ret;
    while (my @vals = $sth->fetchrow_array) {
	push(@ret,\@vals);
    }
    $sth->finish;
    return @ret;
}


#
# select1hash returns a single hash for the select statement
#
sub select1hash {
    my $self = shift;
    my($sql,$ignoreerr) = @_;

    print "$sql\n" if $self->{'debug'};

    my $dbh = $self->{'dbh'} || die "dbh not defined,";
    my $sth = $dbh->prepare($sql);
    if(!$sth){
	return if $ignoreerr;
	die "SQL Failure in prepare (3).\n  $0 Statement: $sql\n  Error: " . $dbh->errstr . "\n";
    }
    if(!$sth->execute){
	return if $ignoreerr;
	die "SQL Failure in execute (3).\n  $0 Statement: $sql\n  Error: " . $sth->errstr . "\n";
    }

    my $hashref;
    my %hash;

    if($hashref = $sth->fetchrow_hashref){
	%hash = %$hashref;
	return %hash;
    }
    return 0;
}


################################################################
#
# Helper functions that don't really touch the DBI interface


sub firstColumn {
    my $self = shift;
    my @res = @_;
    my @ret;

    while(@res){
	push(@ret,$res[0][0]);
	shift @res;
    }
    #return sort @ret;
    return @ret;
}


sub dbh {
    my $self = shift;
    return $self->{'dbh'};
}

sub DESTROY {
    my $self = shift;
    my $dbh = $self->{'dbh'} || die "dbh not defined,";
    
    $dbh->disconnect;		# force a disconnect on destruction
}


1;
