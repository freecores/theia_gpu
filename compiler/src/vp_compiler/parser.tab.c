
/* A Bison parser, made by GNU Bison 2.4.1.  */

/* Skeleton implementation for Bison LALR(1) parsers in C++
   
      Copyright (C) 2002, 2003, 2004, 2005, 2006, 2007, 2008 Free Software
   Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */


/* First part of user declarations.  */


/* Line 311 of lalr1.cc  */
#line 41 "parser.tab.c"


#include "parser.tab.h"

/* User implementation prologue.  */


/* Line 317 of lalr1.cc  */
#line 50 "parser.tab.c"
/* Unqualified %code blocks.  */

/* Line 318 of lalr1.cc  */
#line 68 "parser.y"

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



/* Line 318 of lalr1.cc  */
#line 824 "parser.tab.c"

#ifndef YY_
# if YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* FIXME: INFRINGES ON USER NAME SPACE */
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#define YYUSE(e) ((void) (e))

/* Enable debugging if requested.  */
#if YYDEBUG

/* A pseudo ostream that takes yydebug_ into account.  */
# define YYCDEBUG if (yydebug_) (*yycdebug_)

# define YY_SYMBOL_PRINT(Title, Type, Value, Location)	\
do {							\
  if (yydebug_)						\
    {							\
      *yycdebug_ << Title << ' ';			\
      yy_symbol_print_ ((Type), (Value), (Location));	\
      *yycdebug_ << std::endl;				\
    }							\
} while (false)

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug_)				\
    yy_reduce_print_ (Rule);		\
} while (false)

# define YY_STACK_PRINT()		\
do {					\
  if (yydebug_)				\
    yystack_print_ ();			\
} while (false)

#else /* !YYDEBUG */

# define YYCDEBUG if (false) std::cerr
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
# define YY_REDUCE_PRINT(Rule)
# define YY_STACK_PRINT()

#endif /* !YYDEBUG */

#define yyerrok		(yyerrstatus_ = 0)
#define yyclearin	(yychar = yyempty_)

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrorlab
#define YYRECOVERING()  (!!yyerrstatus_)


/* Line 380 of lalr1.cc  */
#line 28 "parser.y"
namespace Theia {

/* Line 380 of lalr1.cc  */
#line 892 "parser.tab.c"
#if YYERROR_VERBOSE

  /* Return YYSTR after stripping away unnecessary quotes and
     backslashes, so that it's suitable for yyerror.  The heuristic is
     that double-quoting is unnecessary unless the string contains an
     apostrophe, a comma, or backslash (other than backslash-backslash).
     YYSTR is taken from yytname.  */
  std::string
  Parser::yytnamerr_ (const char *yystr)
  {
    if (*yystr == '"')
      {
        std::string yyr = "";
        char const *yyp = yystr;

        for (;;)
          switch (*++yyp)
            {
            case '\'':
            case ',':
              goto do_not_strip_quotes;

            case '\\':
              if (*++yyp != '\\')
                goto do_not_strip_quotes;
              /* Fall through.  */
            default:
              yyr += *yyp;
              break;

            case '"':
              return yyr;
            }
      do_not_strip_quotes: ;
      }

    return yystr;
  }

#endif

  /// Build a parser object.
  Parser::Parser (Theia::Scanner &scanner_yyarg, std::map<std::string,unsigned int>  & mSymbolMap_yyarg, std::vector< Instruction > &mInstructions_yyarg, bool &mGenerateFixedPointArithmetic_yyarg)
    :
#if YYDEBUG
      yydebug_ (false),
      yycdebug_ (&std::cerr),
#endif
      scanner (scanner_yyarg),
      mSymbolMap (mSymbolMap_yyarg),
      mInstructions (mInstructions_yyarg),
      mGenerateFixedPointArithmetic (mGenerateFixedPointArithmetic_yyarg)
  {
  }

  Parser::~Parser ()
  {
  }

#if YYDEBUG
  /*--------------------------------.
  | Print this symbol on YYOUTPUT.  |
  `--------------------------------*/

  inline void
  Parser::yy_symbol_value_print_ (int yytype,
			   const semantic_type* yyvaluep, const location_type* yylocationp)
  {
    YYUSE (yylocationp);
    YYUSE (yyvaluep);
    switch (yytype)
      {
         default:
	  break;
      }
  }


  void
  Parser::yy_symbol_print_ (int yytype,
			   const semantic_type* yyvaluep, const location_type* yylocationp)
  {
    *yycdebug_ << (yytype < yyntokens_ ? "token" : "nterm")
	       << ' ' << yytname_[yytype] << " ("
	       << *yylocationp << ": ";
    yy_symbol_value_print_ (yytype, yyvaluep, yylocationp);
    *yycdebug_ << ')';
  }
#endif

  void
  Parser::yydestruct_ (const char* yymsg,
			   int yytype, semantic_type* yyvaluep, location_type* yylocationp)
  {
    YYUSE (yylocationp);
    YYUSE (yymsg);
    YYUSE (yyvaluep);

    YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

    switch (yytype)
      {
  
	default:
	  break;
      }
  }

  void
  Parser::yypop_ (unsigned int n)
  {
    yystate_stack_.pop (n);
    yysemantic_stack_.pop (n);
    yylocation_stack_.pop (n);
  }

#if YYDEBUG
  std::ostream&
  Parser::debug_stream () const
  {
    return *yycdebug_;
  }

  void
  Parser::set_debug_stream (std::ostream& o)
  {
    yycdebug_ = &o;
  }


  Parser::debug_level_type
  Parser::debug_level () const
  {
    return yydebug_;
  }

  void
  Parser::set_debug_level (debug_level_type l)
  {
    yydebug_ = l;
  }
#endif

  int
  Parser::parse ()
  {
    /// Lookahead and lookahead in internal form.
    int yychar = yyempty_;
    int yytoken = 0;

    /* State.  */
    int yyn;
    int yylen = 0;
    int yystate = 0;

    /* Error handling.  */
    int yynerrs_ = 0;
    int yyerrstatus_ = 0;

    /// Semantic value of the lookahead.
    semantic_type yylval;
    /// Location of the lookahead.
    location_type yylloc;
    /// The locations where the error started and ended.
    location_type yyerror_range[2];

    /// $$.
    semantic_type yyval;
    /// @$.
    location_type yyloc;

    int yyresult;

    YYCDEBUG << "Starting parse" << std::endl;


    /* Initialize the stacks.  The initial state will be pushed in
       yynewstate, since the latter expects the semantical and the
       location values to have been already stored, initialize these
       stacks with a primary value.  */
    yystate_stack_ = state_stack_type (0);
    yysemantic_stack_ = semantic_stack_type (0);
    yylocation_stack_ = location_stack_type (0);
    yysemantic_stack_.push (yylval);
    yylocation_stack_.push (yylloc);

    /* New state.  */
  yynewstate:
    yystate_stack_.push (yystate);
    YYCDEBUG << "Entering state " << yystate << std::endl;

    /* Accept?  */
    if (yystate == yyfinal_)
      goto yyacceptlab;

    goto yybackup;

    /* Backup.  */
  yybackup:

    /* Try to take a decision without lookahead.  */
    yyn = yypact_[yystate];
    if (yyn == yypact_ninf_)
      goto yydefault;

    /* Read a lookahead token.  */
    if (yychar == yyempty_)
      {
	YYCDEBUG << "Reading a token: ";
	yychar = yylex (&yylval, &yylloc, scanner);
      }


    /* Convert token to internal form.  */
    if (yychar <= yyeof_)
      {
	yychar = yytoken = yyeof_;
	YYCDEBUG << "Now at end of input." << std::endl;
      }
    else
      {
	yytoken = yytranslate_ (yychar);
	YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
      }

    /* If the proper action on seeing token YYTOKEN is to reduce or to
       detect an error, take that action.  */
    yyn += yytoken;
    if (yyn < 0 || yylast_ < yyn || yycheck_[yyn] != yytoken)
      goto yydefault;

    /* Reduce or error.  */
    yyn = yytable_[yyn];
    if (yyn <= 0)
      {
	if (yyn == 0 || yyn == yytable_ninf_)
	goto yyerrlab;
	yyn = -yyn;
	goto yyreduce;
      }

    /* Shift the lookahead token.  */
    YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

    /* Discard the token being shifted.  */
    yychar = yyempty_;

    yysemantic_stack_.push (yylval);
    yylocation_stack_.push (yylloc);

    /* Count tokens shifted since error; after three, turn off error
       status.  */
    if (yyerrstatus_)
      --yyerrstatus_;

    yystate = yyn;
    goto yynewstate;

  /*-----------------------------------------------------------.
  | yydefault -- do the default action for the current state.  |
  `-----------------------------------------------------------*/
  yydefault:
    yyn = yydefact_[yystate];
    if (yyn == 0)
      goto yyerrlab;
    goto yyreduce;

  /*-----------------------------.
  | yyreduce -- Do a reduction.  |
  `-----------------------------*/
  yyreduce:
    yylen = yyr2_[yyn];
    /* If YYLEN is nonzero, implement the default value of the action:
       `$$ = $1'.  Otherwise, use the top of the stack.

       Otherwise, the following line sets YYVAL to garbage.
       This behavior is undocumented and Bison
       users should not rely upon it.  */
    if (yylen)
      yyval = yysemantic_stack_[yylen - 1];
    else
      yyval = yysemantic_stack_[0];

    {
      slice<location_type, location_stack_type> slice (yylocation_stack_, yylen);
      YYLLOC_DEFAULT (yyloc, slice, yylen);
    }
    YY_REDUCE_PRINT (yyn);
    switch (yyn)
      {
	  case 6:

/* Line 678 of lalr1.cc  */
#line 851 "parser.y"
    {
		mGenerateFixedPointArithmetic = true;
	}
    break;

  case 7:

/* Line 678 of lalr1.cc  */
#line 856 "parser.y"
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
    break;

  case 8:

/* Line 678 of lalr1.cc  */
#line 873 "parser.y"
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
			if ((yysemantic_stack_[(3) - (3)]).find("R") != std::string::npos)
			{
				PopulateInstruction( "R1", (yysemantic_stack_[(3) - (2)]),"R0 . X X X",I,yylloc);
			}
			else
			{
				unsigned int ImmediateValue = 0;
				std::string StringHex = (yysemantic_stack_[(3) - (3)]);
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				PopulateInstruction( "R1", (yysemantic_stack_[(3) - (3)]),"NULL",I, yylloc, true, ImmediateValue);
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
    break;

  case 9:

/* Line 678 of lalr1.cc  */
#line 940 "parser.y"
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
    break;

  case 10:

/* Line 678 of lalr1.cc  */
#line 968 "parser.y"
    {
		
		 I.mSourceLine = GetCurrentLineNumber( yylloc );
		 I.SetCode( EOPERATION_ADD );
		 SetDestinationFromRegister( (yysemantic_stack_[(4) - (1)]), I , true);
		 unsigned int ImmediateValue;
		 std::string StringHex = (yysemantic_stack_[(4) - (3)]);
		 std::stringstream ss;
		 ss << std::hex << StringHex;
		 ss >> ImmediateValue;
		 I.SetImm( ImmediateValue );
		 I.SetDestZero( false );
		 
		 mInstructions.push_back( I );
		 I.Clear();
	 }
    break;

  case 11:

/* Line 678 of lalr1.cc  */
#line 986 "parser.y"
    {
		
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetCode( EOPERATION_ADD );
		SetDestinationFromRegister( (yysemantic_stack_[(4) - (1)]), I, false );
		I.SetSrc0SignX( true );
		I.SetSrc0SignY( true );
		I.SetSrc0SignZ( true );
		std::string Destination = (yysemantic_stack_[(4) - (1)]);
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
    break;

  case 12:

/* Line 678 of lalr1.cc  */
#line 1015 "parser.y"
    {
		
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetCode( EOPERATION_ADD );
		SetDestinationFromRegister( (yysemantic_stack_[(4) - (1)]), I, false );
		std::string Destination = (yysemantic_stack_[(4) - (1)]);
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
    break;

  case 13:

/* Line 678 of lalr1.cc  */
#line 1040 "parser.y"
    {
		
		//////////////////////////////////////////////////////////////////////////////
		// This means this that the expression will read from the T memory
		// variable index
		// For example:
		//          vector MyAddress,MyReadValue;
		//          MyReadValue = in [ MyAddress ];
		//
		//////////////////////////////////////////////////////////////////////////////
		
		DCOUT << (yysemantic_stack_[(4) - (3)]) << " YYY \n";
		if ((yysemantic_stack_[(4) - (3)]).find("IN") != std::string::npos )
		{
			
			std::string ReadAddress = (yysemantic_stack_[(4) - (3)]);
			
			std::string SourceAddrRegister = ReadAddress.substr(ReadAddress.find("INDEX")+5);
			DCOUT << "!!!!!!!!!!!!!!!!!   " << ReadAddress << "\n";
			ReadAddress.erase(0,ReadAddress.find("IN")+3);
			DCOUT << "!!!!!!!!!!!!!!!!!   " << ReadAddress << "\n";
			
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
				
	
			PopulateSourceRegisters( ReadAddress, "R0", I, mInstructions );
			
			SetDestinationFromRegister( (yysemantic_stack_[(4) - (1)]), I, false );
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
	
		if ((yysemantic_stack_[(4) - (1)]).find("OUT") != std::string::npos && (yysemantic_stack_[(4) - (1)]).find("INDEX") == std::string::npos )
		{
			//PopulateInstruction( "R0", "R0 . X X X",$3,I,yylloc);
			
			I.SetCode(EOPERATION_IO); 
			I.SetIOOperation( EIO_OMWRITE );
			
			(yysemantic_stack_[(4) - (1)]).erase((yysemantic_stack_[(4) - (1)]).find("OUT"),3);
			
			unsigned int ImmediateValue;
			std::stringstream ss;
			ss << std::hex << (yysemantic_stack_[(4) - (1)]);
			ss >> ImmediateValue;
			PopulateInstruction( (yysemantic_stack_[(4) - (3)]), "R0 OFFSET", "R0 OFFSET", I, yylloc, true, ImmediateValue );
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
	
		if ((yysemantic_stack_[(4) - (1)]).find("OUT") != std::string::npos && (yysemantic_stack_[(4) - (1)]).find("INDEX") != std::string::npos )
		{
			std::string Destination = (yysemantic_stack_[(4) - (1)]);
			DCOUT << "!!!!!!!!!!!!!!!!!Destination " << Destination << "\n";
			std::string IndexRegister = Destination.substr(Destination.find("INDEX")+5);
			Destination.erase(Destination.find("INDEX"));
			
			
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
				
		//	PopulateSourceRegisters( IndexRegister + " OFFSET ", $3, I, mInstructions );
			PopulateSourceRegisters( IndexRegister, (yysemantic_stack_[(4) - (3)]), I, mInstructions );
			
			
			//I.SetImm( 0 );
			I.SetCode( EOPERATION_IO );
			I.SetIOOperation( EIO_OMWRITE );
			
			std::string Source0 = (yysemantic_stack_[(4) - (3)]);
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
			if ((yysemantic_stack_[(4) - (3)]).find("R") != std::string::npos)
			{
			// case 1:
			// foo = 0;        //$$ = R0 . X X X
			/*	SetDestinationFromRegister( $1, I, false );
				PopulateSourceRegisters( $3, "R0 . X X X", I, mInstructions);*/
				
				PopulateInstruction( (yysemantic_stack_[(4) - (1)]), "R0 . X X X",(yysemantic_stack_[(4) - (3)]),I,yylloc);
			
			} else {
			// case 2:
			// foo = 0xcafe;  //$$ = 0xcafe
				SetDestinationFromRegister( (yysemantic_stack_[(4) - (1)]), I, true );
				unsigned int ImmediateValue = 0;
				std::string StringHex = (yysemantic_stack_[(4) - (3)]);
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
							
				PopulateInstruction( (yysemantic_stack_[(4) - (1)]), (yysemantic_stack_[(4) - (3)]),"NULL",I, yylloc, true, ImmediateValue);
			}
			std::string strConstant = (yysemantic_stack_[(4) - (3)]);
			
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
			mInstructions[LastIndex].SetDestinationAddress(atoi((yysemantic_stack_[(4) - (1)]).c_str()+1));
			mInstructions[LastIndex-1].SetDestinationAddress(atoi((yysemantic_stack_[(4) - (1)]).c_str()+1));
			mInstructions[LastIndex-2].SetDestinationAddress(atoi((yysemantic_stack_[(4) - (1)]).c_str()+1));
			mInstructions[LastIndex-2].mSourceLine = GetCurrentLineNumber( yylloc );
			if((yysemantic_stack_[(4) - (1)]).find("OFFSET") == std::string::npos)
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
		if (I.GetOperation() == 0 && (yysemantic_stack_[(4) - (3)]).find("array_element") != std::string::npos)
		{
			//No operation meaning the the expression only has a single variable
			//See if the expression returned is an array_element 
			if ((yysemantic_stack_[(4) - (3)]).find("array_element") != std::string::npos)
			{
				////std::cout << "expression is an array element\n\n";
				std::string Index = (yysemantic_stack_[(4) - (3)]).substr((yysemantic_stack_[(4) - (3)]).find("array_element"));
				Index = Index.substr(Index.find_first_not_of("array_element R"));
				SetIndexRegister( atoi(Index.c_str()), mInstructions );
				(yysemantic_stack_[(4) - (3)]).erase((yysemantic_stack_[(4) - (3)]).find("array_element"));
				SetExpressionDestination( (yysemantic_stack_[(4) - (1)]), I );
				I.SetCode(EOPERATION_ADD);
				I.SetImmBit( true );
				I.SetDestZero( true );
				I.SetSrc1Displace( true ); 
				I.SetSrc0Displace( false ); 
				I.mSourceLine = GetCurrentLineNumber(yylloc);
				
				if ((yysemantic_stack_[(4) - (3)]).find("OFFSET") != std::string::npos)
					(yysemantic_stack_[(4) - (3)]).erase((yysemantic_stack_[(4) - (3)]).find("OFFSET"));
					
				I.SetSrc1Address(atoi((yysemantic_stack_[(4) - (3)]).c_str()+1));
				I.SetSrc0Address(0);
				mInstructions.push_back(I);
				I.Clear();
			}
		} 
		else 
		{
		
				mInstructions[ mInstructions.size() - gInsertedInstructions].mSourceLine = GetCurrentLineNumber(yylloc);
				gInsertedInstructions = 0;		
				std::string Destination = (yysemantic_stack_[(4) - (1)]);
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
				
					std::string Source0 = (yysemantic_stack_[(4) - (3)]);
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
						mInstructions.back().SetDestinationAddress( atoi((yysemantic_stack_[(4) - (1)]).c_str()+1) );
						for (int i = 1; i <= gExtraDestModifications; i++ )
						{
							int idx = (mInstructions.size()-1)-i;
							mInstructions[idx].SetDestinationAddress( atoi((yysemantic_stack_[(4) - (1)]).c_str()+1) );
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
    break;

  case 14:

/* Line 678 of lalr1.cc  */
#line 1358 "parser.y"
    { /*Middle rule here, get me the loop address*/ ;gWhileLoopAddress = (mInstructions.size());}
    break;

  case 15:

/* Line 678 of lalr1.cc  */
#line 1359 "parser.y"
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
    break;

  case 16:

/* Line 678 of lalr1.cc  */
#line 1390 "parser.y"
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
	  
	  
	}
    break;

  case 17:

/* Line 678 of lalr1.cc  */
#line 1408 "parser.y"
    {
	   
	   mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size());
	   gBranchStack.pop_back();
	   
	}
    break;

  case 18:

/* Line 678 of lalr1.cc  */
#line 1426 "parser.y"
    {
		mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size());
		//mInstructions[gBranchStack.back()].mSourceLine = GetCurrentLineNumber(yylloc);
		
		gBranchStack.pop_back();
		////std::cout << "if closing at " << mInstructions.size() << "\n";
		
	}
    break;

  case 19:

/* Line 678 of lalr1.cc  */
#line 1446 "parser.y"
    {
	  DCOUT << "Function declaration for " << (yysemantic_stack_[(5) - (2)]) << " at " << mInstructions.size() << "\n" ;
	  mSymbolMap[ (yysemantic_stack_[(5) - (2)]) ] = mInstructions.size();
	}
    break;

  case 20:

/* Line 678 of lalr1.cc  */
#line 1450 "parser.y"
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
    break;

  case 21:

/* Line 678 of lalr1.cc  */
#line 1485 "parser.y"
    {
		gThreadMap[ (yysemantic_stack_[(4) - (2)]) ] = mInstructions.size();
		gThreadScope = true;
	}
    break;

  case 22:

/* Line 678 of lalr1.cc  */
#line 1490 "parser.y"
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
    break;

  case 23:

/* Line 678 of lalr1.cc  */
#line 1516 "parser.y"
    {
		unsigned int ThreadCodeOffset = 0;
		////std::cout << "Starting thread" << "\n";
		if (gThreadMap.find((yysemantic_stack_[(5) - (2)])) == gThreadMap.end())
		{
			
			std::ostringstream ret;
			ret << "Undefined thread '" << (yysemantic_stack_[(5) - (2)]) << "' at line " << yylloc << " \n";
			ret << "Current version of the compiler needs thread defintion prior of thread instantiation\n";
			throw ret.str();
		} else {
			ThreadCodeOffset = gThreadMap[(yysemantic_stack_[(5) - (2)])];
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
    break;

  case 24:

/* Line 678 of lalr1.cc  */
#line 1565 "parser.y"
    {
		////std::cout << "Function call returning to var\n";
		StoreReturnAddress( mInstructions, yylloc );
		SavePreviousFramePointer( mInstructions );
		UpdateFramePointer( mInstructions );
		CallFunction( (yysemantic_stack_[(7) - (3)]), mInstructions, mSymbolMap );
		
		
		//Return value comes in R1, so let's store this in our variable
		I.SetCode( EOPERATION_ADD );
		SetDestinationFromRegister( (yysemantic_stack_[(7) - (1)]), I, false );
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
    break;

  case 25:

/* Line 678 of lalr1.cc  */
#line 1596 "parser.y"
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
		if (mSymbolMap.find((yysemantic_stack_[(5) - (1)])) == mSymbolMap.end())
		{
			//The destination is not yet declared
			//so leave it as a symbol so that it can latter
			//resolved by the linker
			I.SetDestinationSymbol( "@"+(yysemantic_stack_[(5) - (1)]) );
		} else {
			//The destination symbol has already been declared
			//so assign it right away
			I.SetDestinationAddress( mSymbolMap[ (yysemantic_stack_[(5) - (1)]) ] );
		}
		
		//Push the last instruction in the sequence and clean up	
		mInstructions.push_back( I );
		I.Clear();
		
	}
    break;

  case 27:

/* Line 678 of lalr1.cc  */
#line 1659 "parser.y"
    {
						AddFunctionInputList( (yysemantic_stack_[(3) - (1)]), mInstructions,yylloc );
					  }
    break;

  case 28:

/* Line 678 of lalr1.cc  */
#line 1664 "parser.y"
    {
						AddFunctionInputList( (yysemantic_stack_[(1) - (1)]),mInstructions, yylloc );
					  }
    break;

  case 30:

/* Line 678 of lalr1.cc  */
#line 1673 "parser.y"
    {
							AddFunctionParameter( (yysemantic_stack_[(3) - (1)]), yylloc );
						}
    break;

  case 31:

/* Line 678 of lalr1.cc  */
#line 1678 "parser.y"
    {
							AddFunctionParameter( (yysemantic_stack_[(1) - (1)]), yylloc );
						}
    break;

  case 32:

/* Line 678 of lalr1.cc  */
#line 1709 "parser.y"
    {
			unsigned int TempRegIndex  = GetFreeTempRegister();
			gExtraDestModifications = 0;
			
			I.SetCode( EOPERATION_ADD );
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
				
			PopulateSourceRegisters( (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions );
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			(yyval) = ss.str();
			
		}
    break;

  case 33:

/* Line 678 of lalr1.cc  */
#line 1730 "parser.y"
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
				
			PopulateSourceRegisters( (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions);
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			(yyval) = ss.str();
		}
    break;

  case 34:

/* Line 678 of lalr1.cc  */
#line 1752 "parser.y"
    {
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_LOGIC );
			I.SetLogicOperation( ELOGIC_OR );
			PopulateSourceRegisters( (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions);
			
						
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			(yyval) = ss.str();
		}
    break;

  case 35:

/* Line 678 of lalr1.cc  */
#line 1782 "parser.y"
    {
			std::string Register;
			if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(4) - (3)]))) != "NULL")
				(yyval) = "IN " + Register;
			else	
				(yyval) = "IN " + GetRegisterFromAutoVar( (yysemantic_stack_[(4) - (3)]), yylloc ) + " OFFSET ";
		}
    break;

  case 36:

/* Line 678 of lalr1.cc  */
#line 1791 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(1) - (1)]);
		}
    break;

  case 37:

/* Line 678 of lalr1.cc  */
#line 1799 "parser.y"
    {
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_MUL );
			
			PopulateSourceRegisters( (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions);
			
			//If we are using fixed point aritmethic then we need to apply the scale
			//R = A * ( B >> SCALE)
			if (mGenerateFixedPointArithmetic)
				I.SetSrc0Rotation( EROT_RESULT_RIGHT );
			
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			(yyval) = ss.str();
		}
    break;

  case 38:

/* Line 678 of lalr1.cc  */
#line 1824 "parser.y"
    {
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_DIV );
			
			PopulateSourceRegisters( (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions);
			
			//If we are using fixed point aritmethic then we need to apply the scale
			// R = (A << N) / B
			if (mGenerateFixedPointArithmetic)
				I.SetSrc1Rotation( EROT_SRC1_LEFT );
			
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			(yyval) = ss.str();
		}
    break;

  case 39:

/* Line 678 of lalr1.cc  */
#line 1849 "parser.y"
    {
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_LOGIC );
			I.SetLogicOperation( ELOGIC_AND );
			PopulateSourceRegisters( (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions);
			
						
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			(yyval) = ss.str();
		}
    break;

  case 40:

/* Line 678 of lalr1.cc  */
#line 1870 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(1) - (1)]);
		}
    break;

  case 41:

/* Line 678 of lalr1.cc  */
#line 1878 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(1) - (1)]);
		}
    break;

  case 42:

/* Line 678 of lalr1.cc  */
#line 1888 "parser.y"
    {
			gExtraDestModifications = 0;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetDestZero( true ); //Use indexing for DST
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_SQRT );
			I.SetSrc0Address( 0 );       
			PopulateSourceRegisters( (yysemantic_stack_[(4) - (3)]) ,"R0 . X X X", I, mInstructions);
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex << " OFFSET ";
			(yyval) = ss.str();
		}
    break;

  case 43:

/* Line 678 of lalr1.cc  */
#line 1907 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(3) - (2)]);
		}
    break;

  case 44:

/* Line 678 of lalr1.cc  */
#line 1917 "parser.y"
    {
	
		unsigned int ImmediateValue;
		std::string StringHex = (yysemantic_stack_[(1) - (1)]);
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		
		switch (ImmediateValue)
		{
		case 0:
			(yyval) = "R0 . X X X";
		break;
		case 1:
			(yyval) = "R0 . Y Y Y";
		break;
		case 2:
			(yyval) = "R0 . Z Z Z";
		break;
		default:
			std::string StringHex = (yysemantic_stack_[(1) - (1)]);
			std::stringstream ss;
			ss << std::hex << StringHex;
			ss >> ImmediateValue;
			(yyval) = ss.str();
			break;
		}
	}
    break;

  case 45:

/* Line 678 of lalr1.cc  */
#line 1947 "parser.y"
    {
		unsigned int TempRegIndex  = GetFreeTempRegister();
		unsigned int ImmediateValue;
		
		{
		
		std::string StringHex = (yysemantic_stack_[(7) - (2)]);
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
		std::string StringHex = (yysemantic_stack_[(7) - (4)]);
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
		std::string StringHex = (yysemantic_stack_[(7) - (6)]);
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
		(yyval) = ss2.str();
	}
    break;

  case 46:

/* Line 678 of lalr1.cc  */
#line 2012 "parser.y"
    {
		
		
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(2) - (1)]))) != "NULL")
			(yyval) = Register;
		 else
			(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(2) - (1)]), yylloc) + " OFFSET ";
			
		if ((yysemantic_stack_[(2) - (2)]) != "NULL")
		{
					
			(yyval) += " array_element " + (yysemantic_stack_[(2) - (2)]);
			
		}
	}
    break;

  case 47:

/* Line 678 of lalr1.cc  */
#line 2030 "parser.y"
    {
	
		std::string X = (yysemantic_stack_[(5) - (3)]),Y = (yysemantic_stack_[(5) - (4)]),Z = (yysemantic_stack_[(5) - (5)]);
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(5) - (1)]))) != "NULL")
			(yyval) = (Register + " . " + " " + X + " " + Y  + " " + Z/* + " OFFSET "*/);
		else
			(yyval) = (GetRegisterFromAutoVar( (yysemantic_stack_[(5) - (1)]), yylloc) + " . " + " " + X + " " + Y  + " " + Z + " OFFSET ");
	}
    break;

  case 48:

/* Line 678 of lalr1.cc  */
#line 2041 "parser.y"
    {
		
		std::string R = (yysemantic_stack_[(1) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R;
		
	}
    break;

  case 49:

/* Line 678 of lalr1.cc  */
#line 2050 "parser.y"
    {
	
		std::string R = (yysemantic_stack_[(4) - (1)]);
		R.erase(0,1);
		(yyval) = "<<R" + R;
	}
    break;

  case 50:

/* Line 678 of lalr1.cc  */
#line 2058 "parser.y"
    {
	
		std::string R = (yysemantic_stack_[(4) - (1)]);
		R.erase(0,1);
		(yyval) = ">>R" + R;
	}
    break;

  case 51:

/* Line 678 of lalr1.cc  */
#line 2066 "parser.y"
    {
		std::string R = (yysemantic_stack_[(5) - (1)]);
		std::string X = (yysemantic_stack_[(5) - (3)]),Y = (yysemantic_stack_[(5) - (4)]),Z = (yysemantic_stack_[(5) - (5)]);
		R.erase(0,1);
		(yyval) = "R" + R + " . " + " " + X + " " + Y  + " " + Z;
	
	}
    break;

  case 52:

/* Line 678 of lalr1.cc  */
#line 2079 "parser.y"
    {
		(yyval) = "X";
	}
    break;

  case 53:

/* Line 678 of lalr1.cc  */
#line 2084 "parser.y"
    {
		(yyval) = "-X";
	}
    break;

  case 54:

/* Line 678 of lalr1.cc  */
#line 2089 "parser.y"
    {
		(yyval) = "Y";
	}
    break;

  case 55:

/* Line 678 of lalr1.cc  */
#line 2094 "parser.y"
    {
		(yyval) = "-Y";
	}
    break;

  case 56:

/* Line 678 of lalr1.cc  */
#line 2099 "parser.y"
    {
		(yyval) = "Z";
	}
    break;

  case 57:

/* Line 678 of lalr1.cc  */
#line 2104 "parser.y"
    {
		(yyval) = "-Z";
	}
    break;

  case 58:

/* Line 678 of lalr1.cc  */
#line 2112 "parser.y"
    {
		(yyval) = "NULL";
	}
    break;

  case 59:

/* Line 678 of lalr1.cc  */
#line 2117 "parser.y"
    {
		/*std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($2)) != "NULL")
			$$ = Register;
		else*/
		//Indexes into arrays can only be auto variables!
		(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(3) - (2)]), yylloc );
	}
    break;

  case 60:

/* Line 678 of lalr1.cc  */
#line 2130 "parser.y"
    {
		
		(yyval) = "OUT " + (yysemantic_stack_[(4) - (3)]);
	}
    break;

  case 61:

/* Line 678 of lalr1.cc  */
#line 2136 "parser.y"
    {
	
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(4) - (3)]))) != "NULL")
			(yyval) = "OUT INDEX" + Register;
		else	
			(yyval) = "OUT INDEX" + GetRegisterFromAutoVar( (yysemantic_stack_[(4) - (3)]), yylloc ) + " OFFSET ";
		
		
		
	}
    break;

  case 62:

/* Line 678 of lalr1.cc  */
#line 2149 "parser.y"
    {
		
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(2) - (1)]))) != "NULL")
			(yyval) = Register + ".xyz";
		else
			(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(2) - (1)]), yylloc ) + ".xyz" + " OFFSET " + (((yysemantic_stack_[(2) - (2)]) != "NULL")?" INDEX"+(yysemantic_stack_[(2) - (2)]):"");
		
	}
    break;

  case 63:

/* Line 678 of lalr1.cc  */
#line 2160 "parser.y"
    {
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(3) - (1)]))) != "NULL")
			(yyval) = Register + ".x";
		else
		(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(3) - (1)]), yylloc ) + ".x" + " OFFSET ";
	}
    break;

  case 64:

/* Line 678 of lalr1.cc  */
#line 2169 "parser.y"
    {
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(3) - (1)]))) != "NULL")
			(yyval) = Register + ".y";
		else
			(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(3) - (1)]), yylloc ) + ".y" + " OFFSET ";
	}
    break;

  case 65:

/* Line 678 of lalr1.cc  */
#line 2178 "parser.y"
    {
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(3) - (1)]))) != "NULL")
			(yyval) = Register + ".z";
		else
			(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(3) - (1)]), yylloc ) + ".z" + " OFFSET ";
	}
    break;

  case 66:

/* Line 678 of lalr1.cc  */
#line 2187 "parser.y"
    {
		std::string R = (yysemantic_stack_[(1) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".xyz";
	}
    break;

  case 67:

/* Line 678 of lalr1.cc  */
#line 2194 "parser.y"
    {
		std::string R = (yysemantic_stack_[(3) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".x";
	}
    break;

  case 68:

/* Line 678 of lalr1.cc  */
#line 2201 "parser.y"
    {
		std::string R = (yysemantic_stack_[(3) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".y";
	}
    break;

  case 69:

/* Line 678 of lalr1.cc  */
#line 2208 "parser.y"
    {
		
		std::string R = (yysemantic_stack_[(3) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".z";
	}
    break;

  case 70:

/* Line 678 of lalr1.cc  */
#line 2216 "parser.y"
    {
		std::string R = (yysemantic_stack_[(5) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".xy";
	}
    break;

  case 71:

/* Line 678 of lalr1.cc  */
#line 2223 "parser.y"
    {
		std::string R = (yysemantic_stack_[(5) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".xz";
	}
    break;

  case 72:

/* Line 678 of lalr1.cc  */
#line 2230 "parser.y"
    {
		std::string R = (yysemantic_stack_[(5) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".yz";
	}
    break;

  case 73:

/* Line 678 of lalr1.cc  */
#line 2241 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_ZERO, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 74:

/* Line 678 of lalr1.cc  */
#line 2247 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_NOT_ZERO, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 75:

/* Line 678 of lalr1.cc  */
#line 2253 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_ZERO_OR_SIGN, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 76:

/* Line 678 of lalr1.cc  */
#line 2260 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_ZERO_OR_NOT_SIGN, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
				
				}
    break;

  case 77:

/* Line 678 of lalr1.cc  */
#line 2266 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_NOT_SIGN, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 78:

/* Line 678 of lalr1.cc  */
#line 2272 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_SIGN, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 79:

/* Line 678 of lalr1.cc  */
#line 2281 "parser.y"
    {
			// Transform to HEX string
			unsigned int Val;
			std::string StringDec = (yysemantic_stack_[(1) - (1)]);
			std::stringstream ss;
			ss << StringDec;
			ss >> Val;
			std::stringstream ss2;
			ss2 << std::hex << Val;
			(yyval) = ss2.str();
		}
    break;

  case 80:

/* Line 678 of lalr1.cc  */
#line 2294 "parser.y"
    {
			std::string StringHex = (yysemantic_stack_[(1) - (1)]);
			// Get rid of the 0x
			StringHex.erase(StringHex.begin(),StringHex.begin()+2);
			std::stringstream ss;
			ss << std::hex << StringHex;
			
			(yyval) = ss.str();
		}
    break;

  case 81:

/* Line 678 of lalr1.cc  */
#line 2305 "parser.y"
    {
			// Transform to HEX string
			std::string StringBin = (yysemantic_stack_[(1) - (1)]);
			// Get rid of the 0b
			StringBin.erase(StringBin.begin(),StringBin.begin()+2);
			std::bitset<32> Bitset( StringBin );
			std::stringstream ss2;
			ss2 << std::hex <<  Bitset.to_ulong();
			(yyval) = ss2.str();
		}
    break;

  case 82:

/* Line 678 of lalr1.cc  */
#line 2319 "parser.y"
    {
				if (gAutoVarMap.find((yysemantic_stack_[(4) - (1)])) != gAutoVarMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << (yysemantic_stack_[(4) - (1)]) << "'\n";
					throw ret.str();
				}
				
				std::stringstream ss;
				ss << (yysemantic_stack_[(4) - (2)]);
				unsigned int Size;
				ss >> Size;
				gAutoVarMap[ (yysemantic_stack_[(4) - (1)]) ] = AllocAutoVar(Size);
			}
    break;

  case 83:

/* Line 678 of lalr1.cc  */
#line 2335 "parser.y"
    {
				if (gAutoVarMap.find((yysemantic_stack_[(11) - (1)])) != gAutoVarMap.end())
				{
				std::ostringstream ret;
				ret << "Duplicated symbol " << (yysemantic_stack_[(11) - (1)]) << "'\n";
				throw ret.str();
				}
				gAutoVarMap[ (yysemantic_stack_[(11) - (1)]) ] = AllocAutoVar();
				
				unsigned int Destination = gAutoVarMap[ (yysemantic_stack_[(11) - (1)]) ];
		
					
		
				I.ClearWriteChannel();
				unsigned int ImmediateValue;
				{
				I.SetDestinationAddress( Destination );
				I.SetWriteChannel(ECHANNEL_X);
				std::string StringHex = (yysemantic_stack_[(11) - (4)]);
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
				std::string StringHex = (yysemantic_stack_[(11) - (6)]);
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
				std::string StringHex = (yysemantic_stack_[(11) - (8)]);
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
    break;

  case 84:

/* Line 678 of lalr1.cc  */
#line 2399 "parser.y"
    {
				if (gAutoVarMap.find((yysemantic_stack_[(9) - (1)])) != gAutoVarMap.end())
				{
				std::ostringstream ret;
				ret << "Duplicated symbol " << (yysemantic_stack_[(9) - (1)]) << "'\n";
				throw ret.str();
				}
				gAutoVarMap[ (yysemantic_stack_[(9) - (1)]) ] = AllocAutoVar();
				
				unsigned int Destination = gAutoVarMap[ (yysemantic_stack_[(9) - (1)]) ];
		
			
				I.SetDestZero( true );
				I.SetSrc1Displace( false );
				I.SetSrc0Displace( true );
		
		
				I.ClearWriteChannel();
				unsigned int ImmediateValue;
				{
				I.SetDestinationAddress( Destination );
				I.SetWriteChannel(ECHANNEL_X);
				std::string StringHex = (yysemantic_stack_[(9) - (4)]);
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
				std::string StringHex = (yysemantic_stack_[(9) - (6)]);
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
				std::string StringHex = (yysemantic_stack_[(9) - (8)]);
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
    break;

  case 85:

/* Line 678 of lalr1.cc  */
#line 2467 "parser.y"
    {
				
				if (gAutoVarMap.find((yysemantic_stack_[(2) - (1)])) != gAutoVarMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol " << (yysemantic_stack_[(2) - (1)]) << "'\n";
					throw ret.str();
				}
				std::stringstream ss;
				ss << std::hex << (yysemantic_stack_[(2) - (2)]);
				unsigned int Size;
				ss >> Size;
				////std::cout  << "Array Size is " << Size << " " << $2 << "\n";
				gAutoVarMap[ (yysemantic_stack_[(2) - (1)]) ] = AllocAutoVar(Size);
			}
    break;

  case 86:

/* Line 678 of lalr1.cc  */
#line 2486 "parser.y"
    {
		 (yyval) = "1";
		 }
    break;

  case 87:

/* Line 678 of lalr1.cc  */
#line 2491 "parser.y"
    {
		
		 (yyval) = (yysemantic_stack_[(3) - (2)]);
		 }
    break;



/* Line 678 of lalr1.cc  */
#line 3006 "parser.tab.c"
	default:
          break;
      }
    YY_SYMBOL_PRINT ("-> $$ =", yyr1_[yyn], &yyval, &yyloc);

    yypop_ (yylen);
    yylen = 0;
    YY_STACK_PRINT ();

    yysemantic_stack_.push (yyval);
    yylocation_stack_.push (yyloc);

    /* Shift the result of the reduction.  */
    yyn = yyr1_[yyn];
    yystate = yypgoto_[yyn - yyntokens_] + yystate_stack_[0];
    if (0 <= yystate && yystate <= yylast_
	&& yycheck_[yystate] == yystate_stack_[0])
      yystate = yytable_[yystate];
    else
      yystate = yydefgoto_[yyn - yyntokens_];
    goto yynewstate;

  /*------------------------------------.
  | yyerrlab -- here on detecting error |
  `------------------------------------*/
  yyerrlab:
    /* If not already recovering from an error, report this error.  */
    if (!yyerrstatus_)
      {
	++yynerrs_;
	error (yylloc, yysyntax_error_ (yystate, yytoken));
      }

    yyerror_range[0] = yylloc;
    if (yyerrstatus_ == 3)
      {
	/* If just tried and failed to reuse lookahead token after an
	 error, discard it.  */

	if (yychar <= yyeof_)
	  {
	  /* Return failure if at end of input.  */
	  if (yychar == yyeof_)
	    YYABORT;
	  }
	else
	  {
	    yydestruct_ ("Error: discarding", yytoken, &yylval, &yylloc);
	    yychar = yyempty_;
	  }
      }

    /* Else will try to reuse lookahead token after shifting the error
       token.  */
    goto yyerrlab1;


  /*---------------------------------------------------.
  | yyerrorlab -- error raised explicitly by YYERROR.  |
  `---------------------------------------------------*/
  yyerrorlab:

    /* Pacify compilers like GCC when the user code never invokes
       YYERROR and the label yyerrorlab therefore never appears in user
       code.  */
    if (false)
      goto yyerrorlab;

    yyerror_range[0] = yylocation_stack_[yylen - 1];
    /* Do not reclaim the symbols of the rule which action triggered
       this YYERROR.  */
    yypop_ (yylen);
    yylen = 0;
    yystate = yystate_stack_[0];
    goto yyerrlab1;

  /*-------------------------------------------------------------.
  | yyerrlab1 -- common code for both syntax error and YYERROR.  |
  `-------------------------------------------------------------*/
  yyerrlab1:
    yyerrstatus_ = 3;	/* Each real token shifted decrements this.  */

    for (;;)
      {
	yyn = yypact_[yystate];
	if (yyn != yypact_ninf_)
	{
	  yyn += yyterror_;
	  if (0 <= yyn && yyn <= yylast_ && yycheck_[yyn] == yyterror_)
	    {
	      yyn = yytable_[yyn];
	      if (0 < yyn)
		break;
	    }
	}

	/* Pop the current state because it cannot handle the error token.  */
	if (yystate_stack_.height () == 1)
	YYABORT;

	yyerror_range[0] = yylocation_stack_[0];
	yydestruct_ ("Error: popping",
		     yystos_[yystate],
		     &yysemantic_stack_[0], &yylocation_stack_[0]);
	yypop_ ();
	yystate = yystate_stack_[0];
	YY_STACK_PRINT ();
      }

    yyerror_range[1] = yylloc;
    // Using YYLLOC is tempting, but would change the location of
    // the lookahead.  YYLOC is available though.
    YYLLOC_DEFAULT (yyloc, (yyerror_range - 1), 2);
    yysemantic_stack_.push (yylval);
    yylocation_stack_.push (yyloc);

    /* Shift the error token.  */
    YY_SYMBOL_PRINT ("Shifting", yystos_[yyn],
		     &yysemantic_stack_[0], &yylocation_stack_[0]);

    yystate = yyn;
    goto yynewstate;

    /* Accept.  */
  yyacceptlab:
    yyresult = 0;
    goto yyreturn;

    /* Abort.  */
  yyabortlab:
    yyresult = 1;
    goto yyreturn;

  yyreturn:
    if (yychar != yyempty_)
      yydestruct_ ("Cleanup: discarding lookahead", yytoken, &yylval, &yylloc);

    /* Do not reclaim the symbols of the rule which action triggered
       this YYABORT or YYACCEPT.  */
    yypop_ (yylen);
    while (yystate_stack_.height () != 1)
      {
	yydestruct_ ("Cleanup: popping",
		   yystos_[yystate_stack_[0]],
		   &yysemantic_stack_[0],
		   &yylocation_stack_[0]);
	yypop_ ();
      }

    return yyresult;
  }

  // Generate an error message.
  std::string
  Parser::yysyntax_error_ (int yystate, int tok)
  {
    std::string res;
    YYUSE (yystate);
#if YYERROR_VERBOSE
    int yyn = yypact_[yystate];
    if (yypact_ninf_ < yyn && yyn <= yylast_)
      {
	/* Start YYX at -YYN if negative to avoid negative indexes in
	   YYCHECK.  */
	int yyxbegin = yyn < 0 ? -yyn : 0;

	/* Stay within bounds of both yycheck and yytname.  */
	int yychecklim = yylast_ - yyn + 1;
	int yyxend = yychecklim < yyntokens_ ? yychecklim : yyntokens_;
	int count = 0;
	for (int x = yyxbegin; x < yyxend; ++x)
	  if (yycheck_[x + yyn] == x && x != yyterror_)
	    ++count;

	// FIXME: This method of building the message is not compatible
	// with internationalization.  It should work like yacc.c does it.
	// That is, first build a string that looks like this:
	// "syntax error, unexpected %s or %s or %s"
	// Then, invoke YY_ on this string.
	// Finally, use the string as a format to output
	// yytname_[tok], etc.
	// Until this gets fixed, this message appears in English only.
	res = "syntax error, unexpected ";
	res += yytnamerr_ (yytname_[tok]);
	if (count < 5)
	  {
	    count = 0;
	    for (int x = yyxbegin; x < yyxend; ++x)
	      if (yycheck_[x + yyn] == x && x != yyterror_)
		{
		  res += (!count++) ? ", expecting " : " or ";
		  res += yytnamerr_ (yytname_[x]);
		}
	  }
      }
    else
#endif
      res = YY_("syntax error");
    return res;
  }


  /* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
     STATE-NUM.  */
  const signed char Parser::yypact_ninf_ = -126;
  const short int
  Parser::yypact_[] =
  {
       258,   -21,    92,   -15,    -6,    24,    13,    -9,     5,  -126,
      28,    43,     6,     8,  -126,   126,   -11,    44,   252,  -126,
    -126,  -126,  -126,    55,   -12,    74,    76,    77,    54,   110,
     -16,  -126,  -126,  -126,    84,  -126,   252,   188,   252,   157,
      68,  -126,    85,    88,    98,    99,   138,  -126,  -126,   275,
     109,   106,   177,   120,   177,   100,  -126,    36,   101,   199,
     199,  -126,   252,   113,   114,   118,   298,  -126,   298,   298,
     298,   298,   298,   121,    15,   127,    41,  -126,  -126,   134,
     128,    50,  -126,  -126,  -126,   135,  -126,   252,   160,   166,
     142,   149,    18,   111,   168,   169,   171,   177,   162,   -21,
    -126,   177,   213,  -126,  -126,  -126,   199,   199,    52,   196,
     197,   173,   -16,   -16,   -16,  -126,  -126,  -126,   185,   215,
     252,   252,   252,   252,   252,   252,   217,   200,   204,   208,
     214,   252,  -126,   229,  -126,   221,  -126,  -126,   252,  -126,
    -126,  -126,  -126,   210,  -126,  -126,   211,  -126,  -126,  -126,
     199,   199,  -126,  -126,  -126,  -126,   121,  -126,    82,    82,
      82,    82,    82,    82,   258,  -126,  -126,  -126,  -126,  -126,
     242,   251,  -126,   254,   177,   177,  -126,  -126,  -126,   255,
      63,   258,   258,   247,   234,   262,   258,   265,   147,   165,
    -126,   177,  -126,   203,  -126,  -126,  -126,   264,  -126,   266,
     241,   258,   -21,   220,  -126,  -126
  };

  /* YYDEFACT[S] -- default rule to reduce with in state S when YYTABLE
     doesn't specify something else to do.  Zero means the default is an
     error.  */
  const unsigned char
  Parser::yydefact_[] =
  {
         2,     0,     0,     0,     0,     0,    66,    58,     0,    14,
       0,     0,     0,     0,     4,     0,    86,     0,     0,    79,
      80,    81,     9,    48,    58,     0,     0,     0,     0,     0,
      36,    40,    41,    44,     0,     7,     0,     0,    26,     0,
       0,    62,     0,     0,     0,     0,     0,     1,     3,     0,
       0,     0,     0,     0,     0,    85,     5,     0,    44,     0,
       0,    46,     0,     0,     0,     0,     0,     8,     0,     0,
       0,     0,     0,    29,     0,     0,    67,    68,    69,     0,
       0,    28,    63,    64,    65,     0,     6,     0,     0,     0,
       0,     0,    58,     0,     0,     0,     0,     0,     0,     0,
      43,     0,     0,    52,    54,    56,     0,     0,     0,     0,
       0,     0,    32,    33,    34,    38,    37,    39,    31,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    26,    59,     0,    21,     0,    61,    60,    26,    13,
      12,    11,    10,     0,    87,    82,     0,    53,    55,    57,
       0,     0,    42,    49,    50,    35,    29,    19,    74,    73,
      75,    76,    77,    78,     2,    70,    71,    72,    25,    27,
       0,     0,    23,     0,     0,     0,    51,    47,    30,     0,
       0,     2,     2,     0,     0,     0,     2,    18,     0,     0,
      24,     0,    45,     0,    16,    15,    22,     0,    20,     0,
      84,     2,     0,     0,    83,    17
  };

  /* YYPGOTO[NTERM-NUM].  */
  const short int
  Parser::yypgoto_[] =
  {
      -126,  -125,   -13,  -126,  -126,  -126,  -126,  -121,   129,     0,
      20,   186,  -126,   -56,   276,  -126,   207,   -17,   -96,  -126
  };

  /* YYDEFGOTO[NTERM-NUM].  */
  const short int
  Parser::yydefgoto_[] =
  {
        -1,    13,    14,    43,   199,   179,   171,    80,   119,    81,
      30,    31,    32,   106,    61,    15,    75,    33,    17,    55
  };

  /* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
     positive, shift that token.  If negative, reduce the rule which
     number is the opposite.  If zero, do what YYDEFACT says.  */
  const signed char Parser::yytable_ninf_ = -1;
  const unsigned char
  Parser::yytable_[] =
  {
        48,    58,    29,   145,   107,    70,    71,    38,    47,    53,
     169,     1,     2,     3,    16,     4,    60,   173,    57,    39,
      34,    35,     5,   120,   121,   122,   123,   124,   125,    91,
      40,    54,    72,    40,   138,    96,    74,    98,    66,   180,
      36,    37,     6,     7,    68,    42,    60,     8,    46,    93,
     150,   151,     9,   100,    10,    11,   188,   189,    12,    66,
      40,   193,   108,    44,    69,    68,     1,     2,     3,   152,
       4,    56,   127,    66,   128,    66,   203,     5,    45,    68,
     143,    68,   187,    59,   146,    69,   112,    74,   113,   114,
      62,   131,    63,    64,   176,   177,    65,     6,     7,    69,
      73,    69,     8,    85,    87,    66,   204,     9,    18,    10,
      11,    68,    86,    12,    88,    89,    19,    20,    21,    22,
     158,   159,   160,   161,   162,   163,    23,    24,    25,    26,
      27,    69,    94,    66,    66,    95,    97,    67,   139,    68,
      68,    99,   101,    28,   126,   130,    49,   109,   110,    50,
       1,     2,     3,   111,     4,    51,   118,   184,   185,    69,
      69,     5,    19,    20,    21,   129,   195,    48,     1,     2,
       3,    52,     4,    90,   197,    48,    48,   134,   132,     5,
      48,     6,     7,   135,   196,   136,     8,    82,    83,    84,
      48,     9,   137,    10,    11,   140,   141,    12,   142,     6,
       7,    19,    20,    21,     8,   144,     1,     2,     3,     9,
       4,    10,    11,   153,   154,    12,   155,     5,    76,    77,
      78,    79,   198,     1,     2,     3,   156,     4,   102,   103,
     104,   105,   157,   165,     5,   164,   166,     6,     7,   205,
     167,   168,     8,   147,   148,   149,   170,     9,   172,    10,
      11,   174,   175,    12,     6,     7,   115,   116,   117,     8,
     181,     1,     2,     3,     9,     4,    10,    11,    18,   182,
      12,   183,     5,   186,   190,   191,    19,    20,    21,   192,
     194,   200,   202,    41,   201,   178,    23,    24,    25,    26,
      27,    18,     6,     7,   133,     0,     0,     8,     0,    19,
      20,    21,     9,    28,    10,    11,     0,     0,    12,    23,
      92,    25,    26,    27,    18,     0,     0,     0,     0,     0,
       0,     0,    19,    20,    21,     0,    28,     0,     0,     0,
       0,     0,    23,    24,    25,    26,    27
  };

  /* YYCHECK.  */
  const short int
  Parser::yycheck_[] =
  {
        13,    18,     2,    99,    60,    21,    22,    16,     0,    20,
     131,     3,     4,     5,    35,     7,    28,   138,    18,    28,
      35,    27,    14,     8,     9,    10,    11,    12,    13,    46,
      42,    42,    48,    42,    16,    52,    36,    54,    23,   164,
      16,    28,    34,    35,    29,    40,    28,    39,    42,    49,
     106,   107,    44,    17,    46,    47,   181,   182,    50,    23,
      42,   186,    62,    35,    49,    29,     3,     4,     5,    17,
       7,    27,    31,    23,    33,    23,   201,    14,    35,    29,
      97,    29,    19,    28,   101,    49,    66,    87,    68,    69,
      16,    41,    16,    16,   150,   151,    42,    34,    35,    49,
      16,    49,    39,    35,    16,    23,   202,    44,    16,    46,
      47,    29,    27,    50,    16,    16,    24,    25,    26,    27,
     120,   121,   122,   123,   124,   125,    34,    35,    36,    37,
      38,    49,    23,    23,    23,    29,    16,    27,    27,    29,
      29,    41,    41,    51,    17,    17,    20,    34,    34,    23,
       3,     4,     5,    35,     7,    29,    35,   174,   175,    49,
      49,    14,    24,    25,    26,    31,    19,   180,     3,     4,
       5,    45,     7,    35,   191,   188,   189,    17,    43,    14,
     193,    34,    35,    17,    19,    43,    39,    30,    31,    32,
     203,    44,    43,    46,    47,    27,    27,    50,    27,    34,
      35,    24,    25,    26,    39,    43,     3,     4,     5,    44,
       7,    46,    47,    17,    17,    50,    43,    14,    30,    31,
      32,    33,    19,     3,     4,     5,    41,     7,    29,    30,
      31,    32,    17,    33,    14,    18,    32,    34,    35,    19,
      32,    27,    39,    30,    31,    32,    17,    44,    27,    46,
      47,    41,    41,    50,    34,    35,    70,    71,    72,    39,
      18,     3,     4,     5,    44,     7,    46,    47,    16,    18,
      50,    17,    14,    18,    27,    41,    24,    25,    26,    17,
      15,    17,    41,     7,    18,   156,    34,    35,    36,    37,
      38,    16,    34,    35,    87,    -1,    -1,    39,    -1,    24,
      25,    26,    44,    51,    46,    47,    -1,    -1,    50,    34,
      35,    36,    37,    38,    16,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    24,    25,    26,    -1,    51,    -1,    -1,    -1,
      -1,    -1,    34,    35,    36,    37,    38
  };

  /* STOS_[STATE-NUM] -- The (internal number of the) accessing
     symbol of state STATE-NUM.  */
  const unsigned char
  Parser::yystos_[] =
  {
         0,     3,     4,     5,     7,    14,    34,    35,    39,    44,
      46,    47,    50,    53,    54,    67,    35,    70,    16,    24,
      25,    26,    27,    34,    35,    36,    37,    38,    51,    61,
      62,    63,    64,    69,    35,    27,    16,    28,    16,    28,
      42,    66,    40,    55,    35,    35,    42,     0,    54,    20,
      23,    29,    45,    20,    42,    71,    27,    61,    69,    28,
      28,    66,    16,    16,    16,    42,    23,    27,    29,    49,
      21,    22,    48,    16,    61,    68,    30,    31,    32,    33,
      59,    61,    30,    31,    32,    35,    27,    16,    16,    16,
      35,    69,    35,    61,    23,    29,    69,    16,    69,    41,
      17,    41,    29,    30,    31,    32,    65,    65,    61,    34,
      34,    35,    62,    62,    62,    63,    63,    63,    35,    60,
       8,     9,    10,    11,    12,    13,    17,    31,    33,    31,
      17,    41,    43,    68,    17,    17,    43,    43,    16,    27,
      27,    27,    27,    69,    43,    70,    69,    30,    31,    32,
      65,    65,    17,    17,    17,    43,    41,    17,    61,    61,
      61,    61,    61,    61,    18,    33,    32,    32,    27,    59,
      17,    58,    27,    59,    41,    41,    65,    65,    60,    57,
      53,    18,    18,    17,    69,    69,    18,    19,    53,    53,
      27,    41,    17,    53,    15,    19,    19,    69,    19,    56,
      17,    18,    41,    53,    70,    19
  };

#if YYDEBUG
  /* TOKEN_NUMBER_[YYLEX-NUM] -- Internal symbol number corresponding
     to YYLEX-NUM.  */
  const unsigned short int
  Parser::yytoken_number_[] =
  {
         0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306
  };
#endif

  /* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
  const unsigned char
  Parser::yyr1_[] =
  {
         0,    52,    53,    53,    53,    54,    54,    54,    54,    54,
      54,    54,    54,    54,    55,    54,    56,    54,    54,    57,
      54,    58,    54,    54,    54,    54,    59,    59,    59,    60,
      60,    60,    61,    61,    61,    61,    61,    62,    62,    62,
      62,    63,    63,    63,    64,    64,    64,    64,    64,    64,
      64,    64,    65,    65,    65,    65,    65,    65,    66,    66,
      67,    67,    67,    67,    67,    67,    67,    67,    67,    67,
      67,    67,    67,    68,    68,    68,    68,    68,    68,    69,
      69,    69,    70,    70,    70,    70,    71,    71
  };

  /* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
  const unsigned char
  Parser::yyr2_[] =
  {
         0,     2,     0,     2,     1,     3,     3,     2,     3,     2,
       4,     4,     4,     4,     0,     8,     0,    12,     7,     0,
       9,     0,     8,     5,     7,     5,     0,     3,     1,     0,
       3,     1,     3,     3,     3,     4,     1,     3,     3,     3,
       1,     1,     4,     3,     1,     7,     2,     5,     1,     4,
       4,     5,     1,     2,     1,     2,     1,     2,     0,     3,
       4,     4,     2,     3,     3,     3,     1,     3,     3,     3,
       5,     5,     5,     3,     3,     3,     3,     3,     3,     1,
       1,     1,     4,    11,     9,     2,     0,     3
  };

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
  /* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
     First, the terminals, then, starting at \a yyntokens_, nonterminals.  */
  const char*
  const Parser::yytname_[] =
  {
    "$end", "error", "$undefined", "AUTO", "RETURN", "FUNCTION", "JMP",
  "EXIT", "EQUAL", "NOT_EQUAL", "GREATER_THAN", "LESS_THAN",
  "LESS_OR_EQUAL_THAN", "GREATER_OR_EQUAL_THAN", "IF", "ELSE",
  "OPEN_ROUND_BRACE", "CLOSE_ROUND_BRACE", "OPEN_BRACE", "CLOSE_BRACE",
  "ASSIGN", "DIV", "MUL", "ADD", "DECCONST", "HEXCONST", "BINCONST", "EOS",
  "DOT", "MINUS", "TK_X", "TK_Y", "TK_Z", "TK_N", "REG", "IDENTIFIER",
  "SQRT", "SCALE", "UNSCALE", "USING", "FIXED_POINT", "COMMA",
  "OPEN_SQUARE_BRACE", "CLOSE_SQUARE_BRACE", "WHILE", "ADD_EQ", "THREAD",
  "START", "BITWISE_AND", "BITWISE_OR", "OUT", "IN", "$accept",
  "statement_list", "statement", "$@1", "$@2", "$@3", "$@4",
  "function_input_list", "function_argument_list", "expression", "term",
  "factor", "source", "coordinate", "array_index", "left_hand_side",
  "boolean_expression", "constant", "auto_var_list", "array_size", 0
  };
#endif

#if YYDEBUG
  /* YYRHS -- A `-1'-separated list of the rules' RHS.  */
  const Parser::rhs_number_type
  Parser::yyrhs_[] =
  {
        53,     0,    -1,    -1,    53,    54,    -1,    54,    -1,     3,
      70,    27,    -1,    39,    40,    27,    -1,     7,    27,    -1,
       4,    61,    27,    -1,     4,    27,    -1,    67,    45,    69,
      27,    -1,    67,    29,    29,    27,    -1,    67,    23,    23,
      27,    -1,    67,    20,    61,    27,    -1,    -1,    44,    55,
      16,    68,    17,    18,    53,    19,    -1,    -1,    14,    16,
      68,    17,    18,    53,    19,    15,    56,    18,    53,    19,
      -1,    14,    16,    68,    17,    18,    53,    19,    -1,    -1,
       5,    35,    16,    60,    17,    57,    18,    53,    19,    -1,
      -1,    46,    35,    16,    17,    58,    18,    53,    19,    -1,
      47,    35,    16,    17,    27,    -1,    67,    20,    35,    16,
      59,    17,    27,    -1,    35,    16,    59,    17,    27,    -1,
      -1,    61,    41,    59,    -1,    61,    -1,    -1,    35,    41,
      60,    -1,    35,    -1,    61,    23,    62,    -1,    61,    29,
      62,    -1,    61,    49,    62,    -1,    51,    42,    35,    43,
      -1,    62,    -1,    62,    22,    63,    -1,    62,    21,    63,
      -1,    62,    48,    63,    -1,    63,    -1,    64,    -1,    36,
      16,    61,    17,    -1,    16,    61,    17,    -1,    69,    -1,
      16,    69,    41,    69,    41,    69,    17,    -1,    35,    66,
      -1,    35,    28,    65,    65,    65,    -1,    34,    -1,    37,
      16,    34,    17,    -1,    38,    16,    34,    17,    -1,    34,
      28,    65,    65,    65,    -1,    30,    -1,    29,    30,    -1,
      31,    -1,    29,    31,    -1,    32,    -1,    29,    32,    -1,
      -1,    42,    35,    43,    -1,    50,    42,    69,    43,    -1,
      50,    42,    35,    43,    -1,    35,    66,    -1,    35,    28,
      30,    -1,    35,    28,    31,    -1,    35,    28,    32,    -1,
      34,    -1,    34,    28,    30,    -1,    34,    28,    31,    -1,
      34,    28,    32,    -1,    34,    28,    30,    31,    33,    -1,
      34,    28,    30,    33,    32,    -1,    34,    28,    33,    31,
      32,    -1,    61,     9,    61,    -1,    61,     8,    61,    -1,
      61,    10,    61,    -1,    61,    11,    61,    -1,    61,    12,
      61,    -1,    61,    13,    61,    -1,    24,    -1,    25,    -1,
      26,    -1,    35,    71,    41,    70,    -1,    35,    20,    16,
      69,    41,    69,    41,    69,    17,    41,    70,    -1,    35,
      20,    16,    69,    41,    69,    41,    69,    17,    -1,    35,
      71,    -1,    -1,    42,    69,    43,    -1
  };

  /* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
     YYRHS.  */
  const unsigned short int
  Parser::yyprhs_[] =
  {
         0,     0,     3,     4,     7,     9,    13,    17,    20,    24,
      27,    32,    37,    42,    47,    48,    57,    58,    71,    79,
      80,    90,    91,   100,   106,   114,   120,   121,   125,   127,
     128,   132,   134,   138,   142,   146,   151,   153,   157,   161,
     165,   167,   169,   174,   178,   180,   188,   191,   197,   199,
     204,   209,   215,   217,   220,   222,   225,   227,   230,   231,
     235,   240,   245,   248,   252,   256,   260,   262,   266,   270,
     274,   280,   286,   292,   296,   300,   304,   308,   312,   316,
     318,   320,   322,   327,   339,   349,   352,   353
  };

  /* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
  const unsigned short int
  Parser::yyrline_[] =
  {
         0,   839,   839,   841,   843,   848,   850,   855,   872,   939,
     967,   985,  1014,  1039,  1358,  1358,  1390,  1386,  1425,  1446,
    1445,  1485,  1484,  1515,  1564,  1595,  1655,  1658,  1663,  1669,
    1672,  1677,  1708,  1729,  1751,  1781,  1790,  1798,  1823,  1848,
    1869,  1877,  1887,  1906,  1916,  1946,  2011,  2029,  2040,  2049,
    2057,  2065,  2078,  2083,  2088,  2093,  2098,  2103,  2112,  2116,
    2129,  2135,  2148,  2159,  2168,  2177,  2186,  2193,  2200,  2207,
    2215,  2222,  2229,  2240,  2246,  2252,  2259,  2265,  2271,  2280,
    2293,  2304,  2318,  2334,  2398,  2466,  2486,  2490
  };

  // Print the state stack on the debug stream.
  void
  Parser::yystack_print_ ()
  {
    *yycdebug_ << "Stack now";
    for (state_stack_type::const_iterator i = yystate_stack_.begin ();
	 i != yystate_stack_.end (); ++i)
      *yycdebug_ << ' ' << *i;
    *yycdebug_ << std::endl;
  }

  // Report on the debug stream that the rule \a yyrule is going to be reduced.
  void
  Parser::yy_reduce_print_ (int yyrule)
  {
    unsigned int yylno = yyrline_[yyrule];
    int yynrhs = yyr2_[yyrule];
    /* Print the symbols being reduced, and their result.  */
    *yycdebug_ << "Reducing stack by rule " << yyrule - 1
	       << " (line " << yylno << "):" << std::endl;
    /* The symbols being reduced.  */
    for (int yyi = 0; yyi < yynrhs; yyi++)
      YY_SYMBOL_PRINT ("   $" << yyi + 1 << " =",
		       yyrhs_[yyprhs_[yyrule] + yyi],
		       &(yysemantic_stack_[(yynrhs) - (yyi + 1)]),
		       &(yylocation_stack_[(yynrhs) - (yyi + 1)]));
  }
#endif // YYDEBUG

  /* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
  Parser::token_number_type
  Parser::yytranslate_ (int t)
  {
    static
    const token_number_type
    translate_table[] =
    {
           0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51
    };
    if ((unsigned int) t <= yyuser_token_number_max_)
      return translate_table[t];
    else
      return yyundef_token_;
  }

  const int Parser::yyeof_ = 0;
  const int Parser::yylast_ = 336;
  const int Parser::yynnts_ = 20;
  const int Parser::yyempty_ = -2;
  const int Parser::yyfinal_ = 47;
  const int Parser::yyterror_ = 1;
  const int Parser::yyerrcode_ = 256;
  const int Parser::yyntokens_ = 52;

  const unsigned int Parser::yyuser_token_number_max_ = 306;
  const Parser::token_number_type Parser::yyundef_token_ = 2;


/* Line 1054 of lalr1.cc  */
#line 28 "parser.y"
} // Theia

/* Line 1054 of lalr1.cc  */
#line 3628 "parser.tab.c"


/* Line 1056 of lalr1.cc  */
#line 2496 "parser.y"




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


