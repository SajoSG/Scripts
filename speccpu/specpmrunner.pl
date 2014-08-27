#!/usr/bin/perl 
use warnings;
use strict;
use diagnostics;
use feature 'state';
use 5.014;
use Cwd qw(abs_path cwd);

my $HOME = $ENV{"HOME"};
my $SPEC = $ENV{"SPEC"};

say "Home -> $HOME and Spec -> $SPEC";
die "Initialize env vars !" if (!defined $HOME or !defined $SPEC);

#the ld.gold must have a suffix .x_y where x is the size beyond the standard 16B size for  PLT entry and y is the offset where the entry starts
my @ldlist = qw(ld.gold.0_0 ld.gold.16_4 ld.gold.64_24 ld.gold.240_36);

my $srcpath = "$HOME/ldf";
#my $destpath = "/usr/bin";
my $destpath = "$HOME/ldf";
my $replacefile = "ld";

=local
my @ldlist = qw(test1.txt test2.txt);
my $srcpath = "$HOME/study/perl/speccpu/bin";
my $destpath = "$HOME/study/perl/speccpu/bin/t2";
my $replacefile = "test.txt";
=cut

my $pathvar = $ENV{"PATH"};
#say $pathvar;
die "Set ld path on ENV PATH manually " if ($pathvar !~ m/$srcpath/g);

foreach my $file (@ldlist){

    #system("sudo", "mv", "$destpath/$replacefile","$destpath/$replacefile.orig");
    system("cp", "$srcpath/$file","$destpath/$replacefile");
    system("./runspec", "--config=../config/sample.cfg", "--action=clean", "--tune=base", "all");
    `rm -Rf $SPEC/benchspec/C*/*/run`;
    `rm -Rf $SPEC/benchspec/C*/*/exe`;
    sleep 1;
    system("./runspec", "--config=../config/sample.cfg", "--action=build", "--tune=base", "all");
    #system("./runspec", "--config=../config/sample.cfg", "--action=build", "--tune=base", "bzip2");
    sleep 1;
    system("./runspec", "--config=../config/sample.cfg", "--tune=base", "--size=test", "--noreportable", "--iterations=1", "all");
    #system("./runspec", "--config=../config/sample.cfg", "--tune=base", "--size=test", "--noreportable", "--iterations=1", "bzip2");
    #system("sudo","mv", "$destpath/$replacefile.orig", "$destpath/$replacefile");
    system("rm", "$destpath/$replacefile");
    sleep 2;
    my $test = "0_0";
    $test = $1 if ($file =~ m/ld\.gold\.(.*)/);
    #say $test;
    system("./specpm.pl","-s", "CINT", "-t", "TestINT$test", "-r", "valgrind");
    sleep 2;
    system("./specpm.pl","-s", "CFP", "-t", "TestFP$test", "-r", "valgrind");
    #system("./specpm.pl","-b", "bzip2", "-t", "Testbzip$test", "-r", "valgrind");
    #system("./specpm.pl","-b", "bzip2", "-t", "Testbzip$test");
    sleep 5;
}
