
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
#line 815 "parser.tab.c"

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
#line 883 "parser.tab.c"
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
#line 842 "parser.y"
    {
		mGenerateFixedPointArithmetic = true;
	}
    break;

  case 7:

/* Line 678 of lalr1.cc  */
#line 847 "parser.y"
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
#line 864 "parser.y"
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
#line 931 "parser.y"
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
#line 959 "parser.y"
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
#line 977 "parser.y"
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
#line 1006 "parser.y"
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
#line 1031 "parser.y"
    {
		
		//////////////////////////////////////////////////////////////////////////////
		// This means this that the expression will write into the output memory
		// constant index
		//////////////////////////////////////////////////////////////////////////////
	
		if ((yysemantic_stack_[(4) - (1)]).find("OUT") != std::string::npos && (yysemantic_stack_[(4) - (1)]).find("INDEX") == std::string::npos )
		{
			//PopulateInstruction( "R0", "R0 . X X X",$3,I,yylloc);
			
			I.SetCode(EOPERATION_OUT); 
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
				
			PopulateSourceRegisters( IndexRegister + " OFFSET ", (yysemantic_stack_[(4) - (3)]), I, mInstructions );
			
			
			//I.SetImm( 0 );
			I.SetCode( EOPERATION_OUT );
			std::string Source0 = (yysemantic_stack_[(4) - (3)]);
			DCOUT << "!!!!!!!!!!!!!!!!!Source0 '" << Source0 << "'\n";
		/*	if (Source0.find("OFFSET") != std::string::npos)
			{
					Source0.erase(Source0.find("OFFSET"));
					I.SetSrc0Displace(1);
			}
			I.SetSrc1Address(atoi(IndexRegister.c_str()+1));
			I.SetSrc0Address(atoi(Source0.c_str()+1));*/
			
		/*	if (Destination.find(".") != std::string::npos)
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
			I.SetDestinationAddress( atoi(Destination.c_str()+1) );*/
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
#line 1343 "parser.y"
    { /*Middle rule here, get me the loop address*/ ;gWhileLoopAddress = (mInstructions.size());}
    break;

  case 15:

/* Line 678 of lalr1.cc  */
#line 1344 "parser.y"
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
#line 1363 "parser.y"
    { 
	 
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
	  ////std::cout << "else\n";
	  
	}
    break;

  case 17:

/* Line 678 of lalr1.cc  */
#line 1381 "parser.y"
    {
	   
	   mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size());
	   gBranchStack.pop_back();
	   //Now push the JMP
	   
		////std::cout << "END elseif\n";
	}
    break;

  case 18:

/* Line 678 of lalr1.cc  */
#line 1392 "parser.y"
    {
		mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size());
		//mInstructions[gBranchStack.back()].mSourceLine = GetCurrentLineNumber(yylloc);
		
		gBranchStack.pop_back();
		////std::cout << "if closing at " << mInstructions.size() << "\n";
		
	}
    break;

  case 19:

/* Line 678 of lalr1.cc  */
#line 1402 "parser.y"
    {
	  ////std::cout << "Function declaration for " << $2 << " at " << mInstructions.size() << "\n" ;
	  mSymbolMap[ (yysemantic_stack_[(5) - (2)]) ] = mInstructions.size();
	}
    break;

  case 20:

/* Line 678 of lalr1.cc  */
#line 1406 "parser.y"
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
#line 1431 "parser.y"
    {
		gThreadMap[ (yysemantic_stack_[(4) - (2)]) ] = mInstructions.size();
		gThreadScope = true;
	}
    break;

  case 22:

/* Line 678 of lalr1.cc  */
#line 1436 "parser.y"
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
#line 1454 "parser.y"
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
#line 1495 "parser.y"
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
#line 1519 "parser.y"
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
		//Now do the branch
		if (mSymbolMap.find((yysemantic_stack_[(5) - (1)])) == mSymbolMap.end())
		{
		//	////std::cout << "Error in line : " << $1 <<" undelcared IDENTIFIER\n";
			I.SetDestinationSymbol( "@"+(yysemantic_stack_[(5) - (1)]) );
		//	exit(1);
		} else {
			I.SetDestinationAddress( mSymbolMap[ (yysemantic_stack_[(5) - (1)]) ] );
		}
		
		
		mInstructions.push_back( I );
		I.Clear();
		
	}
    break;

  case 27:

/* Line 678 of lalr1.cc  */
#line 1578 "parser.y"
    {
						AddFunctionInputList( (yysemantic_stack_[(3) - (1)]), mInstructions,yylloc );
					  }
    break;

  case 28:

/* Line 678 of lalr1.cc  */
#line 1583 "parser.y"
    {
						AddFunctionInputList( (yysemantic_stack_[(1) - (1)]),mInstructions, yylloc );
					  }
    break;

  case 30:

/* Line 678 of lalr1.cc  */
#line 1592 "parser.y"
    {
							AddFunctionParameter( (yysemantic_stack_[(3) - (1)]), yylloc );
						}
    break;

  case 31:

/* Line 678 of lalr1.cc  */
#line 1597 "parser.y"
    {
							AddFunctionParameter( (yysemantic_stack_[(1) - (1)]), yylloc );
						}
    break;

  case 32:

/* Line 678 of lalr1.cc  */
#line 1618 "parser.y"
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
#line 1639 "parser.y"
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
#line 1661 "parser.y"
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
#line 1682 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(1) - (1)]);
		}
    break;

  case 36:

/* Line 678 of lalr1.cc  */
#line 1690 "parser.y"
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

  case 37:

/* Line 678 of lalr1.cc  */
#line 1715 "parser.y"
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

  case 38:

/* Line 678 of lalr1.cc  */
#line 1740 "parser.y"
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

  case 39:

/* Line 678 of lalr1.cc  */
#line 1761 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(1) - (1)]);
		}
    break;

  case 40:

/* Line 678 of lalr1.cc  */
#line 1769 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(1) - (1)]);
		}
    break;

  case 41:

/* Line 678 of lalr1.cc  */
#line 1774 "parser.y"
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

  case 42:

/* Line 678 of lalr1.cc  */
#line 1793 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(3) - (2)]);
		}
    break;

  case 43:

/* Line 678 of lalr1.cc  */
#line 1803 "parser.y"
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

  case 44:

/* Line 678 of lalr1.cc  */
#line 1833 "parser.y"
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

  case 45:

/* Line 678 of lalr1.cc  */
#line 1898 "parser.y"
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

  case 46:

/* Line 678 of lalr1.cc  */
#line 1916 "parser.y"
    {
	
		std::string X = (yysemantic_stack_[(5) - (3)]),Y = (yysemantic_stack_[(5) - (4)]),Z = (yysemantic_stack_[(5) - (5)]);
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(5) - (1)]))) != "NULL")
			(yyval) = (Register + " . " + " " + X + " " + Y  + " " + Z + " OFFSET ");
		else
			(yyval) = (GetRegisterFromAutoVar( (yysemantic_stack_[(5) - (1)]), yylloc) + " . " + " " + X + " " + Y  + " " + Z + " OFFSET ");
	}
    break;

  case 47:

/* Line 678 of lalr1.cc  */
#line 1927 "parser.y"
    {
		
		std::string R = (yysemantic_stack_[(1) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R;
		
	}
    break;

  case 48:

/* Line 678 of lalr1.cc  */
#line 1936 "parser.y"
    {
	
		std::string R = (yysemantic_stack_[(4) - (1)]);
		R.erase(0,1);
		(yyval) = "<<R" + R;
	}
    break;

  case 49:

/* Line 678 of lalr1.cc  */
#line 1944 "parser.y"
    {
	
		std::string R = (yysemantic_stack_[(4) - (1)]);
		R.erase(0,1);
		(yyval) = ">>R" + R;
	}
    break;

  case 50:

/* Line 678 of lalr1.cc  */
#line 1952 "parser.y"
    {
		std::string R = (yysemantic_stack_[(5) - (1)]);
		std::string X = (yysemantic_stack_[(5) - (3)]),Y = (yysemantic_stack_[(5) - (4)]),Z = (yysemantic_stack_[(5) - (5)]);
		R.erase(0,1);
		(yyval) = "R" + R + " . " + " " + X + " " + Y  + " " + Z;
	
	}
    break;

  case 51:

/* Line 678 of lalr1.cc  */
#line 1965 "parser.y"
    {
		(yyval) = "X";
	}
    break;

  case 52:

/* Line 678 of lalr1.cc  */
#line 1970 "parser.y"
    {
		(yyval) = "-X";
	}
    break;

  case 53:

/* Line 678 of lalr1.cc  */
#line 1975 "parser.y"
    {
		(yyval) = "Y";
	}
    break;

  case 54:

/* Line 678 of lalr1.cc  */
#line 1980 "parser.y"
    {
		(yyval) = "-Y";
	}
    break;

  case 55:

/* Line 678 of lalr1.cc  */
#line 1985 "parser.y"
    {
		(yyval) = "Z";
	}
    break;

  case 56:

/* Line 678 of lalr1.cc  */
#line 1990 "parser.y"
    {
		(yyval) = "-Z";
	}
    break;

  case 57:

/* Line 678 of lalr1.cc  */
#line 1998 "parser.y"
    {
		(yyval) = "NULL";
	}
    break;

  case 58:

/* Line 678 of lalr1.cc  */
#line 2003 "parser.y"
    {
		/*std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($2)) != "NULL")
			$$ = Register;
		else*/
		//Indexes into arrays can only be auto variables!
		(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(3) - (2)]), yylloc );
	}
    break;

  case 59:

/* Line 678 of lalr1.cc  */
#line 2016 "parser.y"
    {
		
		(yyval) = "OUT " + (yysemantic_stack_[(4) - (3)]);
	}
    break;

  case 60:

/* Line 678 of lalr1.cc  */
#line 2022 "parser.y"
    {
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(4) - (3)]))) == "NULL")
			Register = GetRegisterFromAutoVar( (yysemantic_stack_[(4) - (3)]), yylloc );
		
		(yyval) = "OUT INDEX" + Register;
	}
    break;

  case 61:

/* Line 678 of lalr1.cc  */
#line 2031 "parser.y"
    {
		
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(2) - (1)]))) != "NULL")
			(yyval) = Register + ".xyz";
		else
			(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(2) - (1)]), yylloc ) + ".xyz" + " OFFSET " + (((yysemantic_stack_[(2) - (2)]) != "NULL")?" INDEX"+(yysemantic_stack_[(2) - (2)]):"");
		
	}
    break;

  case 62:

/* Line 678 of lalr1.cc  */
#line 2042 "parser.y"
    {
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(3) - (1)]))) != "NULL")
			(yyval) = Register + ".x";
		else
		(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(3) - (1)]), yylloc ) + ".x" + " OFFSET ";
	}
    break;

  case 63:

/* Line 678 of lalr1.cc  */
#line 2051 "parser.y"
    {
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(3) - (1)]))) != "NULL")
			(yyval) = Register + ".y";
		else
			(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(3) - (1)]), yylloc ) + ".y" + " OFFSET ";
	}
    break;

  case 64:

/* Line 678 of lalr1.cc  */
#line 2060 "parser.y"
    {
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter((yysemantic_stack_[(3) - (1)]))) != "NULL")
			(yyval) = Register + ".z";
		else
			(yyval) = GetRegisterFromAutoVar( (yysemantic_stack_[(3) - (1)]), yylloc ) + ".z" + " OFFSET ";
	}
    break;

  case 65:

/* Line 678 of lalr1.cc  */
#line 2069 "parser.y"
    {
		std::string R = (yysemantic_stack_[(1) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".xyz";
	}
    break;

  case 66:

/* Line 678 of lalr1.cc  */
#line 2076 "parser.y"
    {
		std::string R = (yysemantic_stack_[(3) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".x";
	}
    break;

  case 67:

/* Line 678 of lalr1.cc  */
#line 2083 "parser.y"
    {
		std::string R = (yysemantic_stack_[(3) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".y";
	}
    break;

  case 68:

/* Line 678 of lalr1.cc  */
#line 2090 "parser.y"
    {
		
		std::string R = (yysemantic_stack_[(3) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".z";
	}
    break;

  case 69:

/* Line 678 of lalr1.cc  */
#line 2098 "parser.y"
    {
		std::string R = (yysemantic_stack_[(5) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".xy";
	}
    break;

  case 70:

/* Line 678 of lalr1.cc  */
#line 2105 "parser.y"
    {
		std::string R = (yysemantic_stack_[(5) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".xz";
	}
    break;

  case 71:

/* Line 678 of lalr1.cc  */
#line 2112 "parser.y"
    {
		std::string R = (yysemantic_stack_[(5) - (1)]);
		R.erase(0,1);
		(yyval) = "R" + R + ".yz";
	}
    break;

  case 72:

/* Line 678 of lalr1.cc  */
#line 2123 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_ZERO, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 73:

/* Line 678 of lalr1.cc  */
#line 2129 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_NOT_ZERO, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 74:

/* Line 678 of lalr1.cc  */
#line 2135 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_ZERO_OR_SIGN, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 75:

/* Line 678 of lalr1.cc  */
#line 2142 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_ZERO_OR_NOT_SIGN, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
				
				}
    break;

  case 76:

/* Line 678 of lalr1.cc  */
#line 2148 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_NOT_SIGN, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 77:

/* Line 678 of lalr1.cc  */
#line 2154 "parser.y"
    {
					PopulateBoolean(EBRANCH_IF_SIGN, (yysemantic_stack_[(3) - (1)]), (yysemantic_stack_[(3) - (3)]), I, mInstructions, yylloc );
					
				}
    break;

  case 78:

/* Line 678 of lalr1.cc  */
#line 2163 "parser.y"
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

  case 79:

/* Line 678 of lalr1.cc  */
#line 2176 "parser.y"
    {
			std::string StringHex = (yysemantic_stack_[(1) - (1)]);
			// Get rid of the 0x
			StringHex.erase(StringHex.begin(),StringHex.begin()+2);
			std::stringstream ss;
			ss << std::hex << StringHex;
			
			(yyval) = ss.str();
		}
    break;

  case 80:

/* Line 678 of lalr1.cc  */
#line 2187 "parser.y"
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

  case 81:

/* Line 678 of lalr1.cc  */
#line 2201 "parser.y"
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

  case 82:

/* Line 678 of lalr1.cc  */
#line 2217 "parser.y"
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

  case 83:

/* Line 678 of lalr1.cc  */
#line 2281 "parser.y"
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

  case 84:

/* Line 678 of lalr1.cc  */
#line 2349 "parser.y"
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

  case 85:

/* Line 678 of lalr1.cc  */
#line 2368 "parser.y"
    {
		 (yyval) = "1";
		 }
    break;

  case 86:

/* Line 678 of lalr1.cc  */
#line 2373 "parser.y"
    {
		
		 (yyval) = (yysemantic_stack_[(3) - (2)]);
		 }
    break;



/* Line 678 of lalr1.cc  */
#line 2972 "parser.tab.c"
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
  const signed char Parser::yypact_ninf_ = -121;
  const short int
  Parser::yypact_[] =
  {
       216,   -26,   243,   -19,   -14,     3,    19,   -11,    27,  -121,
      20,    33,    29,     7,  -121,    50,    68,    45,   248,  -121,
    -121,  -121,  -121,    48,   -22,    59,    71,    75,    54,     8,
    -121,  -121,  -121,   108,  -121,   248,   184,   248,   153,    81,
    -121,   104,   117,   122,   126,   134,  -121,  -121,   271,   121,
     123,   173,   135,   173,   114,  -121,    15,   115,   195,   195,
    -121,   248,   127,   133,   248,  -121,   248,   248,   248,   248,
     248,   138,    14,   157,   103,  -121,  -121,   148,   164,   100,
    -121,  -121,  -121,   145,  -121,   248,   174,   175,   151,   158,
      24,    57,   182,   183,   185,   173,   179,   -26,  -121,   173,
     205,  -121,  -121,  -121,   195,   195,    16,   211,   212,     8,
       8,     8,  -121,  -121,  -121,   190,   215,   248,   248,   248,
     248,   248,   248,   224,   214,   220,   221,   217,   248,  -121,
     231,  -121,   227,  -121,  -121,   248,  -121,  -121,  -121,  -121,
     230,  -121,  -121,   234,  -121,  -121,  -121,   195,   195,  -121,
    -121,  -121,   138,  -121,    86,    86,    86,    86,    86,    86,
     216,  -121,  -121,  -121,  -121,  -121,   238,   239,  -121,   241,
     173,   173,  -121,  -121,  -121,   247,    55,   216,   216,   249,
     250,   244,   216,   273,    93,   143,  -121,   173,  -121,   161,
    -121,  -121,  -121,   272,  -121,   274,   252,   216,   -26,   199,
    -121,  -121
  };

  /* YYDEFACT[S] -- default rule to reduce with in state S when YYTABLE
     doesn't specify something else to do.  Zero means the default is an
     error.  */
  const unsigned char
  Parser::yydefact_[] =
  {
         2,     0,     0,     0,     0,     0,    65,    57,     0,    14,
       0,     0,     0,     0,     4,     0,    85,     0,     0,    78,
      79,    80,     9,    47,    57,     0,     0,     0,     0,    35,
      39,    40,    43,     0,     7,     0,     0,    26,     0,     0,
      61,     0,     0,     0,     0,     0,     1,     3,     0,     0,
       0,     0,     0,     0,    84,     5,     0,    43,     0,     0,
      45,     0,     0,     0,     0,     8,     0,     0,     0,     0,
       0,    29,     0,     0,    66,    67,    68,     0,     0,    28,
      62,    63,    64,     0,     6,     0,     0,     0,     0,     0,
      57,     0,     0,     0,     0,     0,     0,     0,    42,     0,
       0,    51,    53,    55,     0,     0,     0,     0,     0,    32,
      33,    34,    37,    36,    38,    31,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    26,    58,
       0,    21,     0,    60,    59,    26,    13,    12,    11,    10,
       0,    86,    81,     0,    52,    54,    56,     0,     0,    41,
      48,    49,    29,    19,    73,    72,    74,    75,    76,    77,
       2,    69,    70,    71,    25,    27,     0,     0,    23,     0,
       0,     0,    50,    46,    30,     0,     0,     2,     2,     0,
       0,     0,     2,    18,     0,     0,    24,     0,    44,     0,
      16,    15,    22,     0,    20,     0,    83,     2,     0,     0,
      82,    17
  };

  /* YYPGOTO[NTERM-NUM].  */
  const short int
  Parser::yypgoto_[] =
  {
      -121,   -52,   -13,  -121,  -121,  -121,  -121,  -120,   142,     0,
      47,   171,  -121,   -55,   283,  -121,   213,   -17,   -94,  -121
  };

  /* YYDEFGOTO[NTERM-NUM].  */
  const short int
  Parser::yydefgoto_[] =
  {
        -1,    13,    14,    42,   195,   175,   167,    78,   116,    79,
      29,    30,    31,   104,    60,    15,    73,    32,    17,    54
  };

  /* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
     positive, shift that token.  If negative, reduce the rule which
     number is the opposite.  If zero, do what YYDEFACT says.  */
  const signed char Parser::yytable_ninf_ = -1;
  const unsigned char
  Parser::yytable_[] =
  {
        47,    57,    28,   142,   105,    37,    59,    46,   165,    16,
       1,     2,     3,    34,     4,   169,    33,    38,    56,    35,
      39,     5,   117,   118,   119,   120,   121,   122,    89,    68,
      69,    39,    98,   149,    94,    72,    96,    64,    64,    64,
     135,     6,     7,    66,    66,    66,     8,    36,    91,   147,
     148,     9,    59,    10,    11,    43,    70,    12,     1,     2,
       3,   106,     4,    67,    67,    67,    39,    41,    44,     5,
      48,    45,    55,    49,   183,    61,    58,    64,   140,    50,
      64,    65,   143,    66,   136,    72,    66,    62,    52,     6,
       7,    63,   172,   173,     8,    51,     1,     2,     3,     9,
       4,    10,    11,    67,   200,    12,    67,     5,   176,    64,
      53,   109,   191,   110,   111,    66,    83,   154,   155,   156,
     157,   158,   159,    64,    71,   184,   185,     6,     7,    66,
     189,    84,     8,    85,   124,    67,   125,     9,    86,    10,
      11,   128,    87,    12,    92,   199,     1,     2,     3,    67,
       4,    95,    93,   180,   181,    97,    99,     5,    19,    20,
      21,   107,   192,    47,     1,     2,     3,   108,     4,    88,
     193,    47,    47,   115,   123,     5,    47,     6,     7,   126,
     194,   127,     8,    80,    81,    82,    47,     9,   129,    10,
      11,   131,   132,    12,   133,     6,     7,    19,    20,    21,
       8,   134,     1,     2,     3,     9,     4,    10,    11,   137,
     138,    12,   139,     5,    74,    75,    76,    77,   201,     1,
       2,     3,   141,     4,   100,   101,   102,   103,   150,   151,
       5,   152,   153,     6,     7,   144,   145,   146,     8,   112,
     113,   114,   160,     9,   164,    10,    11,   161,   166,    12,
       6,     7,   162,   163,   168,     8,   177,   178,   179,    18,
       9,   188,    10,    11,    18,   182,    12,    19,    20,    21,
      22,   170,    19,    20,    21,   171,   186,    23,    24,    25,
      26,    27,    23,    24,    25,    26,    27,    18,   190,   196,
      40,   187,   197,   198,   174,    19,    20,    21,   130,     0,
       0,     0,     0,     0,     0,    23,    90,    25,    26,    27
  };

  /* YYCHECK.  */
  const short int
  Parser::yycheck_[] =
  {
        13,    18,     2,    97,    59,    16,    28,     0,   128,    35,
       3,     4,     5,    27,     7,   135,    35,    28,    18,    16,
      42,    14,     8,     9,    10,    11,    12,    13,    45,    21,
      22,    42,    17,    17,    51,    35,    53,    23,    23,    23,
      16,    34,    35,    29,    29,    29,    39,    28,    48,   104,
     105,    44,    28,    46,    47,    35,    48,    50,     3,     4,
       5,    61,     7,    49,    49,    49,    42,    40,    35,    14,
      20,    42,    27,    23,    19,    16,    28,    23,    95,    29,
      23,    27,    99,    29,    27,    85,    29,    16,    20,    34,
      35,    16,   147,   148,    39,    45,     3,     4,     5,    44,
       7,    46,    47,    49,   198,    50,    49,    14,   160,    23,
      42,    64,    19,    66,    67,    29,    35,   117,   118,   119,
     120,   121,   122,    23,    16,   177,   178,    34,    35,    29,
     182,    27,    39,    16,    31,    49,    33,    44,    16,    46,
      47,    41,    16,    50,    23,   197,     3,     4,     5,    49,
       7,    16,    29,   170,   171,    41,    41,    14,    24,    25,
      26,    34,    19,   176,     3,     4,     5,    34,     7,    35,
     187,   184,   185,    35,    17,    14,   189,    34,    35,    31,
      19,    17,    39,    30,    31,    32,   199,    44,    43,    46,
      47,    17,    17,    50,    43,    34,    35,    24,    25,    26,
      39,    43,     3,     4,     5,    44,     7,    46,    47,    27,
      27,    50,    27,    14,    30,    31,    32,    33,    19,     3,
       4,     5,    43,     7,    29,    30,    31,    32,    17,    17,
      14,    41,    17,    34,    35,    30,    31,    32,    39,    68,
      69,    70,    18,    44,    27,    46,    47,    33,    17,    50,
      34,    35,    32,    32,    27,    39,    18,    18,    17,    16,
      44,    17,    46,    47,    16,    18,    50,    24,    25,    26,
      27,    41,    24,    25,    26,    41,    27,    34,    35,    36,
      37,    38,    34,    35,    36,    37,    38,    16,    15,    17,
       7,    41,    18,    41,   152,    24,    25,    26,    85,    -1,
      -1,    -1,    -1,    -1,    -1,    34,    35,    36,    37,    38
  };

  /* STOS_[STATE-NUM] -- The (internal number of the) accessing
     symbol of state STATE-NUM.  */
  const unsigned char
  Parser::yystos_[] =
  {
         0,     3,     4,     5,     7,    14,    34,    35,    39,    44,
      46,    47,    50,    52,    53,    66,    35,    69,    16,    24,
      25,    26,    27,    34,    35,    36,    37,    38,    60,    61,
      62,    63,    68,    35,    27,    16,    28,    16,    28,    42,
      65,    40,    54,    35,    35,    42,     0,    53,    20,    23,
      29,    45,    20,    42,    70,    27,    60,    68,    28,    28,
      65,    16,    16,    16,    23,    27,    29,    49,    21,    22,
      48,    16,    60,    67,    30,    31,    32,    33,    58,    60,
      30,    31,    32,    35,    27,    16,    16,    16,    35,    68,
      35,    60,    23,    29,    68,    16,    68,    41,    17,    41,
      29,    30,    31,    32,    64,    64,    60,    34,    34,    61,
      61,    61,    62,    62,    62,    35,    59,     8,     9,    10,
      11,    12,    13,    17,    31,    33,    31,    17,    41,    43,
      67,    17,    17,    43,    43,    16,    27,    27,    27,    27,
      68,    43,    69,    68,    30,    31,    32,    64,    64,    17,
      17,    17,    41,    17,    60,    60,    60,    60,    60,    60,
      18,    33,    32,    32,    27,    58,    17,    57,    27,    58,
      41,    41,    64,    64,    59,    56,    52,    18,    18,    17,
      68,    68,    18,    19,    52,    52,    27,    41,    17,    52,
      15,    19,    19,    68,    19,    55,    17,    18,    41,    52,
      69,    19
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
     305
  };
#endif

  /* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
  const unsigned char
  Parser::yyr1_[] =
  {
         0,    51,    52,    52,    52,    53,    53,    53,    53,    53,
      53,    53,    53,    53,    54,    53,    55,    53,    53,    56,
      53,    57,    53,    53,    53,    53,    58,    58,    58,    59,
      59,    59,    60,    60,    60,    60,    61,    61,    61,    61,
      62,    62,    62,    63,    63,    63,    63,    63,    63,    63,
      63,    64,    64,    64,    64,    64,    64,    65,    65,    66,
      66,    66,    66,    66,    66,    66,    66,    66,    66,    66,
      66,    66,    67,    67,    67,    67,    67,    67,    68,    68,
      68,    69,    69,    69,    69,    70,    70
  };

  /* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
  const unsigned char
  Parser::yyr2_[] =
  {
         0,     2,     0,     2,     1,     3,     3,     2,     3,     2,
       4,     4,     4,     4,     0,     8,     0,    12,     7,     0,
       9,     0,     8,     5,     7,     5,     0,     3,     1,     0,
       3,     1,     3,     3,     3,     1,     3,     3,     3,     1,
       1,     4,     3,     1,     7,     2,     5,     1,     4,     4,
       5,     1,     2,     1,     2,     1,     2,     0,     3,     4,
       4,     2,     3,     3,     3,     1,     3,     3,     3,     5,
       5,     5,     3,     3,     3,     3,     3,     3,     1,     1,
       1,     4,    11,     9,     2,     0,     3
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
  "START", "BITWISE_AND", "BITWISE_OR", "OUT", "$accept", "statement_list",
  "statement", "$@1", "$@2", "$@3", "$@4", "function_input_list",
  "function_argument_list", "expression", "term", "factor", "source",
  "coordinate", "array_index", "left_hand_side", "boolean_expression",
  "constant", "auto_var_list", "array_size", 0
  };
#endif

#if YYDEBUG
  /* YYRHS -- A `-1'-separated list of the rules' RHS.  */
  const Parser::rhs_number_type
  Parser::yyrhs_[] =
  {
        52,     0,    -1,    -1,    52,    53,    -1,    53,    -1,     3,
      69,    27,    -1,    39,    40,    27,    -1,     7,    27,    -1,
       4,    60,    27,    -1,     4,    27,    -1,    66,    45,    68,
      27,    -1,    66,    29,    29,    27,    -1,    66,    23,    23,
      27,    -1,    66,    20,    60,    27,    -1,    -1,    44,    54,
      16,    67,    17,    18,    52,    19,    -1,    -1,    14,    16,
      67,    17,    18,    52,    19,    15,    55,    18,    52,    19,
      -1,    14,    16,    67,    17,    18,    52,    19,    -1,    -1,
       5,    35,    16,    59,    17,    56,    18,    52,    19,    -1,
      -1,    46,    35,    16,    17,    57,    18,    52,    19,    -1,
      47,    35,    16,    17,    27,    -1,    66,    20,    35,    16,
      58,    17,    27,    -1,    35,    16,    58,    17,    27,    -1,
      -1,    60,    41,    58,    -1,    60,    -1,    -1,    35,    41,
      59,    -1,    35,    -1,    60,    23,    61,    -1,    60,    29,
      61,    -1,    60,    49,    61,    -1,    61,    -1,    61,    22,
      62,    -1,    61,    21,    62,    -1,    61,    48,    62,    -1,
      62,    -1,    63,    -1,    36,    16,    60,    17,    -1,    16,
      60,    17,    -1,    68,    -1,    16,    68,    41,    68,    41,
      68,    17,    -1,    35,    65,    -1,    35,    28,    64,    64,
      64,    -1,    34,    -1,    37,    16,    34,    17,    -1,    38,
      16,    34,    17,    -1,    34,    28,    64,    64,    64,    -1,
      30,    -1,    29,    30,    -1,    31,    -1,    29,    31,    -1,
      32,    -1,    29,    32,    -1,    -1,    42,    35,    43,    -1,
      50,    42,    68,    43,    -1,    50,    42,    35,    43,    -1,
      35,    65,    -1,    35,    28,    30,    -1,    35,    28,    31,
      -1,    35,    28,    32,    -1,    34,    -1,    34,    28,    30,
      -1,    34,    28,    31,    -1,    34,    28,    32,    -1,    34,
      28,    30,    31,    33,    -1,    34,    28,    30,    33,    32,
      -1,    34,    28,    33,    31,    32,    -1,    60,     9,    60,
      -1,    60,     8,    60,    -1,    60,    10,    60,    -1,    60,
      11,    60,    -1,    60,    12,    60,    -1,    60,    13,    60,
      -1,    24,    -1,    25,    -1,    26,    -1,    35,    70,    41,
      69,    -1,    35,    20,    16,    68,    41,    68,    41,    68,
      17,    41,    69,    -1,    35,    20,    16,    68,    41,    68,
      41,    68,    17,    -1,    35,    70,    -1,    -1,    42,    68,
      43,    -1
  };

  /* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
     YYRHS.  */
  const unsigned short int
  Parser::yyprhs_[] =
  {
         0,     0,     3,     4,     7,     9,    13,    17,    20,    24,
      27,    32,    37,    42,    47,    48,    57,    58,    71,    79,
      80,    90,    91,   100,   106,   114,   120,   121,   125,   127,
     128,   132,   134,   138,   142,   146,   148,   152,   156,   160,
     162,   164,   169,   173,   175,   183,   186,   192,   194,   199,
     204,   210,   212,   215,   217,   220,   222,   225,   226,   230,
     235,   240,   243,   247,   251,   255,   257,   261,   265,   269,
     275,   281,   287,   291,   295,   299,   303,   307,   311,   313,
     315,   317,   322,   334,   344,   347,   348
  };

  /* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
  const unsigned short int
  Parser::yyrline_[] =
  {
         0,   830,   830,   832,   834,   839,   841,   846,   863,   930,
     958,   976,  1005,  1030,  1343,  1343,  1363,  1359,  1391,  1402,
    1401,  1431,  1430,  1453,  1494,  1518,  1574,  1577,  1582,  1588,
    1591,  1596,  1617,  1638,  1660,  1681,  1689,  1714,  1739,  1760,
    1768,  1773,  1792,  1802,  1832,  1897,  1915,  1926,  1935,  1943,
    1951,  1964,  1969,  1974,  1979,  1984,  1989,  1998,  2002,  2015,
    2021,  2030,  2041,  2050,  2059,  2068,  2075,  2082,  2089,  2097,
    2104,  2111,  2122,  2128,  2134,  2141,  2147,  2153,  2162,  2175,
    2186,  2200,  2216,  2280,  2348,  2368,  2372
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
      45,    46,    47,    48,    49,    50
    };
    if ((unsigned int) t <= yyuser_token_number_max_)
      return translate_table[t];
    else
      return yyundef_token_;
  }

  const int Parser::yyeof_ = 0;
  const int Parser::yylast_ = 309;
  const int Parser::yynnts_ = 20;
  const int Parser::yyempty_ = -2;
  const int Parser::yyfinal_ = 46;
  const int Parser::yyterror_ = 1;
  const int Parser::yyerrcode_ = 256;
  const int Parser::yyntokens_ = 51;

  const unsigned int Parser::yyuser_token_number_max_ = 305;
  const Parser::token_number_type Parser::yyundef_token_ = 2;


/* Line 1054 of lalr1.cc  */
#line 28 "parser.y"
} // Theia

/* Line 1054 of lalr1.cc  */
#line 3588 "parser.tab.c"


/* Line 1056 of lalr1.cc  */
#line 2378 "parser.y"




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


