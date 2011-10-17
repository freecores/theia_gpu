#!/usr/bin/perl

# This is the main simulation environment laucnher script.
# It will create a regression area under a folder with a
# unique name.
#
#
#
#

use strict;
use Cwd;
use File::Copy;
use File::Find;
use HTTP::Date;
use Data::Dumper;
#use File::Copy::Recursive;

#Globals
my $SimulationCommand          = undef;
my @SimulationFiles            = undef;
my $SimulationBinary           = undef;
my $RegressionTargetDirectory  = undef;
my %TestList                   = undef;


my 
$ScriptPath = getcwd();
print "Running from $ScriptPath\n";
#Read the configuration from this file
eval Slurp( "testlist.pl" );
die "-E- Errors in configuration file!\n".$@."\n" if($@);


CreateTargetTree( $RegressionTargetDirectory );



#----------------------------------------------------------------
sub CreateTargetTree
{
  my $DestinationPath = shift;
  my ($date, $time) = split(" ", HTTP::Date::time2iso());
  $time =~ s/:/_/g;
  my $RegDir = "$RegressionTargetDirectory/regression_${date}_${time}";
  mkdir $RegDir or die "Cannot create regression folder '$RegDir' $!\n";

  #Create the regression.log
  open LOG, ">$RegDir/regression.log" or die "Cannot create file regression log file '$RegDir/Regression.log' $!\n";
  print LOG "Regression Test-bench started at $date ,time $time\n";
  

  #for my $i (0 .. $#TestList)
  #print Dumper(%TestList);
  for my $TestName (keys %TestList)
  {
	chdir $ScriptPath;
	my $TestPath = $TestList{$TestName}->{'path'};
	
		
		 
		print LOG "-----------------------------------------------------------------------------------\n";
		print LOG "Scene: '$TestName'\n";
        my $TestDir = "$RegDir/$TestName";
        mkdir $TestDir;
        #Copy compulsory files
        copy("$TestPath/Vertex.mem","$TestDir/") or die "-E- $TestPath/Vertex.mem $!\n";
        copy("$TestPath/Params.mem","$TestDir/") or die "-E- $TestPath/Params.mem $!\n";
        copy("$TestPath/Creg.mem","$TestDir/") or die "-E- $TestPath/Config.mem $!\n";
        copy("$TestPath/Reference.ppm","$TestDir/") or die "-E- $TestPath/Reference.ppm $!\n";
		copy("$TestPath/Textures.mem","$TestDir/") or die "-E- $TestPath/Textures.ppm $!\n";
		copy("$TestPath/Instructions.mem","$TestDir/") or die "-E- $TestPath/Instructions.ppm $!\n";


        #Copy the Source files just in case..
        mkdir "$RegDir/rtl";
        
        find
          (
          sub{  next if !m/.*\.v/; copy( $File::Find::name,"$RegDir/rtl")  or die ("Cannot Copy '" . $_ . "' : $!\n") },
          ("../rtl/")
          );
 
#Compile the test code 
#print Dumper($TestList{$TestName});
my $CoreCount = $TestList{$TestName}->{core_count};
my $MemBankCount = $TestList{$TestName}->{mem_bank_count}; 
printf 
  "
    Compiling Code
	Number of execution cores: $CoreCount
	Number of texture memory banks: $MemBankCount
  ";
  
  chdir "../simulation";
  if ( system("make compile GPUCORES=$CoreCount GPUMEMBANKS=$MemBankCount") != 0)
  {
	die "-E- Error compiling test code! ($!)\n";
  }
 #Now copy the binary over to our simulation directory
 
 
 copy("$SimulationBinary","$TestDir/") or die "-E- $SimulationBinary $!\n";
        
        printf
 "
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 ** Theia Regression Started **

 
 Regression Target Directory:
 '$TestDir'
 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 ";


        #Execute the Simulation
        chdir $TestDir;
        my ($StartDate,$StartTime) =   split(" ", HTTP::Date::time2iso());
        print LOG "Simulation started at:             $StartDate $StartTime\n";
		print LOG "Number of execution cores:         $CoreCount\n";
		print LOG "Number of memory banks:            $MemBankCount\n";
        #system "$SimulationCommand -tclbatch isim.tcl";
		if (system ("perl $ScriptPath/configure_params.pl $CoreCount") != 0)
		{
			die "-E- Error configuing scene parameters! ($!)\n";
		}
		
		if (system("vvp -n $SimulationBinary -none") != 0)
		{
		  print LOG "-E- Error running simulation! ($!)\n";
		}
		
        my ($EndDate,$EndTime) =   split(" ", HTTP::Date::time2iso());
        print LOG "Simulation Completed at $EndDate $EndTime\n";
        if (  $StartDate eq $EndDate)
        {
          my ($StartHour,$StartMinute) = split ":",$StartTime;
          my ($EndHour,$EndMinute) = split ":",$EndTime;
          print LOG "Elapsed time "
           . ($EndHour - $StartHour) . " : " . ($EndMinute - $StartMinute) . "\n";
        } else {
          print LOG "Simulation ran for more than 1 day\n";
        }
    ParseOutputPPM( $TestDir );
    
   # system("perl D:/\Proyecto/\RTL/\Scripts/calculate_stats.pl $TestDir/\CU.log $RegDir/\Regression.log $TestDir/\Simulation.log");

  }
close LOG;

  

}

#---------------------------------------------------------------- \
sub Slurp
{
    my $file = shift;
    open F, "< $file" or die "Error opening '$file' for read: $!";
    local $/ = undef;
    my $string = <F>;
    close F;
    return $string;
}
#----------------------------------------------------------------
sub ParseOutputPPM()
{
  my $TestDir = shift;
  open FILE, "$TestDir/Output.ppm" or die "Can't open  $TestDir/Output.ppm !$\n";
  my $i = 1;
  my $CurrentRow;
 my $CurrentCol;
  while (<FILE>)
  {
  
   if (m/^#\s*(\d+)\,\s+(\d+)/)
   {
 $CurrentRow = $1;
 $CurrentCol = $2;
   } 

   # m/\s*(\d)\s+(\d)\s+(\d).*/;
    if (m/x+/g)
    {
      print LOG "FATAL ERROR: 'Output.ppm' Found 'x' at row = $CurrentRow , col = $CurrentCol = $2, line $i\n" ;
      last;
      return;
    }
     $i++;
  }
  close FILE;
}

