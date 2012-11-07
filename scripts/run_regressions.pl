#!/usr/bin/perl

use strict;
use Cwd;
use File::Copy;
use File::Find;
use HTTP::Date;
use Data::Dumper;


my $RegressionsDirectory = "../regressions/single_core/";
my $CompilerDir = "../compiler/bin/";
my $SimulatonResultFile = "test_result.log";
my $Option_Quiet = 1;
my $TestConfig;
my $UserTest = undef;
#Set the enviroment variable THEIA_PROJECT_FOLDER
my $tmp = `pwd`; 
chomp $tmp;
$tmp .= "/../";
$ENV{'THEIA_PROJECT_FOLDER'} = $tmp;

#find all the *.vp files

my @Tests;
if (not defined $ARGV[0])
{
  @Tests =  <$RegressionsDirectory/*.vp>;
} else {

  $UserTest = "$RegressionsDirectory/$ARGV[0]";
  die "Test $UserTest not found\n" if (not -e "$UserTest");
  @Tests = ($UserTest);
}
for my $Test (@Tests)
{
	print sprintf("Running test %-60s  ",$Test);
	#Compile the test
	my $CompilationOutput = `$CompilerDir/theia_compile $Test`;
	if ($CompilationOutput =~ /ERROR/)
	{
		print $CompilationOutput;
		print "ERROR: theia_compile failed!\n";
		`ls *.mem | grep -v tmem.mem | xargs rm `;
		next;
	}
	print $CompilationOutput if ($Option_Quiet == 0);
	#Run the test
	my $SimulationOutput = `make run`;
	print $SimulationOutput if ($Option_Quiet == 0);


	#now check for the existance of the test_config file
	my $TestBaseName = `basename $Test .vp`; 
	chomp $TestBaseName;
	$TestConfig =  $RegressionsDirectory . "/" . $TestBaseName . ".config";

	if (not -e $TestConfig)
	{
		print "ERROR: test configuration file $TestConfig does not exist\n";
		`ls *.mem | grep -v tmem.mem | xargs rm `;
		next;
	}
	ParseConfigFile( $TestConfig );
	
	
	
	
	
}
print "Ran " .@Tests .  " tests\n";
#-------------------------------------------------------------------------
sub ParseConfigFile
{
	my $ConfigFile = shift;
	my $Line = 0;
	my $Failed = 0;
	my $block, my $vp;
	my $vpindex;
	open CONFIG_FILE , $ConfigFile or die "Could not open $ConfigFile : $!\n";
	print "Parsing configuration file $ConfigFile\n" if ($Option_Quiet == 0);
	while (<CONFIG_FILE>)
	{
		$Line++;
		next if m/\/\/.*/;		#skip comments
		if (m/==/)
		{
			(my $left, my $ExpectedValue) = split /==/;
			$ExpectedValue =~ s/\s+//g;
			chomp $ExpectedValue;
			#print "left $left\n";
			#print "ExpectedValue $ExpectedValue\n";
			( $vp,  $block) = split (/\./,$left);
			
			if ($vp =~ m/vp\[\s*(\d+)\s*\]/)	#get the vp <index>, expr vp[ <index> ]
				{ 	$vpindex = $1; } 
			else 
				{ die "Error line $Line: Invalid left had side '$vp'\n"; }
			#Now get the block type
			if ($block =~ m/r\[\s*(\d+)\s*\]/) 					#get the register <index>, expr r[ <index> ]
			{
				my $index = $1;
				my $log_file = "rf.vp." . $vpindex . ".log";
				die "Could not open $log_file  : $!\n" if (not -e $log_file);
				my $RegValue = `grep r$index $log_file| awk '{print \$2 \$3 \$4}'`;
				chomp $RegValue;
				if (not ($RegValue =~ m/$ExpectedValue/))
				{
					$Failed = 1;
					print "\n\t ASSERTION : Expecting vp[ $vpindex ].r[ $index ] == '$ExpectedValue', but simulation has value '$RegValue' \n";
				} 
			
			} elsif ($block =~ m/omem\[\s*(\d+)\s*\]/) {		#get the OMEM <index>, expr omem[ <index> ]
			
				my $index = $1;
				my $log_file = "OMEM.vp." . $vpindex . ".log";
				die "Could not open $log_file  : $!\n" if (not -e $log_file);
				print "Expected Value:  $ExpectedValue\n" if ($Option_Quiet == 0);
				my $GrepString;
				$GrepString = sprintf("grep @%02d %s| awk '{print  $2 }'",$index,$log_file);
				my $OmemValue = `$GrepString`;
				chomp $OmemValue;
				print " $GrepString\n" if ($Option_Quiet == 0);
				if (not ($OmemValue =~ m/$ExpectedValue/))
				{
					$Failed = 1;
					print "\n\t ASSERTION : Expecting vp[ $vpindex ].omem[ $index ] == '$ExpectedValue', but simulation has value '$OmemValue' \n";
				} 
				
			} else {
				die "Error parsing '$ConfigFile' unknown block type '$block'\n";
			}
						
			
		}
		
		
	}
	if ($Failed == 0)
	{
		print "Test passed\n";
	} else {
		print "Teset failed\n"
	}
	
	close CONFIG_FILE;
}
#-------------------------------------------------------------------------
