#!/usr/bin/perl 
use warnings;
use strict;
use diagnostics;
use feature 'state';
use 5.014;
use Cwd qw(abs_path cwd);
use File::Spec::Functions;
use List::Util qw(min max);


## Global Variables
my %options = ();
my $workdir = "";
my $resultdir = $ENV{"HOME"} . "/PVResults";
system('mkdir', $resultdir) if (! -e $resultdir);
my $runcmd = "";
my $resultlog = "";
my $resultcsv = "";
my $perfstat = "cache-references,cache-misses,cycles,instructions,L1-dcache-loads,L1-dcache-load-misses,L1-dcache-stores,L1-dcache-store-misses,L1-dcache-prefetches,L1-dcache-prefetch-misses,L1-icache-loads,L1-icache-load-misses,L1-icache-prefetches,L1-icache-prefetch-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses,LLC-prefetches,LLC-prefetch-misses,dTLB-loads,dTLB-load-misses,iTLB-loads,iTLB-load-misses,branches,migrations";
my $delimiter = "@@";
my $valgrindres = "IRefs,I1Misses,LLiMisses,I1MissRate,LLiMissRate,DRefs,D1Misses,LLdMisses,D1MissRate,LLdMissRate,LLRefs,LLMisses,LLMissRate";

## Function Definitions
sub usage(){
    print "Usage: $0 [options]\n\n";
    print "<<<<IMPORTANT NOTICE>>>>>>\n";
    print "SpecPM(Performance Monitor) tool is dependent on the run output of the speccpu suites. So if you want to use $0 for a benchmark or benchset, you MUST have already finished a successful \"runspec\" for it\n";
    print "<<<<END NOTICE>>>>\n\n";
    print "-t Val  Title identifier for this test run \n";
    print "-r Test Which type of test to run\n";
    print "        Test can be either perf or valgrind [perf]\n";
    print "-i Num  Iterations to run for the test\n";
    print "        Num can be any positive integer\n";
    print "-s NAME Run the benchmark set specified\n";
    print "        NAME can be C CPP FORTRAN MIXED INT FP. Does not support multiple benchsets\n";
    print "-b NAME Run the independent benchmark specified\n";
    print "        NAME can be any of the spec benchmark suites such as bzip2, perlbench etc\n";
    print "        You can specify multiple tests by delimiting with a comma eg perlbench,bzip2\n";
    exit;
}

sub parse_args(){
    while (0 != @_){
        my $var = shift @_;
        $options{"benchset"} = shift @_ if ($var =~ m/^-s$/i);
        $options{"benchmark"} = shift @_ if ($var =~ m/^-b$/i);
        $options{"iteration"} = shift @_ if ($var =~ m/^-i$/i);
        $options{"title"} = shift @_ if ($var =~ m/^-t$/i);
        $options{"run"} = shift @_ if ($var =~ m/^-r$/i);
    }
    $options{"iterations"} = 1 if (! defined $options{"iterations"});
    $options{"title"} = "Test" if (! defined $options{"title"});
    $options{"run"} = "perf" if (! defined $options{"run"});
}

sub init(){
#First identify our run count
     
    my $path = abs_path($0);
    die "Cannot change to $resultdir : $!" if (! chdir $resultdir);
    opendir RESDIR, $resultdir;
    my $runNum = 1;
    foreach (readdir RESDIR){
         #$runNum = ($runNum>$2)?$runNum:$2 if (-f and m/^(results)(\d*)(\.log)$/g);
         $runNum = max($runNum, $2) if (-f and m/^(\w*)\.(\d*)(\.log)$/g);
    }
    close RESDIR;
    $runNum += 1;

    my $test = $options{"run"};
    $resultlog = $resultdir . "/$test.$runNum.log";
    $resultcsv = $resultdir . "/$test.$runNum.csv";

    if ($test =~ m/valgrind/ig){
        $runcmd = "valgrind --tool=cachegrind --log-fd=9 9>>$resultlog";
    } else {
    #$perf = "3>>$resultlog perf stat -B -e $perfstat --log-fd 3 --append ";
        $runcmd = "3>>$resultlog perf stat -e $perfstat -x $delimiter --log-fd 3 --append";
    }
#Now chdir to desired working directory
#print "Abs path : $path \n";

#we are on unix so simply strip the filename and append ../spec2006 to reach our target directory

    $workdir = substr($path, 0, rindex($path, "/")) . "/../benchspec/CPU2006";
    #say "$workdir";
    die "Cannot change to $workdir : $!" if (! chdir $workdir);
    $workdir = Cwd::cwd();
}

sub getTests(){
    #if multiple tests, each are seperated by a comma
    my @tests = split ",",$_[0];
    #say "xxx $_[0] and @tests";
    if (! opendir WDIR, $workdir){
        die "Cannot open $workdir : $!";
    }
    my $bset = "";
    #the below logic does not work correctly for all_c.bset
    foreach (readdir WDIR){
        $bset = $_ if (-f and (m/(bset)$/) and (m/$tests[0]/i));
    }
    close WDIR;
    #say $bset;
    #load the bset module and use the array to get the list of tests    
    #need to include spec specific modules if we want to implement this similar to the spec scripts. Instead lets use regex :-)
    my $bsfh;
    die "Cannot open $bset : $!" if (! open $bsfh, '<', $bset);
    #my @tmp = grep {/benchmarks = qw(.*)/ig} <BSFH>;
    #say @tmp;
    local $/;
    my $content = <$bsfh>;
    #print $content;
    my $val;
    if ($content ~~ m/benchmarks = qw\((.*?)\)/isg){
        $val = $1;
        ($val =~ s/^\s+|\s+$//g);#strip leading & ending wsp
        ($val =~ s/\s+/ /g);#multi wsp chars to single space
        #say $val;
    }
    close $bsfh;
    my @testdirs = ();
    @testdirs = split " ", $val if (defined $val);
    #we assume the .bset has valid list of testcases. So we dont cross check if the test does exist as a directory (as we do in -i optio)
    return @testdirs;
}

sub getTrueName(){
    #if multiple tests, each are seperated by a comma
    my @tests = split ",",$_[0];
    #say "xxx $_[0] and @tests";
    if (! opendir WDIR, $workdir){
        die "Cannot open $workdir : $!";
    }
    my @dirs = grep {-d and !(m/^\./)} readdir WDIR;
    #push @dirs if (-d) foreach readdir $workdir;
    close WDIR;
    my @testdirs = ();
    foreach my $name (@tests){
        push @testdirs, grep(/$name/, @dirs);
    }
    return @testdirs;
}

sub translateSpecCMD(){
    my @cmd = ();
    while (@_ != 0){
        my $var = shift @_;
        if ($var =~ m/^-/){
            if ($var =~ m/^-C/g){
                push @cmd, "cd";
                push @cmd, shift @_;
            }
            shift @_ if ($var =~ m/(^-o)|(^-e)|(^-i)/);
        } else {
            push @cmd, $var;
            splice @cmd, 1, 0, @_;
            #@cmd has the run. Prefix it with perf call
            #splice @cmd, 0, 0, $perf;
            splice @cmd, 0, 0, $runcmd;
            return @cmd; 
        }
        
    }
    return @cmd;
}

sub runtest(){
    my $listfile = $workdir . "/$_[0]" . "/run/list";
    my $target;
    open FH, $listfile or die "Cannot open $listfile : $!";
    if (<FH> =~ m/dir=(\S*)/g){
        $target = $1;
    }
    close FH;

    if (defined $target){
        #die "Cannot change to $target : $!" if (! chdir $target);
        my $speccmd = $target . "/speccmds.cmd";
        open FH, $speccmd or die "Cannot open $speccmd : $!";
        #each line in this file is a specinvoke command. Read them into an array
        open my $resFH, '>>', $resultlog;

        while (<FH>){
            #say "Line: $_"
            my @tmp = &translateSpecCMD(split);
            if ($tmp[0] eq "cd"){
                die "Cannot change to $tmp[1] : $!" if (! chdir $tmp[1]);
            } else {
                #say "Line: @tmp";
                my $tmp = join " ", @tmp;
                say "Execute: $tmp";
                printf $resFH "Execute $_[0]:\n";
                system $tmp;
            }
        }
        close $resFH;
        close FH;
        
    }
    #revert back to correct working directory
    die "Cannot change to $workdir : $!" if (! chdir $workdir);
}

sub generatePerfCSV(){
    open my $resFH, '>>', $resultcsv;
    my $title = $options{"title"};
    printf $resFH "$title,$perfstat";

    open LOGFH, $resultlog;
    while (<LOGFH>){
        if (m/^Execute\s?(.*?):/g) {printf $resFH "\n$1,";}
        elsif (m/(.*?)$delimiter.*/) {printf $resFH "$1,";}
    }
    close LOGFH;
    close $resFH;
}

sub generateValgrindCSV(){
    #say "Generating valgrind CSV";
    open my $resFH, '>>', $resultcsv;
    my $title = $options{"title"};
    printf $resFH "$title,$valgrindres";

    open LOGFH, $resultlog;
    while (<LOGFH>){
        if (m/^Execute\s?(.*?):/g) {printf $resFH "\n$1,";}
        elsif (m/(.*?)((refs)|(misses)|(miss rate)):\s+(?<val>\S*).*/) {
            my $val = $+{val};
            $val =~ s/,//g;
            printf $resFH "$val,";
        }
    }
    close LOGFH;
    close $resFH;
}



## Main Run
if (@ARGV == 0) {
    &usage;
}

&parse_args(@ARGV);

while (my ($key, $value) = each %options){
#    print("$key : $value \n");
}

my @tests = ();

if (defined $options{"benchset"}){
    #load the corresponding .bset file and execute each benchmark
    &init();
    @tests = &getTests($options{"benchset"});
} elsif (defined $options{"benchmark"}){
    #goto the correct path of the benchmark. Read the list file and proceed to run it
    &init();
    @tests = &getTrueName($options{"benchmark"});
}

my $tolog = 0;
foreach my $test (@tests){
    #some tests seem not to run. We will skip them here
    next if ($test =~ m/(445\.gobmk)|(447\.dealII)|(416\.gamess)|(433\.milc)|(437\.leslie3d)/g);
    say "Running $test";
    my $i = 0;
    for ($i = 0; $i < $options{"iterations"}; $i+=1){
        &runtest($test);
        $tolog = 1;
    }
    #&runtest($test);
}

if ($tolog != 0){
    my $datetime = `date`;
    say "Results logged into $resultlog on $datetime";

    if ($options{"run"} =~ m/valgrind/ig){
        &generateValgrindCSV();
    } else {
        &generatePerfCSV();
    }
    say "Results csv generated into $resultcsv";
} else {
    say "No testcase run. Nothing to log";
}
