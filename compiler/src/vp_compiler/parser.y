
/**********************************************************************************
Theia, Ray Cast Programable graphic Processing Unit.
Copyright (C) 2012  Diego Valverde (diego.valverde.g@gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

***********************************************************************************/

 
%require "2.4.1"
%skeleton "lalr1.cc"
%defines
%error-verbose
%locations
%define namespace "Theia"
%define parser_class_name "Parser"
%parse-param { Theia::Scanner &scanner }
%parse-param { std::map<std::string,unsigned int>  & mSymbolMap }
%parse-param { std::vector< Instruction > &mInstructions }
%parse-param { bool &mGenerateFixedPointArithmetic }
%lex-param   { Theia::Scanner &scanner }

%code requires {
	#include <string>
	#include <sstream>
	#include <iomanip>
	#include <bitset>
	#include <map>
	#include "Instruction.h"
	#include <vector>
	

	// We want to return a string
	#define YYSTYPE std::string

	
		namespace Theia
		{
			// Forward-declare the Scanner class; the Parser needs to be assigned a 
			// Scanner, but the Scanner can't be declared without the Parser
			class Scanner;
		
			// We use a map to store the INI data
			typedef std::map<std::string, std::map<std::string, std::string> > mapData;
			
			
			


		}
	
}

%code 
{
	#include "Instruction.h"
	#include <vector>
	Instruction I,tmpI;
	
	std::vector< unsigned int > gBranchStack;
	static int gInsertedInstructions = 0;
	static int gWhileLoopAddress = 0;
#define FUNCTION_PARAM_START_REGION 4
#define FUNCTION_PARAM_LAST_REGION  10
	std::map<std::string, unsigned int> gFunctionParameters;
	std::map<std::string, unsigned int> gAutoVarMap;
	std::map<std::string, unsigned int> gThreadMap; //Key: Symbol, value: start code addr
	bool gThreadScope = false;
#define AUTOVAR_START_REGION 9
#define THREAD_OFFSET 128
unsigned int gExtraDestModifications = 0;
unsigned int gAutoVarIndex = AUTOVAR_START_REGION;
unsigned int gThreadAutoVarIndex = THREAD_OFFSET;
unsigned int gFunctionParameterIndex = FUNCTION_PARAM_START_REGION;
//----------------------------------------------------------
unsigned int GetNextFunctionParamRegister()
{
	unsigned Ret = gFunctionParameterIndex++;
	return Ret;
}

//----------------------------------------------------------
void AddFunctionParameter( std::string aVar, Theia::Parser::location_type  yylloc)
{
	////std::cout << "Adding " << aVar << "\n";
	if (gFunctionParameterIndex+1 > FUNCTION_PARAM_LAST_REGION)
	{
			std::ostringstream ret;
			ret << "Cannot allocate more parameters '" << aVar << "' at line " << yylloc << " \n";
			throw ret.str();
	}
	if (gFunctionParameters.find(aVar) != gFunctionParameters.end())
	{
			std::ostringstream ret;
			ret << "Parameter '" << aVar << "' at line " << yylloc << " is already defined\n";
			throw ret.str();
	}
	
	gFunctionParameters[ aVar ] = gFunctionParameterIndex++;
	
}
//----------------------------------------------------------
std::string  GetRegisterFromFunctionParameter( std::string aVar )
{
	////std::cout << "Looking for " << aVar << "\n";
	if (gFunctionParameters.find(aVar) == gFunctionParameters.end())
		return "NULL";
	
	std::ostringstream ss;
	ss << gFunctionParameters[ aVar ];
	return  ("R" + ss.str());
}
//----------------------------------------------------------
unsigned int GetCurretAutoVarFrameSize()
{
	
	return gAutoVarMap.size();
	
}
//----------------------------------------------------------
std::string GetRegisterFromAutoVar( std::string aVar, Theia::Parser::location_type  yylloc )
{
	if (gAutoVarMap.find(aVar) == gAutoVarMap.end())
	{
			std::ostringstream ret;
			ret << "Undefined variable '" << aVar << "' at line " << yylloc << " \n";
			throw ret.str();
	}
			
		std::ostringstream ss;
		ss << gAutoVarMap[ aVar ];
		return  ("R" + ss.str());
}
//----------------------------------------------------------
int GetCurrentLineNumber( const Theia::Parser::location_type &loc )
{
		int ret = -1;
		std::stringstream ss2;
		std::string where;
		ss2 << loc;
		ss2 >> where;
		where.erase(where.find_first_of("."));
		std::stringstream ss3;
		ss3 << where;
		ss3 >> ret;
		return ret;
}
//----------------------------------------------------------
unsigned int AllocAutoVar( unsigned int aSize = 1)
{
		
	if (!gThreadScope)
	{
		gAutoVarIndex += aSize;
		return gAutoVarIndex - (aSize-1);
	}else{
		gThreadAutoVarIndex += aSize;
		return (gThreadAutoVarIndex - (aSize-1));
	}
}
//----------------------------------------------------------
void ClearFunctionParameterMap()
{	
	gFunctionParameters.clear();
	gFunctionParameterIndex = FUNCTION_PARAM_START_REGION;
}
//----------------------------------------------------------
void ClearAutoVarMap()
{
	gAutoVarMap.clear();
	gAutoVarIndex = AUTOVAR_START_REGION;
}
//----------------------------------------------------------
unsigned int gTempRegisterIndex = 1;
unsigned int GetFreeTempRegister( )
{
	if (!gThreadScope)
		return gAutoVarIndex + (gTempRegisterIndex++);
	else
		return gThreadAutoVarIndex + (gTempRegisterIndex++);
	
}
//----------------------------------------------------------			
void ResetTempRegisterIndex( void )
{
	
	gTempRegisterIndex = 1;
}	
//----------------------------------------------------------
bool IsSwizzled( std::string aSource)
{
	if (aSource.find(".") != std::string::npos)
		return true;
	else
		return false;
}

//----------------------------------------------------------
void SetSwizzleAndSign( unsigned int aSourceIndex, std::string aSwizzle, Instruction & I )
{
	std::string Reg,X,Y,Z, junk;
	std::stringstream ss( aSwizzle );
	ss >> Reg >> junk >> X >> Y >> Z;
	
	
	if (aSourceIndex == 1)
	{
		if (X == "X") { I.SetSrc1SwizzleX(SWX_X); 	}
		if (X == "Y") { I.SetSrc1SwizzleX(SWX_Y); 	}
		if (X == "Z") { I.SetSrc1SwizzleX(SWX_Z); 	}
		if (X == "-X") { I.SetSrc1SignX( true ); I.SetSrc1SwizzleX(SWX_X); 	}
		if (X == "-Y") { I.SetSrc1SignX( true ); I.SetSrc1SwizzleX(SWX_Y); 	}
		if (X == "-Z") { I.SetSrc1SignX( true ); I.SetSrc1SwizzleX(SWX_Z); 	}
		
		if (Y == "X") { I.SetSrc1SwizzleY(SWY_X); 	}
		if (Y == "Y") { I.SetSrc1SwizzleY(SWY_Y); 	}
		if (Y == "Z") { I.SetSrc1SwizzleY(SWY_Z); 	}
		if (Y == "-X") { I.SetSrc1SignY( true ); I.SetSrc1SwizzleY(SWY_X); 	}
		if (Y == "-Y") { I.SetSrc1SignY( true ); I.SetSrc1SwizzleY(SWY_Y); 	}
		if (Y == "-Z") { I.SetSrc1SignY( true ); I.SetSrc1SwizzleY(SWY_Z); 	}
		
		if (Z == "X") { I.SetSrc1SwizzleZ(SWZ_X); 	}
		if (Z == "Y") { I.SetSrc1SwizzleZ(SWZ_Y); 	}
		if (Z == "Z") { I.SetSrc1SwizzleZ(SWZ_Z); 	}
		if (Z == "-X") { I.SetSrc1SignZ( true ); I.SetSrc1SwizzleZ(SWZ_X); 	}
		if (Z == "-Y") { I.SetSrc1SignZ( true ); I.SetSrc1SwizzleZ(SWZ_Y); 	}
		if (Z == "-Z") { I.SetSrc1SignZ( true ); I.SetSrc1SwizzleZ(SWZ_Z); 	}
	} else {
		if (X == "X") { I.SetSrc0SwizzleX(SWX_X); 	}
		if (X == "Y") { I.SetSrc0SwizzleX(SWX_Y); 	}
		if (X == "Z") { I.SetSrc0SwizzleX(SWX_Z); 	}
		if (X == "-X") { I.SetSrc0SignX( true ); I.SetSrc0SwizzleX(SWX_X); 	}
		if (X == "-Y") { I.SetSrc0SignX( true ); I.SetSrc0SwizzleX(SWX_Y); 	}
		if (X == "-Z") { I.SetSrc0SignX( true ); I.SetSrc0SwizzleX(SWX_Z); 	}
		
		if (Y == "X") { I.SetSrc0SwizzleY(SWY_X); 	}
		if (Y == "Y") { I.SetSrc0SwizzleY(SWY_Y); 	}
		if (Y == "Z") { I.SetSrc0SwizzleY(SWY_Z); 	}
		if (Y == "-X") { I.SetSrc0SignY( true ); I.SetSrc0SwizzleY(SWY_X); 	}
		if (Y == "-Y") { I.SetSrc0SignY( true ); I.SetSrc0SwizzleY(SWY_Y); 	}
		if (Y == "-Z") { I.SetSrc0SignY( true ); I.SetSrc0SwizzleY(SWY_Z); 	}
		
		if (Z == "X") { I.SetSrc0SwizzleZ(SWZ_X); 	}
		if (Z == "Y") { I.SetSrc0SwizzleZ(SWZ_Y); 	}
		if (Z == "Z") { I.SetSrc0SwizzleZ(SWZ_Z); 	}
		if (Z == "-X") { I.SetSrc0SignZ( true ); I.SetSrc0SwizzleZ(SWZ_X); 	}
		if (Z == "-Y") { I.SetSrc0SignZ( true ); I.SetSrc0SwizzleZ(SWZ_Y); 	}
		if (Z == "-Z") { I.SetSrc0SignZ( true ); I.SetSrc0SwizzleZ(SWZ_Z); 	}
	}
}
//----------------------------------------------------------
void StoreReturnAddress( std::vector<Instruction> & aInstructions, Theia::Parser::location_type & yylloc )
{
		I.SetCode( EOPERATION_ADD );
		I.mComment = "store return address**";
		I.SetImm( aInstructions.size()+4 );
		I.SetWriteChannel(ECHANNEL_X);
		I.SetDestinationAddress( RETURN_ADDRESS_REGISTER );
		I.SetDestZero( true );
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		aInstructions.push_back( I );
		I.Clear();
}
//----------------------------------------------------------
void SavePreviousFramePointer( std::vector<Instruction> & aInstructions )
{
		I.SetCode( EOPERATION_ADD );
		I.mComment = "store current frame offset";
		I.SetWriteChannel(ECHANNEL_Y);
		I.SetDestinationAddress( SPR_CONTROL_REGISTER );
		I.SetSrc1Address(SPR_CONTROL_REGISTER);
		I.SetSrc1SwizzleX(SWX_X);
		I.SetSrc1SwizzleY(SWY_X);
		I.SetSrc1SwizzleZ(SWZ_X);
		I.SetSrc0Address(0);
		I.SetSrc0SwizzleX(SWX_X);
		I.SetSrc0SwizzleY(SWY_X);
		I.SetSrc0SwizzleZ(SWZ_X);
		aInstructions.push_back( I );
		I.Clear();
}
//----------------------------------------------------------
void SetIndexRegister( unsigned int aIndex, std::vector<Instruction> & aInstructions  )
{
		Instruction Tmp;
		Tmp.SetCode( EOPERATION_ADD );
		Tmp.mComment = "store array index register";
		Tmp.SetWriteChannel(ECHANNEL_Z);
		Tmp.SetDestinationAddress( SPR_CONTROL_REGISTER );
		Tmp.SetSrc1Address( aIndex );
		Tmp.SetSrc1Displace( true );
		Tmp.SetSrc1SwizzleX(SWX_X);
		Tmp.SetSrc1SwizzleY(SWY_X);
		Tmp.SetSrc1SwizzleZ(SWZ_X);
		Tmp.SetSrc0Address(0);
		Tmp.SetSrc0SwizzleX(SWX_X);
		Tmp.SetSrc0SwizzleY(SWY_X);
		Tmp.SetSrc0SwizzleZ(SWZ_X);
		//Tmp.SetImm( aIndex );
		//Tmp.SetDestZero( true );
		aInstructions.push_back( Tmp );
		
}
//----------------------------------------------------------
void UpdateFramePointer( std::vector<Instruction> & aInstructions )
{
		I.SetCode( EOPERATION_ADD );
		I.mComment = "displace next frame offset by the number of auto variables in current frame";
		I.SetWriteChannel(ECHANNEL_X);
		I.SetDestinationAddress( SPR_CONTROL_REGISTER );
		I.SetImm( GetCurretAutoVarFrameSize() );
		I.SetDestZero( false );
		aInstructions.push_back( I );
		I.Clear();
}
//----------------------------------------------------------
void CallFunction( std::string aFunctionName,  std::vector<Instruction> & aInstructions, std::map<std::string,unsigned int>  &  aSymbolMap)
{
		I.SetCode( EOPERATION_ADD );
		I.mComment = "call the function";
		I.SetBranchFlag( true );
		I.SetBranchType( EBRANCH_ALWAYS );
		//Now do the branch
		if (aSymbolMap.find(aFunctionName) == aSymbolMap.end())
			I.SetDestinationSymbol( "@"+aFunctionName );
		else 
			I.SetDestinationAddress( aSymbolMap[ aFunctionName ] );
		
		aInstructions.push_back( I );
		I.Clear();
}
//----------------------------------------------------------
void SetDestinationFromRegister( std::string aDestination, Instruction & aInst, bool Imm  )
{
		//Look for displament addressing mode
				
		if (aDestination.find("OFFSET") != std::string::npos)
		{
			aDestination.erase(aDestination.find("OFFSET"));
			////std::cout << "^_^ left_hand_side " << Destination << "\n";
			if (Imm == true)
				aInst.SetSrc0Displace( true ); //When Imm == 0, then setting this makes offset
			else
				aInst.SetDestZero( true ); //When Imm != 0, DestZero means DST = DSTINDEX + offset
		}
		if (aDestination.find(".") != std::string::npos)
		{
			aInst.ClearWriteChannel();
			if (aDestination.find("x") != std::string::npos)
				aInst.SetWriteChannel(ECHANNEL_X);
			if (aDestination.find("y") != std::string::npos)
				aInst.SetWriteChannel(ECHANNEL_Y);
			if (aDestination.find("z") != std::string::npos)
				aInst.SetWriteChannel(ECHANNEL_Z);

			aDestination.erase(aDestination.find("."));
			
		}
		aInst.SetDestinationAddress( atoi(aDestination.c_str()+1) );
}
//----------------------------------------------------------
void PopulateSourceRegisters( std::string a1, std::string a2, Instruction & I, std::vector<Instruction> & aInstructions )
{


			if ( a1.find("R") == std::string::npos )
			{
				//This is for constants
				unsigned int ImmediateValue;
				std::string StringHex = a1;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				I.SetImm( ImmediateValue );
			} else {
			
			
			
				if (a1.find("array_element") != std::string::npos)
				{
					
			
					std::string Index = a1.substr(a1.find("array_element"));
					////std::cout << "XXXXX " << Index << "\n\n\n";
					Index = Index.substr(Index.find_first_not_of("array_element R"));
					////std::cout << "XXXXX " << Index << "\n\n\n";
					SetIndexRegister( atoi(Index.c_str()), aInstructions );
					a1.erase(a1.find("array_element"));
					I.SetSrc0Displace( true ); 
					I.SetSrc1Displace( true ); 
					I.SetImmBit( true );
				}
					//Look for displament addressing mode
				else if (a1.find("OFFSET") != std::string::npos)
				{
					a1.erase(a1.find("OFFSET"));
					////std::cout << "^_^ a1" << a1 << "\n";
					I.SetSrc1Displace( true ); //When Imm != 0, DestZero means DST = DSTINDEX + offset
				}
				
				std::string Src1 = a1;
				if (IsSwizzled( Src1 ))
				{
					SetSwizzleAndSign( 1, Src1,  I );
					Src1.erase(Src1.find("."));
				}
				I.SetSrc1Address( atoi( Src1.c_str()+1 ) );
			}
			
			if ( a2.find("R") == std::string::npos)
			{
			} else {
			
				
			
				//Look for displament addressing mode
				if (a2.find("OFFSET") != std::string::npos)
				{
					a2.erase(a2.find("OFFSET"));
					////std::cout << "^_^ a2 " << a2 << "\n";
					I.SetSrc0Displace( true ); //When Imm != 0, DestZero means DST = DSTINDEX + offset
				}
			
				std::string Src0 = a2;
				if (IsSwizzled( Src0 ))
				{
					SetSwizzleAndSign( 0, Src0,  I );
					Src0.erase(Src0.find("."));
				}
				I.SetSrc0Address( atoi( Src0.c_str()+1 ) );
			}	
}
//----------------------------------------------------------
void ClearNextFunctionParamRegister()
{
	gFunctionParameterIndex = FUNCTION_PARAM_START_REGION;
}
//----------------------------------------------------------
void AddFunctionInputList( std::string aVar, std::vector<Instruction> & aInstructions,Theia::Parser::location_type  yylloc)
{
	//Get the value from the variable
	DCOUT << "Calling AddFunctionInputList input arg: " << aVar << " \n";
	//Copy the value into function parameter register
	unsigned FunctionParamReg = GetNextFunctionParamRegister();
	I.Clear();
	I.SetCode( EOPERATION_ADD );
	I.mComment = "copy the value into function parameter register";
	I.SetWriteChannel(ECHANNEL_XYZ);
	//I.SetDestZero( true ); //When Imm != 0, DestZero means DST = DSTINDEX + offset
	I.SetDestinationAddress( FunctionParamReg );
	
	if (aVar.find("R") != std::string::npos)
	{
		if (aVar.find("OFFSET") != std::string::npos)
		{
			I.SetSrc1Displace( true );
			aVar.erase(aVar.find("OFFSET"));
		}
		I.SetSrc1Address(atoi(aVar.c_str()+1));
		I.SetSrc1SwizzleX(SWX_X);
		I.SetSrc1SwizzleY(SWY_Y);
		I.SetSrc1SwizzleZ(SWZ_Z);
		I.SetSrc0Address(0);
		I.SetSrc0SwizzleX(SWX_X);
		I.SetSrc0SwizzleY(SWY_X);
		I.SetSrc0SwizzleZ(SWZ_X);
		aInstructions.push_back( I );
		I.Clear();
		return;
	}
	std::string Reg = GetRegisterFromFunctionParameter( aVar );
	if (Reg == "NULL")
	{
		Reg = GetRegisterFromAutoVar( aVar, yylloc );
		I.SetSrc1Address(atoi(Reg.c_str()+1));
		I.SetSrc1Displace( true );
	} else {
		I.SetSrc1Address(atoi(Reg.c_str()+1));
		I.SetSrc1Displace( false );
	}
	
	
	
	I.SetSrc1SwizzleX(SWX_X);
	I.SetSrc1SwizzleY(SWY_Y);
	I.SetSrc1SwizzleZ(SWZ_Z);
	I.SetSrc0Address(0);
	I.SetSrc0SwizzleX(SWX_X);
	I.SetSrc0SwizzleY(SWY_X);
	I.SetSrc0SwizzleZ(SWZ_X);
	aInstructions.push_back( I );
	I.Clear();
}
//----------------------------------------------------------
void SetExpressionDestination( std::string aStringDestination, Instruction & I )
{
		std::string Destination = aStringDestination;
		
		//Look for indirect addressing
		if (Destination.find("INDEX") != std::string::npos)
		{
			
			std::string IndexRegister = Destination.substr(Destination.find("INDEX")+5);
			Destination.erase(Destination.find("INDEX"));
			I.SetImm( 0 );
			I.SetCode( EOPERATION_ADD );
			
			if (Destination.find(".") != std::string::npos)
			{
				I.ClearWriteChannel();
				if (Destination.find("x") != std::string::npos)
					I.SetWriteChannel(ECHANNEL_X);
				if (Destination.find("y") != std::string::npos)
					I.SetWriteChannel(ECHANNEL_Y);
				if (Destination.find("z") != std::string::npos)
					I.SetWriteChannel(ECHANNEL_Z);
				Destination.erase(Destination.find("."));
		
			}
						
			I.SetDestinationAddress( atoi(Destination.c_str()+1) );
			
		} else {
		
			//Look for displament addressing mode
			if (Destination.find("OFFSET") != std::string::npos)
			{
				Destination.erase(Destination.find("OFFSET"));
				I.SetDestZero( true ); //When Imm != 0, DestZero means DST = DSTINDEX + offset
			}
			if (Destination.find(".") != std::string::npos)
			{
				I.ClearWriteChannel();
				if (Destination.find("x") != std::string::npos)
					I.SetWriteChannel(ECHANNEL_X);
				if (Destination.find("y") != std::string::npos)
					I.SetWriteChannel(ECHANNEL_Y);
				if (Destination.find("z") != std::string::npos)
					I.SetWriteChannel(ECHANNEL_Z);

				Destination.erase(Destination.find("."));
				
			}
			I.SetDestinationAddress( atoi(Destination.c_str()+1) );
			
			
			
		}
}		

//----------------------------------------------------------
bool SourceNull( std::string aSource )
{
	if (aSource == "NULL")
		return true;
		
	return false;
}
//----------------------------------------------------------

void PopulateInstruction( std::string aDestination, std::string aSource1, std::string aSource0, Instruction & I, Theia::Parser::location_type  yylloc, bool aHasLiteral = false, unsigned int aLiteral = 0)
{


	bool DestinationHasOffset  = false;
	bool DetinationHasIndex    = false;
	bool Source0HasOffset      = false;
	bool Source1HasOffset      = false;
	bool Source1HasIndex       = false;
	bool Source0HasIndex       = false;
	
	
	if (aDestination.find("INDEX") != std::string::npos)
	{
		std::string ArrayIndex = aDestination.substr(aDestination.find("INDEX")+5);
		aSource1 = ArrayIndex;
		DetinationHasIndex	= true;
		
	}
		
	if (aSource1.find("INDEX") != std::string::npos)
		Source1HasIndex	= true;
		
	if (aSource0.find("INDEX") != std::string::npos)
		Source0HasIndex	= true;	
		
	if (aDestination.find("OFFSET") != std::string::npos)
		DestinationHasOffset = true;
		
	if 	(aSource0.find("OFFSET") != std::string::npos)
		Source0HasOffset = true;
		
	if 	(aSource1.find("OFFSET") != std::string::npos)
		Source1HasOffset = true;	
	
	if (IsSwizzled( aSource1 ))
		SetSwizzleAndSign( 1, aSource1,  I );
	I.SetSrc1Address( atoi( aSource1.c_str()+1 ) );
	
	if (IsSwizzled( aSource0 ))
		SetSwizzleAndSign( 0, aSource0,  I );
	I.SetSrc0Address( atoi( aSource0.c_str()+1 ) );
	
	
	
	//Fisrt take care of the destination write channel
	if (aDestination.find(".") != std::string::npos)
		{
			I.ClearWriteChannel();
			if (aDestination.find("x") != std::string::npos)
				I.SetWriteChannel(ECHANNEL_X);
			if (aDestination.find("y") != std::string::npos)
				I.SetWriteChannel(ECHANNEL_Y);
			if (aDestination.find("z") != std::string::npos)
				I.SetWriteChannel(ECHANNEL_Z);
			aDestination.erase(aDestination.find("."));
	} else {
		I.SetWriteChannel(ECHANNEL_XYZ);
	}
	//Now set the destination Index
	I.SetDestinationAddress( atoi(aDestination.c_str()+1) );
	
		
	//Now determine the addressing mode
	//Simple addressing modes
	if (!aHasLiteral &&	!DetinationHasIndex && !Source0HasIndex && !Source1HasIndex)
	{
		
		I.SetAddressingMode( DestinationHasOffset,Source1HasOffset,Source0HasOffset);
		return;
	}
	
	
	I.SetImmBit( true ); //This is to set the IMM bit = 1, may be overwritten latter
	//Complex addressing modes
	if 
	( 
	aHasLiteral &&
	!SourceNull( aSource0 ) &&
	!Source0HasOffset &&
	!Source1HasOffset &&
	!DestinationHasOffset 
	)
	{
		I.SetAddressingMode( false,false,false);
		I.SetImm( aLiteral );
		
	}
	else	
	if 
	( 
	aHasLiteral &&
	!SourceNull( aSource0 ) &&
	Source0HasOffset &&
	!Source0HasIndex &&
	DestinationHasOffset 
	
	)
	{
		
		I.SetAddressingMode( false,false,true);
		I.SetImm( aLiteral );
		
		
	}	
	else
	if 
	( 
	!aHasLiteral &&
	!SourceNull( aSource1 ) &&
	!Source1HasOffset &&
	!SourceNull( aSource0 ) &&
	Source0HasOffset &&
	Source0HasIndex &&
	DestinationHasOffset 
	
	)
	{
		I.SetAddressingMode( false,true,false);
		
	}
	else
	if 
	( 
	!aHasLiteral &&
	!Source1HasOffset &&
	!SourceNull( aSource0 ) &&
	Source0HasOffset &&
	!Source0HasIndex &&
	DestinationHasOffset &&
	DetinationHasIndex
	
	)
	{
		I.SetAddressingMode( false,true,true);
		
	}
	else
	if 
	( 
	aHasLiteral &&
	SourceNull( aSource0 ) &&
	!DestinationHasOffset &&
	!DetinationHasIndex
	
	)
	{
	
		
		I.SetAddressingMode( true,false,false);
		I.SetImm( aLiteral );
	}
	else
	if 
	( 
	aHasLiteral &&
	SourceNull( aSource0 ) &&
	DestinationHasOffset &&
	!DetinationHasIndex
	
	)
	{
		
		I.SetAddressingMode( true,false,true);
		I.SetImm( aLiteral );
	}
	else
	if 
	( 
	!aHasLiteral &&
	Source1HasOffset &&
	Source1HasIndex &&
	SourceNull( aSource0 ) &&
	DestinationHasOffset &&
	!DetinationHasIndex
	
	)
	{
		
		I.SetAddressingMode( true,true,false);
	}
	else
	if 
	( 
	!aHasLiteral &&
	Source1HasOffset &&
	Source1HasIndex &&
	Source0HasOffset &&
	!Source0HasIndex &&
	DestinationHasOffset &&
	!DetinationHasIndex
	
	)
	{
		
		I.SetAddressingMode( true,true,true);
	} else {
			std::ostringstream ret;
			ret << "Could not determine addressing mode  at line " << yylloc << " \n";
			throw ret.str();
	}
	
	
}

//-------------------------------------------------------------
void PopulateBoolean(EBRANCHTYPE aBranchType, std::string Source1, std::string Source0, Instruction & I, std::vector<Instruction> & aInstructions, Theia::Parser::location_type & yylloc )
{

					if (Source0.find("R") == std::string::npos)
					{
						I.mSourceLine = GetCurrentLineNumber( yylloc );
						I.SetCode( EOPERATION_ADD );
						unsigned int TempRegIndex  = GetFreeTempRegister();
						I.SetDestinationAddress( TempRegIndex );
						unsigned int ImmediateValue;
						std::string StringHex = Source0;
						std::stringstream ss;
						ss << std::hex << StringHex;
						ss >> ImmediateValue;
						I.SetImm( ImmediateValue );
						I.SetDestZero( true );
						I.SetSrc0Displace( true );
						I.SetWriteChannel(ECHANNEL_X);
						I.SetWriteChannel(ECHANNEL_Y);
						I.SetWriteChannel(ECHANNEL_Z);
						aInstructions.push_back(I);
						I.Clear();
						
						std::stringstream ss2;
						ss2 << "R" << TempRegIndex; 
						ss2 >> Source0;
						Source0 += " OFFSET ";
						
					}
					else
						I.mSourceLine = GetCurrentLineNumber( yylloc );
						
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.ClearWriteChannel();
					I.SetBranchType( aBranchType );
					
					PopulateSourceRegisters( Source1, Source0, I, aInstructions);
					aInstructions.push_back(I);
					I.Clear();
					////std::cout << "pushing code at position " << (mInstructions.size() - 1) << "\n";
					gBranchStack.push_back(aInstructions.size() - 1);
					ResetTempRegisterIndex();
}

//-------------------------------------------------------------
	// Prototype for the yylex function
	static int yylex(Theia::Parser::semantic_type * yylval,
	                 Theia::Parser::location_type * yylloc,
	                 Theia::Scanner &scanner);
}

%token AUTO RETURN FUNCTION JMP EXIT EQUAL NOT_EQUAL GREATER_THAN LESS_THAN LESS_OR_EQUAL_THAN GREATER_OR_EQUAL_THAN IF ELSE OPEN_ROUND_BRACE CLOSE_ROUND_BRACE OPEN_BRACE CLOSE_BRACE ASSIGN DIV MUL ADD DECCONST HEXCONST BINCONST EOS DOT MINUS TK_X TK_Y TK_Z TK_N REG
%token IDENTIFIER SQRT SCALE UNSCALE USING FIXED_POINT COMMA OPEN_SQUARE_BRACE CLOSE_SQUARE_BRACE WHILE ADD_EQ THREAD START BITWISE_AND BITWISE_OR OUT IN
%%

statement_list: //empty
	|
	statement_list statement
	|
	statement
	;

statement
	:
	AUTO auto_var_list EOS
	|
	USING FIXED_POINT EOS
	{
		mGenerateFixedPointArithmetic = true;
	}
	|
	EXIT EOS
	{
		//Insert a stupid NOP before the exit... is a bug but easier to just patch like this...
		
		I.Clear();
		I.mComment = "NOP";
		I.SetCode( EOPERATION_NOP );
		mInstructions.push_back(I);
		I.Clear();
		
		I.SetEofFlag(true);
		I.mComment = "Set the Exit bit";
		I.SetCode( EOPERATION_ADD );
		mInstructions.push_back(I);
		I.Clear();
	}
	|
	RETURN expression EOS
	{
	
		//////////////////////////////////////////////////////////////////////////////
		// This means this that the expression was just a constant.
		// No operations were inserted
		//////////////////////////////////////////////////////////////////////////////
		if (gInsertedInstructions == 0)
		{
			I.Clear();
			I.SetCode(EOPERATION_ADD);
			I.mComment ="Set the return value";
			if ($3.find("R") != std::string::npos)
			{
				PopulateInstruction( "R1", $2,"R0 . X X X",I,yylloc);
			}
			else
			{
				unsigned int ImmediateValue = 0;
				std::string StringHex = $3;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				PopulateInstruction( "R1", $3,"NULL",I, yylloc, true, ImmediateValue);
			}
			mInstructions.push_back(I);	
			I.Clear();
		} else {
		
			mInstructions[ mInstructions.size() - gInsertedInstructions].mSourceLine = GetCurrentLineNumber(yylloc);
			gInsertedInstructions = 0;	
			mInstructions.back().mComment ="Assigning return value";
			mInstructions.back().SetDestinationAddress( RETURN_VALUE_REGISTER );
			
		}
		ResetTempRegisterIndex();
		
		I.SetCode( EOPERATION_ADD );
		I.mComment = "Restore previous function frame offset";
		I.ClearWriteChannel();
		I.SetWriteChannel(ECHANNEL_X);
		I.SetDestinationAddress( SPR_CONTROL_REGISTER );
		I.SetSrc1Address(SPR_CONTROL_REGISTER);
		I.SetSrc1SwizzleX(SWX_Y);
		I.SetSrc1SwizzleY(SWY_Y);
		I.SetSrc1SwizzleZ(SWZ_Y);
		I.SetSrc0Address(0);
		I.SetSrc0SwizzleX(SWX_X);
		I.SetSrc0SwizzleY(SWY_X);
		I.SetSrc0SwizzleZ(SWZ_X);
		mInstructions.push_back( I );
		I.Clear();
		
		//Now return
		I.SetImm( 0 );
		I.SetCode( EOPERATION_ADD );
		I.mComment = "return from function";
		I.SetBranchFlag( true );
		I.SetBranchType( EBRANCH_ALWAYS );
		I.SetDestinationAddress( RETURN_ADDRESS_REGISTER );
		mInstructions.push_back(I);
		I.Clear();
		
	
		
	}
	|
	RETURN EOS
	{
		I.SetCode( EOPERATION_ADD );
		I.mComment = "Restore previous function frame offset";
		I.SetWriteChannel(ECHANNEL_X);
		I.SetDestinationAddress( SPR_CONTROL_REGISTER );
		I.SetSrc1Address(SPR_CONTROL_REGISTER);
		I.SetSrc1SwizzleX(SWX_Y);
		I.SetSrc1SwizzleY(SWY_Y);
		I.SetSrc1SwizzleZ(SWZ_Y);
		I.SetSrc0Address(0);
		I.SetSrc0SwizzleX(SWX_X);
		I.SetSrc0SwizzleY(SWY_X);
		I.SetSrc0SwizzleZ(SWZ_X);
		mInstructions.push_back( I );
		I.Clear();
	
		I.SetImm( 0 );
		I.SetCode( EOPERATION_ADD );
		I.mComment = "return from function";
		I.SetBranchFlag( true );
		I.SetBranchType( EBRANCH_ALWAYS );
		I.SetDestinationAddress( RETURN_ADDRESS_REGISTER );
		mInstructions.push_back(I);
		I.Clear();
	}
	
	 |
	 left_hand_side ADD_EQ constant EOS
	  {
		
		 I.mSourceLine = GetCurrentLineNumber( yylloc );
		 I.SetCode( EOPERATION_ADD );
		 SetDestinationFromRegister( $1, I , true);
		 unsigned int ImmediateValue;
		 std::string StringHex = $3;
		 std::stringstream ss;
		 ss << std::hex << StringHex;
		 ss >> ImmediateValue;
		 I.SetImm( ImmediateValue );
		 I.SetDestZero( false );
		 
		 mInstructions.push_back( I );
		 I.Clear();
	 }
	 |
	 left_hand_side MINUS MINUS EOS
	 {
		
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetCode( EOPERATION_ADD );
		SetDestinationFromRegister( $1, I, false );
		I.SetSrc0SignX( true );
		I.SetSrc0SignY( true );
		I.SetSrc0SignZ( true );
		std::string Destination = $1;
		if (Destination.find("OFFSET") != std::string::npos)
		{
			I.SetSrc1Displace( true );
			Destination.erase(Destination.find("OFFSET"));
		}
			
		if (Destination.find(".") != std::string::npos)
			Destination.erase(Destination.find("."));
		
		
		I.SetSrc1Address(atoi(Destination.c_str()+1));
		I.SetSrc0Address(0);
		I.SetSrc0SwizzleX(SWX_Y);
		I.SetSrc0SwizzleY(SWY_Y);
		I.SetSrc0SwizzleZ(SWZ_Y);
		mInstructions.push_back( I );
		I.Clear();
	 }
	 |
	 left_hand_side ADD ADD EOS
	 {
		
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetCode( EOPERATION_ADD );
		SetDestinationFromRegister( $1, I, false );
		std::string Destination = $1;
		if (Destination.find("OFFSET") != std::string::npos)
		{
			I.SetSrc1Displace( true );
			Destination.erase(Destination.find("OFFSET"));
		}
			
		if (Destination.find(".") != std::string::npos)
			Destination.erase(Destination.find("."));
		
		I.SetSrc1Address(atoi(Destination.c_str()+1));
		I.SetSrc0Address(0);
		I.SetSrc0SwizzleX(SWX_Y);
		I.SetSrc0SwizzleY(SWY_Y);
		I.SetSrc0SwizzleZ(SWZ_Y);
		mInstructions.push_back( I );
		I.Clear();
	 }
	 |
	 left_hand_side ASSIGN expression  EOS
	{
		
		//////////////////////////////////////////////////////////////////////////////
		// This means this that the expression will read from the T memory
		// variable index
		// For example:
		//          vector MyAddress,MyReadValue;
		//          MyReadValue = in [ MyAddress ];
		//
		//////////////////////////////////////////////////////////////////////////////
		
		DCOUT << $3 << " YYY \n";
		if ($3.find("IN") != std::string::npos )
		{
			
			std::string ReadAddress = $3;
			
			std::string SourceAddrRegister = ReadAddress.substr(ReadAddress.find("INDEX")+5);
			DCOUT << "!!!!!!!!!!!!!!!!!   " << ReadAddress << "\n";
			ReadAddress.erase(0,ReadAddress.find("IN")+3);
			DCOUT << "!!!!!!!!!!!!!!!!!   " << ReadAddress << "\n";
			
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
				
	
			PopulateSourceRegisters( ReadAddress, "R0", I, mInstructions );
			
			SetDestinationFromRegister( $1, I, false );
			I.mSourceLine = GetCurrentLineNumber(yylloc);
			I.SetCode( EOPERATION_IO );
			I.SetIOOperation( EIO_TMREAD );
			
			
			mInstructions.push_back( I );
			I.Clear();
			ResetTempRegisterIndex();
			goto LABEL_EXPRESSION_DONE;
		}
		//////////////////////////////////////////////////////////////////////////////
		// This means this that the expression will write into the output memory
		// constant index
		//////////////////////////////////////////////////////////////////////////////
	
		if ($1.find("OUT") != std::string::npos && $1.find("INDEX") == std::string::npos )
		{
			//PopulateInstruction( "R0", "R0 . X X X",$3,I,yylloc);
			
			I.SetCode(EOPERATION_IO); 
			I.SetIOOperation( EIO_OMWRITE );
			
			$1.erase($1.find("OUT"),3);
			
			unsigned int ImmediateValue;
			std::stringstream ss;
			ss << std::hex << $1;
			ss >> ImmediateValue;
			PopulateInstruction( $3, "R0 OFFSET", "R0 OFFSET", I, yylloc, true, ImmediateValue );
			#ifdef DEBUG
			I.PrintFields();
			#endif
			mInstructions.push_back(I);
			I.Clear();
			ResetTempRegisterIndex();
			goto LABEL_EXPRESSION_DONE;
		}
		//////////////////////////////////////////////////////////////////////////////
		// This means this that the expression will write into the output memory
		// variable index
		//////////////////////////////////////////////////////////////////////////////
	
		if ($1.find("OUT") != std::string::npos && $1.find("INDEX") != std::string::npos )
		{
			std::string Destination = $1;
			DCOUT << "!!!!!!!!!!!!!!!!!Destination " << Destination << "\n";
			std::string IndexRegister = Destination.substr(Destination.find("INDEX")+5);
			Destination.erase(Destination.find("INDEX"));
			
			
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
				
		//	PopulateSourceRegisters( IndexRegister + " OFFSET ", $3, I, mInstructions );
			PopulateSourceRegisters( IndexRegister, $3, I, mInstructions );
			
			
			//I.SetImm( 0 );
			I.SetCode( EOPERATION_IO );
			I.SetIOOperation( EIO_OMWRITE );
			
			std::string Source0 = $3;
			DCOUT << "!!!!!!!!!!!!!!!!!Source0 '" << Source0 << "'\n";
		
			mInstructions.push_back( I );
			I.Clear();
			ResetTempRegisterIndex();
			goto LABEL_EXPRESSION_DONE;
		}
		//////////////////////////////////////////////////////////////////////////////
		// This means this that the expression was just a constant.
		// No operations were inserted
		//////////////////////////////////////////////////////////////////////////////
		if (gInsertedInstructions == 0)
		{
			
			I.Clear();
			
			I.SetCode(EOPERATION_ADD);
			I.mSourceLine = GetCurrentLineNumber(yylloc);
			if ($3.find("R") != std::string::npos)
			{
			// case 1:
			// foo = 0;        //$$ = R0 . X X X
			/*	SetDestinationFromRegister( $1, I, false );
				PopulateSourceRegisters( $3, "R0 . X X X", I, mInstructions);*/
				
				PopulateInstruction( $1, "R0 . X X X",$3,I,yylloc);
			
			} else {
			// case 2:
			// foo = 0xcafe;  //$$ = 0xcafe
				SetDestinationFromRegister( $1, I, true );
				unsigned int ImmediateValue = 0;
				std::string StringHex = $3;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
							
				PopulateInstruction( $1, $3,"NULL",I, yylloc, true, ImmediateValue);
			}
			std::string strConstant = $3;
			
			mInstructions.push_back(I);
			I.Clear();
			ResetTempRegisterIndex();
			goto LABEL_EXPRESSION_DONE;
		}
		
		//////////////////////////////////////////////////////////////////////////////
		// This means that the last instruction which was inserted was a tripple 
		// constant assignement, like foo = (1,2,3)
		//////////////////////////////////////////////////////////////////////////////
		if (mInstructions.back().mBisonFlagTrippleConstAssign)
		{
			unsigned int LastIndex = mInstructions.size() - 1;
			mInstructions[LastIndex].SetDestinationAddress(atoi($1.c_str()+1));
			mInstructions[LastIndex-1].SetDestinationAddress(atoi($1.c_str()+1));
			mInstructions[LastIndex-2].SetDestinationAddress(atoi($1.c_str()+1));
			mInstructions[LastIndex-2].mSourceLine = GetCurrentLineNumber( yylloc );
			if($1.find("OFFSET") == std::string::npos)
			{
				mInstructions[LastIndex].SetAddressingMode(true,false,false);
				mInstructions[LastIndex-1].SetAddressingMode(true,false,false);
				mInstructions[LastIndex-2].SetAddressingMode(true,false,false);
			}
			
			ResetTempRegisterIndex();
			goto LABEL_EXPRESSION_DONE;
		}
		//////////////////////////////////////////////////////////////////////////////
		// Handle the case where the destination is an array of vector
		// ej: R = v1[ i ]  + V2
		//////////////////////////////////////////////////////////////////////////////
		if (I.GetOperation() == 0 && $3.find("array_element") != std::string::npos)
		{
			//No operation meaning the the expression only has a single variable
			//See if the expression returned is an array_element 
			if ($3.find("array_element") != std::string::npos)
			{
				////std::cout << "expression is an array element\n\n";
				std::string Index = $3.substr($3.find("array_element"));
				Index = Index.substr(Index.find_first_not_of("array_element R"));
				SetIndexRegister( atoi(Index.c_str()), mInstructions );
				$3.erase($3.find("array_element"));
				SetExpressionDestination( $1, I );
				I.SetCode(EOPERATION_ADD);
				I.SetImmBit( true );
				I.SetDestZero( true );
				I.SetSrc1Displace( true ); 
				I.SetSrc0Displace( false ); 
				I.mSourceLine = GetCurrentLineNumber(yylloc);
				
				if ($3.find("OFFSET") != std::string::npos)
					$3.erase($3.find("OFFSET"));
					
				I.SetSrc1Address(atoi($3.c_str()+1));
				I.SetSrc0Address(0);
				mInstructions.push_back(I);
				I.Clear();
			}
		} 
		else 
		{
		
				mInstructions[ mInstructions.size() - gInsertedInstructions].mSourceLine = GetCurrentLineNumber(yylloc);
				gInsertedInstructions = 0;		
				std::string Destination = $1;
				//std::cout << "DST " << Destination << " \n";
				//Look for indirect addressing
				if (Destination.find("INDEX") != std::string::npos)
				{
					
					std::string IndexRegister = Destination.substr(Destination.find("INDEX")+5);
					
					Destination.erase(Destination.find("INDEX"));
					
					I.SetImm( 0 );
					I.SetCode( EOPERATION_ADD );
					
					if (Destination.find(".") != std::string::npos)
					{
						I.ClearWriteChannel();
						if (Destination.find("x") != std::string::npos)
							I.SetWriteChannel(ECHANNEL_X);
						if (Destination.find("y") != std::string::npos)
							I.SetWriteChannel(ECHANNEL_Y);
						if (Destination.find("z") != std::string::npos)
							I.SetWriteChannel(ECHANNEL_Z);

						Destination.erase(Destination.find("."));
						
					}
				
					std::string Source0 = $3;
					if (Source0.find("OFFSET") != std::string::npos)
					{
						Source0.erase(Source0.find("OFFSET"));
						I.SetSrc0Displace(1);
					}
					I.SetSrc1Address(atoi(IndexRegister.c_str()+1));
					I.SetSrc0Address(atoi(Source0.c_str()+1));
					
					
				//	I.SetSrc0Address(mInstructions.back().GetDestinationAddress());
					I.SetDestZero(0);
					I.SetSrc1Displace(1);
					I.SetSrc0Displace(1);
					I.SetDestinationAddress( atoi(Destination.c_str()+1) );
					mInstructions.push_back( I );
					I.Clear();
				} else {
					
					if (mInstructions.back().GetImm())
					{
						//Look for displament addressing mode
						unsigned int AddressingMode = mInstructions.back().GetAddressingMode();
						if (Destination.find("OFFSET") != std::string::npos)
						{
							//This means AddressMode is '101', so leave the way it is
							mInstructions.back().ClearWriteChannel();
							mInstructions.back().SetWriteChannel(ECHANNEL_Z);
							Destination.erase(Destination.find("OFFSET"));
						} else {
							//This is not supposed to have index, so change addressing mode to '100'
							
							mInstructions.back().SetDestZero( true );
							mInstructions.back().SetSrc1Displace( false );
							mInstructions.back().SetSrc0Displace( false );
							mInstructions.back().ClearWriteChannel();
							mInstructions.back().SetWriteChannel(ECHANNEL_Z);
						}
						
					} else {
						mInstructions.back().SetDestZero( false ); //First assume no offset was used
						
						
						
						//Look for displament addressing mode
						if (Destination.find("OFFSET") != std::string::npos)
						{
							Destination.erase(Destination.find("OFFSET"));
							mInstructions.back().SetDestZero( true ); //When Imm != 0, DestZero means DST = DSTINDEX + offset
						}
					}	
						if (Destination.find(".") != std::string::npos)
						{
							mInstructions.back().ClearWriteChannel();
							if (Destination.find("x") != std::string::npos)
								mInstructions.back().SetWriteChannel(ECHANNEL_X);
							if (Destination.find("y") != std::string::npos)
								mInstructions.back().SetWriteChannel(ECHANNEL_Y);
							if (Destination.find("z") != std::string::npos)
								mInstructions.back().SetWriteChannel(ECHANNEL_Z);

							Destination.erase(Destination.find("."));
							
						}
						mInstructions.back().SetDestinationAddress( atoi($1.c_str()+1) );
						for (int i = 1; i <= gExtraDestModifications; i++ )
						{
							int idx = (mInstructions.size()-1)-i;
							mInstructions[idx].SetDestinationAddress( atoi($1.c_str()+1) );
							if (mInstructions[idx].GetImm())
							{
									
								//This is not supposed to have index, so change addressing mode to '100'
								mInstructions[idx].SetDestZero( true );
								mInstructions[idx].SetSrc1Displace( false );
								mInstructions[idx].SetSrc0Displace( false );
										
										
							}
							
						}
						gExtraDestModifications = 0;
					
					
					
				}
				ResetTempRegisterIndex();
		}
		
		LABEL_EXPRESSION_DONE:
		gInsertedInstructions = 0;
		while(0);
		
	}
	|
	WHILE { /*Middle rule here, get me the loop address*/ ;gWhileLoopAddress = (mInstructions.size());}OPEN_ROUND_BRACE boolean_expression CLOSE_ROUND_BRACE OPEN_BRACE statement_list CLOSE_BRACE
	{
		mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size()+1);
		gBranchStack.pop_back();
		//Now I need to put a GOTO so that the while gets evaluated again...
		//jump out of the if
	   I.Clear();
	   I.SetCode( EOPERATION_ADD );
	   I.mComment = "while loop goto re-eval boolean";
	   I.SetDestinationAddress( gWhileLoopAddress );
	   I.SetBranchFlag( true );
	   I.SetBranchType( EBRANCH_ALWAYS );
	   mInstructions.push_back(I);
	   I.Clear();
	
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////																										  /////
	/////	If-else											        											  /////
	/////																										  /////
	/////	if (<boolean-expression>)                       													  /////
	/////	{																									  /////
	/////	 <statement-list>																					  /////
	/////																										  /////
	/////	} else {																							  /////
	/////      <statement-list>																					  /////
	/////   }																									  /////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	| IF 
	  OPEN_ROUND_BRACE boolean_expression CLOSE_ROUND_BRACE 
	  OPEN_BRACE statement_list CLOSE_BRACE
      ELSE 
	{ //Start of middle rule
	 
	   //jump out of the if
	   I.Clear();
	   I.SetCode( EOPERATION_ADD );
	   I.SetBranchFlag( true );
	   I.SetBranchType( EBRANCH_ALWAYS );
	   mInstructions.push_back(I);
	   I.Clear();
	   //Take care of the destination addr of the if statement.
	   mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size());
	  gBranchStack.pop_back();
	  //push the inconditional jump into the stack
	  gBranchStack.push_back(mInstructions.size() - 1);
	  
	  
	} //End of middle rule
	  OPEN_BRACE  statement_list CLOSE_BRACE
	{
	   
	   mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size());
	   gBranchStack.pop_back();
	   
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////																										  /////
	/////	If statement									        											  /////
	/////																										  /////
	/////	if (<boolean-expression>)                       													  /////
	/////	{																									  /////
	/////	 <statement-list>																					  /////
	/////																										  /////
	/////	}																									  /////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|
	IF OPEN_ROUND_BRACE boolean_expression CLOSE_ROUND_BRACE OPEN_BRACE statement_list CLOSE_BRACE  
	{
		mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size());
		//mInstructions[gBranchStack.back()].mSourceLine = GetCurrentLineNumber(yylloc);
		
		gBranchStack.pop_back();
		////std::cout << "if closing at " << mInstructions.size() << "\n";
		
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////																										  /////
	/////	Function declaration																				  /////
	/////																										  /////
	/////	function <function-name> ( [ <arg1>, ... ,<arg6> ])													  /////
	/////	{																									  /////
	/////	 <statement-list>																					  /////
	/////																										  /////
	/////	}																									  /////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|
	FUNCTION IDENTIFIER OPEN_ROUND_BRACE function_argument_list CLOSE_ROUND_BRACE
	{
	  DCOUT << "Function declaration for " << $2 << " at " << mInstructions.size() << "\n" ;
	  mSymbolMap[ $2 ] = mInstructions.size();
	} OPEN_BRACE statement_list CLOSE_BRACE
	{
		//Clear the auto var index now that we leave the function scope
		ClearAutoVarMap();
		ClearFunctionParameterMap();
		
		//Now uddate the current SPR_CONTROL_REGISTER.x = SPR_CONTROL_REGISTER.y
		I.SetCode( EOPERATION_ADD );
		I.mComment = "Restore previous function frame offset";
		I.SetWriteChannel(ECHANNEL_X);
		I.SetDestinationAddress( SPR_CONTROL_REGISTER );
		I.SetSrc1Address(SPR_CONTROL_REGISTER);
		I.SetSrc1SwizzleX(SWX_Y);
		I.SetSrc1SwizzleY(SWY_Y);
		I.SetSrc1SwizzleZ(SWZ_Y);
		I.SetSrc0Address(0);
		I.SetSrc0SwizzleX(SWX_X);
		I.SetSrc0SwizzleY(SWY_X);
		I.SetSrc0SwizzleZ(SWZ_X);
		
		mInstructions.push_back( I );
		I.Clear();
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////																										  /////
	/////	Thread declaration																					  /////
	/////																										  /////
	/////	thread <thread-name> ( )																			  /////
	/////	{																									  /////
	/////	 <statement-list>																					  /////
	/////																										  /////
	/////	}																									  /////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|
	//Thread declaration
	THREAD IDENTIFIER OPEN_ROUND_BRACE CLOSE_ROUND_BRACE
	{
		gThreadMap[ $2 ] = mInstructions.size();
		gThreadScope = true;
	}
	OPEN_BRACE statement_list CLOSE_BRACE
	{
		////std::cout << "Defining thread" << "\n";
		gThreadScope = false;
		ClearAutoVarMap();
		//Since the thread is done, then disable threading
		I.SetCode( EOPERATION_ADD );
		I.mComment = "Disable multi-threading";
		I.SetDestinationAddress( SPR_CONTROL_REGISTER0 );
		unsigned int Value = 0;
		I.SetImm( Value );
		I.SetDestZero( true );
		I.SetWriteChannel(ECHANNEL_Z);
		mInstructions.push_back( I );
		I.Clear();
	
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////																										  /////
	/////	Start thread																						  /////
	/////																										  /////
	/////	start <thread-name> ( );												  							  /////
	/////																										  /////
	/////																										  /////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|
	START IDENTIFIER OPEN_ROUND_BRACE CLOSE_ROUND_BRACE EOS
	{
		unsigned int ThreadCodeOffset = 0;
		////std::cout << "Starting thread" << "\n";
		if (gThreadMap.find($2) == gThreadMap.end())
		{
			
			std::ostringstream ret;
			ret << "Undefined thread '" << $2 << "' at line " << yylloc << " \n";
			ret << "Current version of the compiler needs thread defintion prior of thread instantiation\n";
			throw ret.str();
		} else {
			ThreadCodeOffset = gThreadMap[$2];
			//Now enable the multithreading and set instruction offset
			I.SetCode( EOPERATION_ADD );
			std::ostringstream ss;
			ss << "Set thread instruction offset to 8'd" << ThreadCodeOffset;
			I.mComment = ss.str();
			I.SetDestinationAddress( SPR_CONTROL_REGISTER0 );
			unsigned int Value = (ThreadCodeOffset << 1);
			I.SetImm( Value );
			I.SetDestZero( true );
			I.SetWriteChannel(ECHANNEL_Z);
			mInstructions.push_back( I );
			I.Clear();
			
			 
			I.SetCode( EOPERATION_ADD );
			I.mComment = "Enable multi-threading";
			I.SetDestinationAddress( SPR_CONTROL_REGISTER0 );
			Value = (ThreadCodeOffset << 1 | 1);
			I.SetImm( Value );
			I.SetDestZero( true );
			I.SetWriteChannel(ECHANNEL_Z);
			mInstructions.push_back( I );
			I.Clear();
			
		}
		
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////																										  /////
	/////	Function call and assign return value to variable													  /////
	/////																										  /////
	/////	<variable> = <function-name> ( [ <arg1>, ... ,<arg6> ]);											  /////
	/////																										  /////
	/////																										  /////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|
	left_hand_side ASSIGN IDENTIFIER OPEN_ROUND_BRACE function_input_list CLOSE_ROUND_BRACE EOS
	{
		////std::cout << "Function call returning to var\n";
		StoreReturnAddress( mInstructions, yylloc );
		SavePreviousFramePointer( mInstructions );
		UpdateFramePointer( mInstructions );
		CallFunction( $3, mInstructions, mSymbolMap );
		
		
		//Return value comes in R1, so let's store this in our variable
		I.SetCode( EOPERATION_ADD );
		SetDestinationFromRegister( $1, I, false );
		I.mComment = "grab the return value from the function";
		I.SetSrc1Address( RETURN_VALUE_REGISTER);
		I.SetSrc0Address(0);
		I.SetSrc0SwizzleX(SWX_X);
		I.SetSrc0SwizzleY(SWY_X);
		I.SetSrc0SwizzleZ(SWZ_X);
		mInstructions.push_back( I );
		I.Clear();
		ClearNextFunctionParamRegister();
	}
	|
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////																										  /////
	/////	Function call (return value is ignored)																  /////
	/////																										  /////
	/////	<function-name> ( [ <arg1>, ... ,<arg6> ]);															  /////
	/////																										  /////
	/////																										  /////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	IDENTIFIER  OPEN_ROUND_BRACE function_input_list CLOSE_ROUND_BRACE EOS
	{
	
		//Store the return address	
		StoreReturnAddress( mInstructions, yylloc );
	
	
		//Store the current SPR_CONTROL_REGISTER.x into the previous SPR_CONTROL_REGISTER.y
		//SPR_CONTROL_REGISTER.y = SPR_CONTROL_REGISTER.xxx + 0;
		I.SetCode( EOPERATION_ADD );
		I.mComment = "store current frame offset";
		I.SetWriteChannel(ECHANNEL_Y);
		I.SetDestinationAddress( SPR_CONTROL_REGISTER );
		I.SetSrc1Address(SPR_CONTROL_REGISTER);
		I.SetSrc1SwizzleX(SWX_X);
		I.SetSrc1SwizzleY(SWY_X);
		I.SetSrc1SwizzleZ(SWZ_X);
		I.SetSrc0Address(0);
		I.SetSrc0SwizzleX(SWX_X);
		I.SetSrc0SwizzleY(SWY_X);
		I.SetSrc0SwizzleZ(SWZ_X);
		mInstructions.push_back( I );
		I.Clear();
		//Now uddate the current SPR_CONTROL_REGISTER.x += number of auto variables
		I.SetCode( EOPERATION_ADD );
		I.mComment = "displace next frame offset by the number of auto variables in current frame";
		I.SetWriteChannel(ECHANNEL_X);
		I.SetDestinationAddress( SPR_CONTROL_REGISTER );
		I.SetImm( GetCurretAutoVarFrameSize() );
		I.SetDestZero( false );
		mInstructions.push_back( I );
		I.Clear();
		//Call the function with a JMP
		I.SetCode( EOPERATION_ADD );
		I.mComment = "call the function";
		I.SetBranchFlag( true );
		I.SetBranchType( EBRANCH_ALWAYS );
		
		//Now assign the destination of the branch (our function virtual address)
		if (mSymbolMap.find($1) == mSymbolMap.end())
		{
			//The destination is not yet declared
			//so leave it as a symbol so that it can latter
			//resolved by the linker
			I.SetDestinationSymbol( "@"+$1 );
		} else {
			//The destination symbol has already been declared
			//so assign it right away
			I.SetDestinationAddress( mSymbolMap[ $1 ] );
		}
		
		//Push the last instruction in the sequence and clean up	
		mInstructions.push_back( I );
		I.Clear();
		
	}
	;
	
	
	
	function_input_list
					  :
					  |//empty
					  expression COMMA function_input_list
					  {
						AddFunctionInputList( $1, mInstructions,yylloc );
					  }
					  |
					  expression
					  {
						AddFunctionInputList( $1,mInstructions, yylloc );
					  }
					  ;

	function_argument_list
						:
						| //empty
						IDENTIFIER COMMA function_argument_list
						{
							AddFunctionParameter( $1, yylloc );
						}
						|
						IDENTIFIER
						{
							AddFunctionParameter( $1, yylloc );
						}
						;
	

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////																										  /////
/////	Expression declaration.																                  /////
/////																										  /////
/////	This is the definition for the expressions which make the Right Hand values							  /////
/////	The expressions follow the general shape of Expression made of "Terms" which in turn are made our of  /////																								  /////
/////	"factors". This so the order operations is taken into cosiderations and subexpressions can be grouped /////
/////   using parenthesis. The expressions follow th BNF format as described next                             /////
/////																									      /////
///// <Exp> ::= <Exp> + <Term> |                                                                              /////
/////          <Exp> - <Term>  |                                                                              /////
/////          <Term>                                                                                         /////
/////                                                                                                         /////
///// <Term> ::= <Term> * <Factor> |                                                                          /////
/////            <Term> / <Factor> |                                                                          /////
/////            <Factor>                                                                                     /////
/////                                                                                                         /////
///// <Factor> ::= <source>   |                                                                               /////
/////              ( <Exp> )  |                                                                               /////
/////              - <Factor> |                                                                               /////
/////              <Number>                                                                                   /////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////	 
expression
		:
		expression ADD term
		{
			unsigned int TempRegIndex  = GetFreeTempRegister();
			gExtraDestModifications = 0;
			
			I.SetCode( EOPERATION_ADD );
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
				
			PopulateSourceRegisters( $1, $3, I, mInstructions );
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			$$ = ss.str();
			
		}
		|
		expression MINUS term
		{
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetCode( EOPERATION_ADD );
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetSrc0SignX( true );
			I.SetSrc0SignY( true );
			I.SetSrc0SignZ( true );
				
			PopulateSourceRegisters( $1, $3, I, mInstructions);
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			$$ = ss.str();
		}
		|
		expression BITWISE_OR term
		{
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_LOGIC );
			I.SetLogicOperation( ELOGIC_OR );
			PopulateSourceRegisters( $1, $3, I, mInstructions);
			
						
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			$$ = ss.str();
		}
		//////////////////////////////////////////////////////////////////////////////
		//  This is the "in" operator used as the RHV
		//  Example:
		//   MyValue = in[ MyAddress ]
		//
		//  Note that this RHV cannot be combined with other RHV expressions, in other
		//  words you can not do thing like this: RHV = in[ addr ] + SomeOtherVariable
		//
		//////////////////////////////////////////////////////////////////////////////
		|
		IN OPEN_SQUARE_BRACE IDENTIFIER CLOSE_SQUARE_BRACE
		{
			std::string Register;
			if ((Register = GetRegisterFromFunctionParameter($3)) != "NULL")
				$$ = "IN " + Register;
			else	
				$$ = "IN " + GetRegisterFromAutoVar( $3, yylloc ) + " OFFSET ";
		}
		|
		term
		{
			$$ = $1;
		}
		;
		
		term
		:
		term MUL factor
		{
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_MUL );
			
			PopulateSourceRegisters( $1, $3, I, mInstructions);
			
			//If we are using fixed point aritmethic then we need to apply the scale
			//R = A * ( B >> SCALE)
			if (mGenerateFixedPointArithmetic)
				I.SetSrc0Rotation( EROT_RESULT_RIGHT );
			
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			$$ = ss.str();
		}
		|
		term DIV factor
		{
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_DIV );
			
			PopulateSourceRegisters( $1, $3, I, mInstructions);
			
			//If we are using fixed point aritmethic then we need to apply the scale
			// R = (A << N) / B
			if (mGenerateFixedPointArithmetic)
				I.SetSrc1Rotation( EROT_SRC1_LEFT );
			
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			$$ = ss.str();
		}
		|
		term BITWISE_AND factor
		{
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_LOGIC );
			I.SetLogicOperation( ELOGIC_AND );
			PopulateSourceRegisters( $1, $3, I, mInstructions);
			
						
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			$$ = ss.str();
		}
		|
		factor
		{
			$$ = $1;
		}
		;
		
		factor
		:
		source
		{
			$$ = $1;
		}
		//////////////////////////////////////////////////////////////////////////////
		// this is the square root used as part of RHS
		// Example:
		//   RHS = sqrt( <expression> )
		//////////////////////////////////////////////////////////////////////////////
		|
		SQRT OPEN_ROUND_BRACE expression CLOSE_ROUND_BRACE
		{
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_SQRT );
			I.SetSrc0Address( 0 );       
			PopulateSourceRegisters( $3 ,"R0 . X X X", I, mInstructions);
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			$$ = ss.str();
		}
		|
		OPEN_ROUND_BRACE expression CLOSE_ROUND_BRACE
		{
			$$ = $2;
		}
		;
		
	
	
	source
	:
	constant
	{
	
		unsigned int ImmediateValue;
		std::string StringHex = $1;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		
		switch (ImmediateValue)
		{
		case 0:
			$$ = "R0 . X X X";
		break;
		case 1:
			$$ = "R0 . Y Y Y";
		break;
		case 2:
			$$ = "R0 . Z Z Z";
		break;
		default:
			std::string StringHex = $1;
			std::stringstream ss;
			ss << std::hex << StringHex;
			ss >> ImmediateValue;
			$$ = ss.str();
			break;
		}
	}
	|
	OPEN_ROUND_BRACE constant COMMA constant COMMA constant CLOSE_ROUND_BRACE
	{
		unsigned int TempRegIndex  = GetFreeTempRegister();
		unsigned int ImmediateValue;
		
		{
		
		std::string StringHex = $2;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		
		
		I.SetDestinationAddress( TempRegIndex );
		I.SetImm( ImmediateValue );
		I.SetDestZero(true);
		I.SetSrc0Displace(true);
		I.SetWriteChannel(ECHANNEL_X);
		I.SetCode( EOPERATION_ADD );
		mInstructions.push_back(I);
		gInsertedInstructions++;
		I.Clear();
		}
		
		{
		std::string StringHex = $4;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		
		I.SetDestinationAddress( TempRegIndex );
		I.SetImm( ImmediateValue );
		I.SetDestZero(true);
		I.SetSrc0Displace(true);
		I.SetWriteChannel(ECHANNEL_Y);
		I.SetCode( EOPERATION_ADD );
		mInstructions.push_back(I);
		gInsertedInstructions++;
		I.Clear();
		}
		
		{
		std::string StringHex = $6;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		
		I.SetDestinationAddress( TempRegIndex );
		I.SetImm( ImmediateValue );
		I.SetDestZero(true);
		I.SetSrc0Displace(true);
		I.SetWriteChannel(ECHANNEL_Z);
		I.SetCode( EOPERATION_ADD );
		I.mBisonFlagTrippleConstAssign = true;
		mInstructions.push_back(I);
		gInsertedInstructions++;
		I.Clear();
		}
		
		gExtraDestModifications = 2;
		std::stringstream ss2;
		ss2 << "R" << TempRegIndex << " OFFSET ";
		$$ = ss2.str();
	}
	|
	IDENTIFIER array_index
	{
		
		
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($1)) != "NULL")
			$$ = Register;
		 else
			$$ = GetRegisterFromAutoVar( $1, yylloc) + " OFFSET ";
			
		if ($2 != "NULL")
		{
					
			$$ += " array_element " + $2;
			
		}
	}
	|
	IDENTIFIER DOT coordinate coordinate coordinate
	{
	
		std::string X = $3,Y = $4,Z = $5;
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($1)) != "NULL")
			$$ = (Register + " . " + " " + X + " " + Y  + " " + Z/* + " OFFSET "*/);
		else
			$$ = (GetRegisterFromAutoVar( $1, yylloc) + " . " + " " + X + " " + Y  + " " + Z + " OFFSET ");
	}
	|
	REG
	{
		
		std::string R = $1;
		R.erase(0,1);
		$$ = "R" + R;
		
	}
	|
	SCALE OPEN_ROUND_BRACE REG CLOSE_ROUND_BRACE
	{
	
		std::string R = $1;
		R.erase(0,1);
		$$ = "<<R" + R;
	}
	|
	UNSCALE OPEN_ROUND_BRACE REG CLOSE_ROUND_BRACE
	{
	
		std::string R = $1;
		R.erase(0,1);
		$$ = ">>R" + R;
	}
	|
	REG DOT coordinate coordinate coordinate
	{
		std::string R = $1;
		std::string X = $3,Y = $4,Z = $5;
		R.erase(0,1);
		$$ = "R" + R + " . " + " " + X + " " + Y  + " " + Z;
	
	}
	;
	
	
	coordinate
	:
	TK_X 
	{
		$$ = "X";
	}
	|
	MINUS TK_X
	{
		$$ = "-X";
	}
	|
	TK_Y
	{
		$$ = "Y";
	}
	|
	MINUS TK_Y
	{
		$$ = "-Y";
	}
	|
	TK_Z
	{
		$$ = "Z";
	}
	|
	MINUS TK_Z
	{
		$$ = "-Z";
	}
	;	
	
	
array_index
	:
	{
		$$ = "NULL";
	}
	|
	OPEN_SQUARE_BRACE IDENTIFIER CLOSE_SQUARE_BRACE
	{
		/*std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($2)) != "NULL")
			$$ = Register;
		else*/
		//Indexes into arrays can only be auto variables!
		$$ = GetRegisterFromAutoVar( $2, yylloc );
	}
	;
	
left_hand_side
	:
	OUT OPEN_SQUARE_BRACE constant CLOSE_SQUARE_BRACE
	{
		
		$$ = "OUT " + $3;
	}
	|
	OUT OPEN_SQUARE_BRACE IDENTIFIER CLOSE_SQUARE_BRACE
	{
	
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($3)) != "NULL")
			$$ = "OUT INDEX" + Register;
		else	
			$$ = "OUT INDEX" + GetRegisterFromAutoVar( $3, yylloc ) + " OFFSET ";
		
		
		
	}
	|
	IDENTIFIER array_index
	{
		
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($1)) != "NULL")
			$$ = Register + ".xyz";
		else
			$$ = GetRegisterFromAutoVar( $1, yylloc ) + ".xyz" + " OFFSET " + (($2 != "NULL")?" INDEX"+$2:"");
		
	} 
	|
	IDENTIFIER DOT TK_X
	{
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($1)) != "NULL")
			$$ = Register + ".x";
		else
		$$ = GetRegisterFromAutoVar( $1, yylloc ) + ".x" + " OFFSET ";
	}
	|
	IDENTIFIER DOT TK_Y
	{
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($1)) != "NULL")
			$$ = Register + ".y";
		else
			$$ = GetRegisterFromAutoVar( $1, yylloc ) + ".y" + " OFFSET ";
	}
	|
	IDENTIFIER DOT TK_Z
	{
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($1)) != "NULL")
			$$ = Register + ".z";
		else
			$$ = GetRegisterFromAutoVar( $1, yylloc ) + ".z" + " OFFSET ";
	}
	|
	REG 
	{
		std::string R = $1;
		R.erase(0,1);
		$$ = "R" + R + ".xyz";
	}
	|
	REG DOT TK_X
	{
		std::string R = $1;
		R.erase(0,1);
		$$ = "R" + R + ".x";
	}
	|
	REG DOT TK_Y
	{
		std::string R = $1;
		R.erase(0,1);
		$$ = "R" + R + ".y";
	}
	|
	REG DOT TK_Z
	{
		
		std::string R = $1;
		R.erase(0,1);
		$$ = "R" + R + ".z";
	}
	|
	REG DOT TK_X TK_Y TK_N
	{
		std::string R = $1;
		R.erase(0,1);
		$$ = "R" + R + ".xy";
	}
	|
	REG DOT TK_X TK_N TK_Z
	{
		std::string R = $1;
		R.erase(0,1);
		$$ = "R" + R + ".xz";
	}
	|
	REG DOT TK_N TK_Y TK_Z
	{
		std::string R = $1;
		R.erase(0,1);
		$$ = "R" + R + ".yz";
	}
	;

	
boolean_expression
				:
				expression NOT_EQUAL expression
				{
					PopulateBoolean(EBRANCH_IF_ZERO, $1, $3, I, mInstructions, yylloc );
					
				}
				|
				expression EQUAL expression 
				{
					PopulateBoolean(EBRANCH_IF_NOT_ZERO, $1, $3, I, mInstructions, yylloc );
					
				}
				|
				expression GREATER_THAN expression
				{
					PopulateBoolean(EBRANCH_IF_ZERO_OR_SIGN, $1, $3, I, mInstructions, yylloc );
					
				}
					
				|
				expression LESS_THAN expression
				{
					PopulateBoolean(EBRANCH_IF_ZERO_OR_NOT_SIGN, $1, $3, I, mInstructions, yylloc );
				
				}
				|
				expression LESS_OR_EQUAL_THAN expression
				{
					PopulateBoolean(EBRANCH_IF_NOT_SIGN, $1, $3, I, mInstructions, yylloc );
					
				}				
				|
				expression GREATER_OR_EQUAL_THAN expression
				{
					PopulateBoolean(EBRANCH_IF_SIGN, $1, $3, I, mInstructions, yylloc );
					
				}
				;	
	
constant
	:
		DECCONST
		{
			// Transform to HEX string
			unsigned int Val;
			std::string StringDec = $1;
			std::stringstream ss;
			ss << StringDec;
			ss >> Val;
			std::stringstream ss2;
			ss2 << std::hex << Val;
			$$ = ss2.str();
		}
		|
		HEXCONST
		{
			std::string StringHex = $1;
			// Get rid of the 0x
			StringHex.erase(StringHex.begin(),StringHex.begin()+2);
			std::stringstream ss;
			ss << std::hex << StringHex;
			
			$$ = ss.str();
		}
		|
		BINCONST
		{
			// Transform to HEX string
			std::string StringBin = $1;
			// Get rid of the 0b
			StringBin.erase(StringBin.begin(),StringBin.begin()+2);
			std::bitset<32> Bitset( StringBin );
			std::stringstream ss2;
			ss2 << std::hex <<  Bitset.to_ulong();
			$$ = ss2.str();
		}
	;
auto_var_list
			:
			IDENTIFIER array_size COMMA auto_var_list
			{
				if (gAutoVarMap.find($1) != gAutoVarMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << $1 << "'\n";
					throw ret.str();
				}
				
				std::stringstream ss;
				ss << $2;
				unsigned int Size;
				ss >> Size;
				gAutoVarMap[ $1 ] = AllocAutoVar(Size);
			}
			|
			IDENTIFIER ASSIGN OPEN_ROUND_BRACE constant COMMA constant COMMA constant CLOSE_ROUND_BRACE COMMA auto_var_list
			{
				if (gAutoVarMap.find($1) != gAutoVarMap.end())
				{
				std::ostringstream ret;
				ret << "Duplicated symbol " << $1 << "'\n";
				throw ret.str();
				}
				gAutoVarMap[ $1 ] = AllocAutoVar();
				
				unsigned int Destination = gAutoVarMap[ $1 ];
		
					
		
				I.ClearWriteChannel();
				unsigned int ImmediateValue;
				{
				I.SetDestinationAddress( Destination );
				I.SetWriteChannel(ECHANNEL_X);
				std::string StringHex = $4;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				I.SetImm( ImmediateValue );
				I.SetDestZero( true );
				I.SetSrc1Displace( false );
				I.SetSrc0Displace( true );
				I.SetCode( EOPERATION_ADD );
				I.mSourceLine = GetCurrentLineNumber( yylloc );
				mInstructions.push_back(I);
				I.Clear();
				}
				{
				I.SetDestinationAddress( Destination );
				I.SetWriteChannel(ECHANNEL_Y);
				std::string StringHex = $6;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				I.SetImm( ImmediateValue );
				I.SetDestZero( true );
				I.SetSrc1Displace( false );
				I.SetSrc0Displace( true );
				I.SetCode( EOPERATION_ADD );
				mInstructions.push_back(I);
				I.Clear();
				}
				{
				I.SetDestinationAddress( Destination );
				I.SetWriteChannel(ECHANNEL_Z);
				std::string StringHex = $8;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				I.SetImm( ImmediateValue );
				I.SetDestZero( true );
				I.SetSrc1Displace( false );
				I.SetSrc0Displace( true );
				I.SetCode( EOPERATION_ADD );
				mInstructions.push_back(I);
				I.Clear();
				}
			}
			|
			IDENTIFIER ASSIGN OPEN_ROUND_BRACE constant COMMA constant COMMA constant CLOSE_ROUND_BRACE
			{
				if (gAutoVarMap.find($1) != gAutoVarMap.end())
				{
				std::ostringstream ret;
				ret << "Duplicated symbol " << $1 << "'\n";
				throw ret.str();
				}
				gAutoVarMap[ $1 ] = AllocAutoVar();
				
				unsigned int Destination = gAutoVarMap[ $1 ];
		
			
				I.SetDestZero( true );
				I.SetSrc1Displace( false );
				I.SetSrc0Displace( true );
		
		
				I.ClearWriteChannel();
				unsigned int ImmediateValue;
				{
				I.SetDestinationAddress( Destination );
				I.SetWriteChannel(ECHANNEL_X);
				std::string StringHex = $4;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				I.SetImm( ImmediateValue );
				I.SetDestZero( true );
				I.SetSrc1Displace( false );
				I.SetSrc0Displace( true );
				I.SetCode( EOPERATION_ADD );
				I.mSourceLine = GetCurrentLineNumber( yylloc );
				mInstructions.push_back(I);
				I.Clear();
				}
				{
				I.SetDestinationAddress( Destination );
				I.SetWriteChannel(ECHANNEL_Y);
				std::string StringHex = $6;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				I.SetImm( ImmediateValue );
				I.SetDestZero( true );
				I.SetSrc1Displace( false );
				I.SetSrc0Displace( true );
				I.SetCode( EOPERATION_ADD );
				mInstructions.push_back(I);
				I.Clear();
				}
				{
				I.SetDestinationAddress( Destination );
				I.SetWriteChannel(ECHANNEL_Z);
				std::string StringHex = $8;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				I.SetImm( ImmediateValue );
				I.SetDestZero( true );
				I.SetSrc1Displace( false );
				I.SetSrc0Displace( true );
				I.SetCode( EOPERATION_ADD );
				mInstructions.push_back(I);
				I.Clear();
				}
			}
			|
			IDENTIFIER array_size
			{
				
				if (gAutoVarMap.find($1) != gAutoVarMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol " << $1 << "'\n";
					throw ret.str();
				}
				std::stringstream ss;
				ss << std::hex << $2;
				unsigned int Size;
				ss >> Size;
				////std::cout  << "Array Size is " << Size << " " << $2 << "\n";
				gAutoVarMap[ $1 ] = AllocAutoVar(Size);
			}
			;

array_size
		 :
		 {
		 $$ = "1";
		 }
		 |
		 OPEN_SQUARE_BRACE constant CLOSE_SQUARE_BRACE
		 {
		
		 $$ = $2;
		 }
		 ;
%%



// Error function throws an exception (std::string) with the location and error message
void Theia::Parser::error(const Theia::Parser::location_type &loc,
                                          const std::string &msg) {
	std::ostringstream ret;
	ret << "Parser Error at " << loc << ": "  << msg;
	throw ret.str();
}

// Now that we have the Parser declared, we can declare the Scanner and implement
// the yylex function
#include "Scanner.h"
static int yylex(Theia::Parser::semantic_type * yylval,
                 Theia::Parser::location_type * yylloc,
                 Theia::Scanner &scanner) {
	return scanner.yylex(yylval, yylloc);
}

