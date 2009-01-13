
#!/usr/bin/perl
#
# Make an SBook distribution.
# This script creates:
# build.txt - contains the time of the build (also put on the server)
# version.txt - the CFBundleVersion from the project.pbxbuild file.

use strict;


my $NAME  = 'SBook51';
my $FNAME = "SBook51.app.tar.gz";
my $archive='SBook51';
my $archive_fname = "$archive.dmg";

my $version;
my $loc = '/home/www/sbook5.com/htdocs';

sub cmd {
    print $_[0],"\n";
    system $_[0] and die "FAILED\n";
}

sub copy {
    cmd("scp SBook51.dmg r2.simson.net:${loc}/SBook51.dmg");
}

# Get the version from the XML
#cmd("cvs commit -m .");
open(G,"Info.plist") || die "Info.plist";
while(<G>){
    if(m/CFBundleVersion/){	# find this line
	$_ = <G>;		# get the next line
	if(m:<string>(.*)</string>:){
	    $version = $1;
	}
	open(F,">version.txt") || die "cannot open version.txt";
	print F "$version\n";
	close(F);
	close(G);
    }
}

# Build

#system("make clean");
system("make all");
system("make src");

# Get the build time
my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks)
    = stat("build/DevelopmentSBook5.app/Contents/MacOS/SBook5");

$mtime || "Cannot find mtime in SBook5!";

# Put the build time into the Resources
open(B,">build/Development/SBook5.app/Contents/Resources/build.txt");
print B "$mtime\n$version\n";
close(B);


# Now create the .dmg archive

my $dstroot='built';
my $mbytes = 25;
my $hdid;

cmd("/bin/rm -rf built");
mkdir "built";
cmd("mv build/Development/SBook5.app built");

unlink $archive_fname;

cmd("hdiutil create '$archive.dmg' -megabytes $mbytes -layout NONE");
$hdid = `hdid -nomount '$archive.dmg' | grep '/dev/disk[0-9]*'`;
$hdid =~ s/\s.*//;

cmd("/sbin/newfs_hfs -w -v '$archive' -b 4096 $hdid");
cmd("hdiutil eject $hdid");
            
$hdid = `hdid '$archive.dmg' | grep '/dev/disk[0-9]*'`;
my($dev, $mountPoint) = ($hdid =~ m/(\S+)\s+(.*)/);
cmd("ditto -rsrc '$dstroot' '$mountPoint'"); # copies over thebuilt directory
cmd("cp demo.sbok '$mountPoint'"); # copies the demo file
cmd("mv plugin-src.tar.gz '$mountPoint'");
cmd("/bin/mv built/SBook5.app build"); # moves out the app
cmd("rmdir built");

cmd("hdiutil eject $dev");
rename "$archive.dmg", "$archive.orig.dmg";
cmd("hdiutil convert '$archive.orig.dmg' -format UDZO -o '$archive'");
unlink "$archive.orig.dmg" 
    or die "can't unlink $archive.orig.dmg: $!\n";

my $version_nospace = $version;
$version_nospace =~ s/ //g;

copy();

exit(0);
my $build = 'build/SBook5.app/Contents/Resources/build.txt';
my $tfiles = "changes.html bugs.html version.txt ";
my $dfiles = "$archive.dmg $archive.dmg.gz ";
system("ssh  r2.simson.net mkdir $loc/new");
system("scp  $tfiles $dfiles $build r2.simson.net:$loc/new");
system("ssh  r2.simson.net '(cd $loc/new;/bin/mv -f $tfiles build.txt ..;mv $dfiles ../download)'");
system("ssh  r2.simson.net ln $loc/download/$archive.dmg $loc/download/$archive.$version_nospace.dmg");


