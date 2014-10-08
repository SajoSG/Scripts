#!/usr/bin/perl 
use warnings;
use strict;
use diagnostics;
use feature 'state';
use 5.014;
use Cwd qw(abs_path cwd);


my $fileName;
my $resultcsv = "parsedResults.csv";

sub getTimeInSecs(){
    if ($_[0] =~ m/(\d*)m(\d*)\.(\d*)s/){
        my $secs = ($1*60) + $2;
        return "$secs.$3";
    }
    return "fail";
}

open my $resFH, '>>', $resultcsv;

my $workdir = Cwd::cwd();

opendir RESDIR, $workdir;
foreach (readdir RESDIR){
    if (-f and m/(.*?)\.Proc(\d)\..*/){
        #say "$_ file is $1 with $2";
        $fileName = $_;
        printf $resFH "$1_$2,";
    }else{
        next;
    }
    

    open logFH, $fileName or die "Cannot open $fileName : $!";
    while (<logFH>){
        #say "Line: $_";
        #say $2 if ($_ ~~ m/(real|user|sys)\s*(.*)/);
        if ($_ =~ m/(real|user|sys)\s*(.*)/){
            my $time = &getTimeInSecs($2);
            printf $resFH "$time,";
        }
    }
    close logFH;
    printf $resFH "\n";
}

close $resFH;
