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
#my @sources = qw(xxorr1 xxorr2 xxorr4 xxorr8 xxorr16);
my @sources = qw(xxorr16 xxorr8 xxorr2);

my $srcpath = "$HOME/xnrheaders";
my $destpath = "$kernel/include/linux/xxorr_types.h";
my $testtype = "test.txt";
my $tmp;

#run the parsec test here
my $parsecdir = "$HOME/parsec/parsec-3.0";
chdir $parsecdir;
my $logdir = "$parsecdir/log/results";
system('mkdir', $logdir) if (! -e $logdir);


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

sub runparsectest(){
    my $testsample = $_[0];
    my $numProcs = $_[1];
    my $runcount = "$_[2]";
    my $testrun = &readtestrun();
    my $logfile = "$logdir/$testrun.Proc$numProcs.$testsample.Run$runcount.txt";

    my $parsecrun = "parsecmgmt -a run -p splash2x -i $testsample -n $numProcs > $logfile 2>&1";
    say $parsecrun;
    say "\nRunning test input size $testsample for a $testrun kernel....";
    say "Tests run time can vary based on test type : simsmall < simlarge < native ";
    say "Look out for kernel oops if you think it is taking way beyond expected time ";
    system $parsecrun;
    say "Test Completed. See results in $logfile \n\n";
}

sub runparsectimetest(){
    my $testsample = $_[0];
    my $numProcs = $_[1];

    chdir "$parsecdir/ext/splash2x/apps/barnes/run";
    my $test = "time $parsecdir/ext/splash2x/apps/barnes/inst/amd64-linux.gcc/bin/run.sh $numProcs $testsample";
    system $test;
    say $test;
}

sub updatetestrun(){
    say $_[0];
    open my $testFH, '>', "$srcpath/$testtype";
    printf $testFH "$_[0]";
    close $testFH;

}

sub readtestrun(){
    my $testfor = "vanilla";
    return $testfor if (! -f "$srcpath/$testtype");
    open TESTFH, '<', "$srcpath/$testtype";
    while (<TESTFH>){
        $testfor = $_;
    }
    close TESTFH;

    return $testfor;
}

#&runparsectest("native", 1, 1);
#&runparsectest("native", 4, 1);
&runparsectimetest("native", 4);

foreach my $file (@sources){
    next if (! -f "$srcpath/$file");
    say "found $file";

    &updatetestrun($file);

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

    while(1){
        sleep 10;
        say "shutting down";
    }
}

