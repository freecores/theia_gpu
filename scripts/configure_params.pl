#!/usr/bin/perl
################################################################
#Theia, Ray Cast Programable graphic Processing Unit.
#Copyright (C) 2010  Diego Valverde (diego.valverde.g@gmail.com)
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public #License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  #02110-1301, USA.
################################################################

use Tie::File;
$NumberOfCores = $ARGV[0];
$Widht = $ARGV[1];
$Height = $ARGV[2];

die "\nusage:\nconfigure_gpu.pl number_of_cores [width height]\n\n" if (not defined $NumberOfCores);
$ParamsFile = "Params.mem";
$index=$NumberOfCores-1;

$Scale = 17;



#------------------------------------------------------------------
tie my @array, 'Tie::File', $ParamsFile or die "Can't open $ParamsFile: $!";
$size = @array;

for ($i = 7; $i < $size; $i++) {$array[$i] = "";} 
if (not defined $Widht and not defined $Height)
{
	print $array[5]; 
	$array[5] =~ m/(\w+)\s+(\w+).*/g;
	$Widht = hex($1) / (2 ** $Scale);
	$Height = hex($2) / (2 ** $Scale)
}

print
"
Scene resolution: $Widht x $Height
";


	$ScaledWidht  = sprintf('%X', $Widht * (2 ** $Scale));
	$ScaledHeight = sprintf('%X', $Height *(2 ** $Scale));
	$Delta = $Height / $NumberOfCores;
	print "Separating proyection plane into $NumberOfCores blocks of $Delta rows\n";
	$array[0] = sprintf('%X',3*(6+$NumberOfCores*2));
	$array[5] = "$ScaledWidht $ScaledHeight 0\t//<Width>, <Height>,<NULL>";
	for ($i = 0,$k = 0; $i < $NumberOfCores; $i++,$k+=2)
	{
		$InitialRow = sprintf('%X', $i*$Delta *(2 ** $Scale));
		$FinalRow   = sprintf('%X', ($i+1)*$Delta *(2 ** $Scale));
		$array[7+$k]   = "0 $InitialRow 0\t\t //Core $i Start";
		$array[7+$k+1] = "$ScaledWidht $FinalRow 0\t\t //Core $i End";
	}

	
untie @array;