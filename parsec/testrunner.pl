#!/usr/bin/perl 
use warnings;
use strict;
use diagnostics;
use feature 'state';
use 5.014;
use Cwd qw(abs_path cwd);

my $HOME = $ENV{"HOME"};
my $PATH = $ENV{"PATH"};

die "Initialize env vars !" if (!defined $HOME);

my $kernel = "/usr/src/linux-3.13.7/";
my @sources = qw(xxorr1 xxorr2 xxorr4 xxorr8 xxorr16);
my $srcpath = "$HOME/xnrheaders";
my $destpath = "$kernel/include/linux/xxorr_types.h";
my $replacefile = "test.txt";
my $tmp;

#run the parsec test here
my $parsecdir = "/home/ssllab/parsec/parsec-3.0";
chdir $parsecdir;
#my $wd = cwd();
#say $wd;
#die "Initialize env path vars !" if ($PATH !~ /(.*?)$parsecdir/m);
say $PATH;

=begin
#no need to build as we are not making any changes to parsec libs
$parsecrun = "parsecmgmt -a fulluninstall -p splash2x";
system $parsecrun;

my $parsecrun = "parsecmgmt -a build -p splash2x";
system $parsecrun;
=cut

my $parsecrun = "parsecmgmt -a run -p splash2x -i simmedium";
system $parsecrun;

foreach my $file (@sources){
    next if (! -f "$srcpath/$file");
    say "found $file";
    chdir $kernel;
    system("cp","-f","$srcpath/$file","$destpath");
    system("mv","$srcpath/$file","$srcpath/$file.tmp");
    #system("make", "clean");
    system("make");
    system("make", "bzImage");
    system("make", "modules");
    system("make", "modules_install");
    $tmp = "make install";
    say $tmp;
    system $tmp;
    print("Shutting down the system now\n");
    sleep 3;
    system("shutdown","-r","now");
    break;
}

while(1){
    sleep 10;
    say "shutting down";
}
