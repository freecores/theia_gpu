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
$NumberOfBanks = $ARGV[1];
$MaxVertexBufferSize = $ARGV[2];
$MaxTextureBufferSize = $ARGV[3];




die "\nusage:\nconfigure_gpu.pl number_of_cores width height\n\n" if (not defined $NumberOfCores );


if (not defined $NumberOfBanks)
{
  $NumberOfBanks = $NumberOfCores;
  print "Number of TMEM banks not specified, making default to Number of execution cores ($NumberOfCores)\n";;
}
if (not defined $MaxVertexBufferSize)
{
	$MaxVertexBufferSize = 7000;
	print "Vertex Buffer Size was no defined\n, making vertex buffer size default value of $MaxVertexBufferSize Bytes\n";
}
if (not defined $MaxTextureBufferSize)
{
	print "Texture Buffer Size was no defined\n, making texture buffer big enough to store 256x256 textures\n";
	$MaxTextureBufferSize = 256*256*3;
}

$DefsPath = "../rtl/aDefinitions.v";
$TopPath = "../rtl/Theia.v";

$TestBenchPath = "../rtl/TestBench_THEIA.v";
$RCOMMIT_O = "assign RCOMMIT_O = wRCommited[0]";
$HDL_O = "assign HDL_O = wHostDataLatched[0]";
$DONE_O = "assign DONE_O = wDone[0]";
$index=$NumberOfCores-1;
$BankRequest = "iRequest( {wBankReadRequest[$index][Bank]";
$SELECT_ALL_CORES = "define SELECT_ALL_CORES `MAX_CORES'b1";

$Scale = 17;

print
"
Applying configuration for:
    $NumberOfCores execution cores
	$NumberOfBanks TMEM banks
";

#------------------------------------------------------------------
for ($i = 1; $i < $NumberOfCores; $i++)
{
	$RCOMMIT_O .= " & wRCommited[$i]";
	$HDL_O .= " &  wHostDataLatched[$i]";
	$DONE_O .= " & wDone[$i]";
	$index=$NumberOfCores-$i-1;
	#print "$NumberOfCores $i: $index\n";
	$BankRequest .= ",wBankReadRequest[$index][Bank]";
	$SELECT_ALL_CORES .= "1";
}


tie my @array, 'Tie::File', $DefsPath or die "Can't open $DefsPath: $!";
foreach (@array) 
{
    s/define MAX_CORES .*(\/\/.*)/define MAX_CORES $NumberOfCores \t\t$1/;
	s/define MAX_TMEM_BANKS .*(\/\/.*)/define MAX_TMEM_BANKS $NumberOfBanks \t\t$1/;
	$MaxCoreBits = log( $NumberOfCores ) / log(2);
	$MaxBankBits = log( $NumberOfBanks ) / log(2);
	$MaxParamSize = (19 + 3*2*$NumberOfCores);

	s/define MAX_CORE_BITS .*(\/\/.*)/define MAX_CORE_BITS $MaxCoreBits \t\t$1/;
	s/define SELECT_ALL_CORES .*(\/\/.*)/$SELECT_ALL_CORES \t\t$1/;
	s/define MAX_TMEM_BITS .*(\/\/.*)/define MAX_TMEM_BITS $MaxBankBits \t\t$1/;
	s/define PARAMS_ARRAY_SIZE .*(\/\/.*)/define PARAMS_ARRAY_SIZE $MaxParamSize \t\t$1/;
	s/define VERTEX_ARRAY_SIZE .*(\/\/.*)/define VERTEX_ARRAY_SIZE $MaxVertexBufferSize \t\t$1/;
	s/define TEXTURE_BUFFER_SIZE .*(\/\/.*)/define TEXTURE_BUFFER_SIZE $MaxTextureBufferSize \t\t$1/;
}
untie @array;



tie my @array, 'Tie::File', $TopPath or die "Can't open $TopPath: $!";
foreach (@array) 
{
    s/assign RCOMMIT_O =.*/$RCOMMIT_O;/;
	s/assign HDL_O =.*/$HDL_O;/;
	s/assign DONE_O =.*/$DONE_O;/;
	s/iRequest\(\s*{wBankReadRequest.*/$BankRequest}\),/;
	
}
untie @array;

$MaxFileLines = 96 + 3*2*$NumberOfCores;
tie my @array, 'Tie::File', $TestBenchPath or die "Can't open $TestBenchPath: $!";
foreach (@array) 
{
    s/reg\s+\[31\:0\]\s+rSceneParameters.*/reg [31:0] rSceneParameters[$MaxFileLines:0];/;
}	
untie @array;

