#!/usr/bin/perl

use strict;
use Cwd;
use File::Copy;
use File::Find;
use HTTP::Date;
use Data::Dumper;


my $RegressionsDirectory 			= "../regressions/single_core/";
my $CompilerDir 					= "../compiler/bin/";
my $SimulatonResultFile 			= "test_result.log";
my $TestConfig						= undef;
my $Option_Quiet 					= 1;
#Set the debug option from the command line
$Option_Quiet = 0 if (defined $ARGV[0] and $ARGV[0] == "-debug");

#Check to see if the necessary bash scripts are present and have
#the proper execution permissions
die "-E- '$CompilerDir/theia_compile' does not exists or does not have execute permissions\n" 	if (not -e "$CompilerDir/theia_compile" 	or not -x "$CompilerDir/theia_compile");
die "-E- '$CompilerDir/theia_vp_compile' does not exists or does not have execute permissions\n" 	if (not -e "$CompilerDir/theia_vp_compile" 	or not -x "$CompilerDir/theia_vp_compile");
die "-E- '$CompilerDir/theia_cp_compile' does not exists or does not have execute permissions\n" 	if (not -e "$CompilerDir/theia_cp_compile" 	or not -x "$CompilerDir/theia_cp_compile");

#Set the enviroment variable THEIA_PROJECT_FOLDER
#this variable is used by the compiler wrapper bash
#scripts under $CompilerDir
my $tmp = `pwd`; 
chomp $tmp;
$tmp .= "/../";
$ENV{'THEIA_PROJECT_FOLDER'} = $tmp;
print "THEIA_PROJECT_FOLDER = $ENV{'THEIA_PROJECT_FOLDER'}\n" if ($Option_Quiet == 0);


#find all the *.vp files
my @Tests =  <$RegressionsDirectory/*.vp>;
for my $Test (@Tests)
{
	print sprintf("Running test %-60s  ",$Test);
	#Compile the test
	print "\nCommand: $CompilerDir/theia_compile $Test\n" if ($Option_Quiet == 0);
	my $CompilationOutput = `source $CompilerDir/theia_compile $Test`;
	if ($CompilationOutput =~ /ERROR/)
	{
		print $CompilationOutput;
		print "ERROR: theia_compile failed!\n";
		`rm *.mem`;
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
		`rm *.mem`;
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
	while (<CONFIG_FILE>)
	{
		$Line++;
		next if m/\/\/.*/;		#skip comments
		#print "* $_ \n";
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
				if (not ($RegValue =~ m/$ExpectedValue/))
				{
					$Failed = 1;
					print "\n\t ASSERTION : Expecting vp[ $vpindex ].r[ $index ] == '$ExpectedValue', but simulation has value '$RegValue' \n";
				} 
			
			} elsif ($block =~ m/omem\[\s*(\d+)\s*\]/) {		#get the OMEM <index>, expr omem[ <index> ]
			
				my $index = $1;
				
				
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
