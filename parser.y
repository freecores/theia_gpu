
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
#define FUNCTION_PARAM_START_REGION 2
#define FUNCTION_PARAM_LAST_REGION  7
	std::map<std::string, unsigned int> gFunctionParameters;
	std::map<std::string, unsigned int> gAutoVarMap;
#define AUTOVAR_START_REGION 8
unsigned int gAutoVarIndex = AUTOVAR_START_REGION;
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
	//std::cout << "Adding " << aVar << "\n";
	if (gFunctionParameterIndex+1 > FUNCTION_PARAM_LAST_REGION)
	{
			std::ostringstream ret;
			ret << "Cannot allocate moere parameters '" << aVar << "' at line " << yylloc << " \n";
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
	//std::cout << "Looking for " << aVar << "\n";
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
unsigned int GetAutoVarIndex()
{
	//std::cout << gAutoVarIndex+1 << "\n";
	return gAutoVarIndex++;
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
unsigned int gTempRegisterIndex = 32;
unsigned int GetFreeTempRegister()
{
	return gTempRegisterIndex++;
}
//----------------------------------------------------------			
void ResetTempRegisterIndex( void )
{
	gTempRegisterIndex = 32;
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
	std::string Reg,X,Y,Z;
	std::stringstream ss( aSwizzle );
	ss >> Reg >> X >> Y >> Z;
	//std::cout << X << " " << Y << " " << Z << "\n";
	
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
		I.mComment = "store return address";
		I.SetImm( aInstructions.size()+4 );
		I.SetWriteChannel(ECHANNEL_XYZ);
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
void SetDestinationFromRegister( std::string aDestination, Instruction & aInst )
{
		//Look for displament addressing mode
				
		if (aDestination.find("&&") != std::string::npos)
		{
			aDestination.erase(aDestination.find("&"));
			//std::cout << "^_^ left_hand_side " << Destination << "\n";
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
void PopulateSourceRegisters( std::string a1, std::string a2, Instruction & I )
{
			if ( a1.find("R") == std::string::npos )
			{
				unsigned int ImmediateValue;
				std::string StringHex = a1;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				I.SetImm( ImmediateValue );
			} else {
			
				//Look for displament addressing mode
			if (a1.find("&&") != std::string::npos)
			{
				a1.erase(a1.find("&"));
				//std::cout << "^_^ a1" << a1 << "\n";
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
				if (a2.find("&&") != std::string::npos)
				{
					a2.erase(a2.find("&"));
					//std::cout << "^_^ a2 " << a2 << "\n";
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
	std::string Reg = GetRegisterFromAutoVar( aVar, yylloc );
	//Copy the value into function parameter register
	unsigned FunctionParamReg = GetNextFunctionParamRegister();
	
	I.SetCode( EOPERATION_ADD );
	I.mComment = "copy the value into function parameter register";
	I.SetWriteChannel(ECHANNEL_XYZ);
	I.SetDestZero( true ); //When Imm != 0, DestZero means DST = DSTINDEX + offset
	I.SetDestinationAddress( FunctionParamReg );
	I.SetSrc1Address(atoi(Reg.c_str()+1));
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
	// Prototype for the yylex function
	static int yylex(Theia::Parser::semantic_type * yylval,
	                 Theia::Parser::location_type * yylloc,
	                 Theia::Scanner &scanner);
}

%token AUTO RETURN FUNCTION JMP EXIT EQUAL NOT_EQUAL GREATER_THAN LESS_THAN LESS_OR_EQUAL_THAN GREATER_OR_EQUAL_THAN IF ELSE OPEN_ROUND_BRACE CLOSE_ROUND_BRACE OPEN_BRACE CLOSE_BRACE ASSIGN DIV MUL ADD DECCONST HEXCONST BINCONST EOS DOT MINUS TK_X TK_Y TK_Z TK_N REG
%token IDENTIFIER SQRT SCALE UNSCALE USING FIXED_POINT COMMA OPEN_SQUARE_BRACE CLOSE_SQUARE_BRACE 
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
		I.SetEofFlag(true);
		I.mComment = "Set the Exit bit";
		I.SetCode( EOPERATION_ADD );
		mInstructions.push_back(I);
		I.Clear();
	}
	|
	RETURN expression EOS
	{
	
		
		
		mInstructions[ mInstructions.size() - gInsertedInstructions].mSourceLine = GetCurrentLineNumber(yylloc);
	    gInsertedInstructions = 0;	
		mInstructions.back().mComment ="Assigning return value";
		mInstructions.back().SetDestinationAddress( RETURN_VALUE_REGISTER );
		ResetTempRegisterIndex();
		
		
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
	| RETURN constant EOS
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
	
		//Set the return value
		unsigned int ImmediateValue;
		std::string StringHex = $3;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		I.SetImm( ImmediateValue );
		I.SetDestZero(true);
		I.mComment = "Set the return value";
		I.SetWriteChannel(ECHANNEL_XYZ);
		I.SetCode( EOPERATION_ADD );
		I.SetDestinationAddress( RETURN_VALUE_REGISTER );
		mInstructions.push_back(I);
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
	 left_hand_side ASSIGN constant EOS
	 {
		
		std::string Destination = $1;
		
		//Look for displament addressing mode
		if (Destination.find("&&") != std::string::npos)
		{
			Destination.erase(Destination.find("&"));
			//std::cout << "^_^ " << Destination << "\n";
			I.SetDestZero( true );
			I.SetSrc1Displace( false );
			I.SetSrc0Displace( true );
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
		
		I.SetDestinationAddress( atoi($1.c_str()+1) );
		unsigned int ImmediateValue;
		
		std::string StringHex = $3;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		I.SetImm( ImmediateValue );
		I.SetDestZero( true );
		I.SetCode( EOPERATION_ADD );
		
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		
		mInstructions.push_back(I);
		I.Clear();
		ResetTempRegisterIndex();
     }
	 |
	 left_hand_side ASSIGN OPEN_ROUND_BRACE constant COMMA constant COMMA constant CLOSE_ROUND_BRACE EOS
	 {
		std::string Destination = $1;
		
		//Look for displament addressing mode
		bool HasOffset = false;
		if (Destination.find("&&") != std::string::npos)
		{
			Destination.erase(Destination.find("&"));
			HasOffset = true;
		}
		
		I.ClearWriteChannel();
		unsigned int ImmediateValue;
		{
		I.SetDestinationAddress( atoi($1.c_str()+1) );
		I.SetWriteChannel(ECHANNEL_X);
		std::string StringHex = $4;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		I.SetImm( ImmediateValue );
		I.SetDestZero( true );
		if (HasOffset)
		{		
			I.SetSrc1Displace( false );
			I.SetSrc0Displace( true );
		}
		I.SetCode( EOPERATION_ADD );
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		mInstructions.push_back(I);
		I.Clear();
		}
		{
		I.SetDestinationAddress( atoi($1.c_str()+1) );
		I.SetWriteChannel(ECHANNEL_Y);
		std::string StringHex = $6;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		I.SetImm( ImmediateValue );
		I.SetDestZero( true );
		if (HasOffset)
		{		
			I.SetSrc1Displace( false );
			I.SetSrc0Displace( true );
		}
		I.SetCode( EOPERATION_ADD );
		mInstructions.push_back(I);
		I.Clear();
		}
		{
		I.SetDestinationAddress( atoi($1.c_str()+1) );
		I.SetWriteChannel(ECHANNEL_Z);
		std::string StringHex = $8;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		I.SetImm( ImmediateValue );
		I.SetDestZero( true );
		if (HasOffset)
		{		
			I.SetSrc1Displace( false );
			I.SetSrc0Displace( true );
		}
		I.SetCode( EOPERATION_ADD );
		mInstructions.push_back(I);
		I.Clear();
		}
		
	 }
	 |
	 left_hand_side MINUS MINUS EOS
	 {
		
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetCode( EOPERATION_ADD );
		SetDestinationFromRegister( $1, I );
		I.SetSrc0SignX( true );
		I.SetSrc0SignY( true );
		I.SetSrc0SignZ( true );
		std::string Destination = $1;
		if (Destination.find("&&") != std::string::npos)
			Destination.erase(Destination.find("&&"));
			
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
		SetDestinationFromRegister( $1, I );
		std::string Destination = $1;
		if (Destination.find("&&") != std::string::npos)
			Destination.erase(Destination.find("&&"));
			
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
		
		mInstructions[ mInstructions.size() - gInsertedInstructions].mSourceLine = GetCurrentLineNumber(yylloc);
	    gInsertedInstructions = 0;		
		std::string Destination = $1;
		
		//Look for displament addressing mode
		if (Destination.find("&&") != std::string::npos)
		{
			Destination.erase(Destination.find("&"));
			//std::cout << "^_^ left_hand_side " << Destination << "\n";
			mInstructions.back().SetDestZero( true ); //When Imm != 0, DestZero means DST = DSTINDEX + offset
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
		ResetTempRegisterIndex();
	}
	| IF 
	  OPEN_ROUND_BRACE boolean_expression CLOSE_ROUND_BRACE 
	  OPEN_BRACE statement_list CLOSE_BRACE
      ELSE 
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
	  //std::cout << "else\n";
	  
	} 
	  OPEN_BRACE  statement_list CLOSE_BRACE
	{
	   
	   mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size());
	   gBranchStack.pop_back();
	   //Now push the JMP
	   
		//std::cout << "END elseif\n";
	}
	|
	//NOW the if statement
	IF OPEN_ROUND_BRACE boolean_expression CLOSE_ROUND_BRACE OPEN_BRACE statement_list CLOSE_BRACE  
	{
		mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size());
		//mInstructions[gBranchStack.back()].mSourceLine = GetCurrentLineNumber(yylloc);
		
		gBranchStack.pop_back();
		//std::cout << "if closing at " << mInstructions.size() << "\n";
		
	}
	|
	FUNCTION IDENTIFIER OPEN_ROUND_BRACE function_argument_list CLOSE_ROUND_BRACE
	{
	  //std::cout << "Function declaration for " << $2 << " at " << mInstructions.size() << "\n" ;
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
	|
	left_hand_side ASSIGN IDENTIFIER OPEN_ROUND_BRACE function_input_list CLOSE_ROUND_BRACE EOS
	{
		//std::cout << "Function call returning to var\n";
		StoreReturnAddress( mInstructions, yylloc );
		SavePreviousFramePointer( mInstructions );
		UpdateFramePointer( mInstructions );
		CallFunction( $3, mInstructions, mSymbolMap );
		
		
		//Return value comes in R1, so let's store this in our variable
		I.SetCode( EOPERATION_ADD );
		SetDestinationFromRegister( $1, I );
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
	// |
	// left_hand_side ASSIGN IDENTIFIER OPEN_ROUND_BRACE CLOSE_ROUND_BRACE EOS
	// {
		// std::cout << "Function call returning to var\n";
		// StoreReturnAddress( mInstructions, yylloc );
		// SavePreviousFramePointer( mInstructions );
		// UpdateFramePointer( mInstructions );
		// CallFunction( $3, mInstructions, mSymbolMap );
		
		
		// //Return value comes in R1, so let's store this in our variable
		// I.SetCode( EOPERATION_ADD );
		// SetDestinationFromRegister( $1, I );
		// I.mComment = "grab the return value from the function";
		// I.SetSrc1Address(1);
		// I.SetSrc0Address(0);
		// I.SetSrc0SwizzleX(SWX_X);
		// I.SetSrc0SwizzleY(SWY_X);
		// I.SetSrc0SwizzleZ(SWZ_X);
		// mInstructions.push_back( I );
		// I.Clear();
	// }
	|
	//Function call
	IDENTIFIER  OPEN_ROUND_BRACE CLOSE_ROUND_BRACE EOS
	{
		//Store the return address
		I.SetCode( EOPERATION_ADD );
		I.mComment = "store return address";
		I.SetImm( mInstructions.size()+4 );
		I.SetWriteChannel(ECHANNEL_XYZ);
		I.SetDestinationAddress( RETURN_ADDRESS_REGISTER );
		I.SetDestZero( true );
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		mInstructions.push_back( I );
		I.Clear();
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
		if (mSymbolMap.find($1) == mSymbolMap.end())
		{
		//	//std::cout << "Error in line : " << $1 <<" undelcared IDENTIFIER\n";
			I.SetDestinationSymbol( "@"+$1 );
		//	exit(1);
		} else {
			I.SetDestinationAddress( mSymbolMap[ $1 ] );
		}
		
		
		mInstructions.push_back( I );
		I.Clear();
		
	}
	;
	function_input_list
					  :
					  |//empty
					  IDENTIFIER COMMA function_input_list
					  {
						AddFunctionInputList( $1, mInstructions,yylloc );
					  }
					  |
					  IDENTIFIER
					  {
						AddFunctionInputList( $1,mInstructions, yylloc );
					  }
					  // |
					  // constant COMMA function_input_list
					  // {
						// unsigned FunctionParamReg = GetNextFunctionParamRegister();
						// I.SetDestinationAddress( FunctionParamReg );
						// unsigned int ImmediateValue;
						// std::string StringHex = $1;
						// std::stringstream ss;
						// ss << std::hex << StringHex;
						// ss >> ImmediateValue;
						// I.SetImm( ImmediateValue );
						// I.SetDestZero( true );
						// I.SetCode( EOPERATION_ADD );
						// I.mComment = "Adding literal as function input param";
						// mInstructions.push_back(I);
						// I.Clear();
					  // }
					  // |
					  // constant
					  // {
						// unsigned FunctionParamReg = GetNextFunctionParamRegister();
						// I.SetDestinationAddress( FunctionParamReg );
						// unsigned int ImmediateValue;
						// std::string StringHex = $1;
						// std::stringstream ss;
						// ss << std::hex << StringHex;
						// ss >> ImmediateValue;
						// I.SetImm( ImmediateValue );
						// I.SetDestZero( true );
						// I.SetCode( EOPERATION_ADD );
						// I.mComment = "Adding literal as function input param";
						// mInstructions.push_back(I);
						// I.Clear();
					  // }
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
	
// <Exp> ::= <Exp> + <Term> |
          // <Exp> - <Term> |
          // <Term>

// <Term> ::= <Term> * <Factor> |
           // <Term> / <Factor> |
           // <Factor>

// <Factor> ::= x | y | ... |
             // ( <Exp> ) |
             // - <Factor> |
             // <Number>
			 
expression
		:
		expression ADD term
		{
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetCode( EOPERATION_ADD );
			I.SetDestinationAddress( TempRegIndex );
			I.SetWriteChannel(ECHANNEL_XYZ);
				
			PopulateSourceRegisters( $1, $3, I);
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			$$ = ss.str();
			
		}
		|
		expression MINUS term
		{
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetCode( EOPERATION_ADD );
			I.SetDestinationAddress( TempRegIndex );
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetSrc0SignX( true );
			I.SetSrc0SignY( true );
			I.SetSrc0SignZ( true );
				
			PopulateSourceRegisters( $1, $3, I);
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			$$ = ss.str();
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
			
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_MUL );
			
			PopulateSourceRegisters( $1, $3, I);
			
			//If we are using fixed point aritmethic then we need to apply the scale
			//R = A * ( B >> SCALE)
			if (mGenerateFixedPointArithmetic)
				I.SetSrc0Rotation( EROT_RESULT_RIGHT );
			
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			$$ = ss.str();
		}
		|
		term DIV factor
		{
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_DIV );
			
			PopulateSourceRegisters( $1, $3, I);
			
			//If we are using fixed point aritmethic then we need to apply the scale
			// R = (A << N) / B
			if (mGenerateFixedPointArithmetic)
				I.SetSrc1Rotation( EROT_SRC1_LEFT );
			
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex;
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
		|
		SQRT OPEN_ROUND_BRACE expression CLOSE_ROUND_BRACE
		{
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetDestinationAddress( TempRegIndex );
			I.SetWriteChannel(ECHANNEL_XYZ);
			I.SetCode( EOPERATION_SQRT );
			I.SetSrc0Address( 0 );       
			PopulateSourceRegisters( $3 ,"R0.XXX", I);
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			
			std::stringstream ss;
			ss << "R" << TempRegIndex;
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
	IDENTIFIER
	{
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($1)) != "NULL")
			$$ = Register;
		 else
			$$ = GetRegisterFromAutoVar( $1, yylloc) + " && ";
	}
	|
	IDENTIFIER DOT coordinate coordinate coordinate
	{
		std::string X = $3,Y = $4,Z = $5;
		std::string Register;
		if ((Register = GetRegisterFromFunctionParameter($1)) != "NULL")
			$$ = (Register + "." + " " + X + " " + Y  + " " + Z + " && ");
		else
			$$ = (GetRegisterFromAutoVar( $1, yylloc) + "." + " " + X + " " + Y  + " " + Z + " && ");
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
		$$ = "R" + R + "." + " " + X + " " + Y  + " " + Z;
	
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
	
left_hand_side
	:
	IDENTIFIER
	{
	    $$ = GetRegisterFromAutoVar( $1, yylloc ) + ".xyz" + " && ";
	} 
	|
	IDENTIFIER DOT TK_X
	{
		$$ = GetRegisterFromAutoVar( $1, yylloc ) + ".x" + " && ";
	}
	|
	IDENTIFIER DOT TK_Y
	{
		$$ = GetRegisterFromAutoVar( $1, yylloc ) + ".y" + " && ";
	}
	|
	IDENTIFIER DOT TK_Z
	{
		$$ = GetRegisterFromAutoVar( $1, yylloc ) + ".z" + " && ";
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
				source NOT_EQUAL constant
				{
					I.mSourceLine = GetCurrentLineNumber( yylloc );
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.SetBranchType( EBRANCH_IF_ZERO );
					if ($3 == "0")
						PopulateSourceRegisters( $1, "R0 . X X X", I);
					mInstructions.push_back(I);
					I.Clear();
					
					//std::cout << "pushing code at position " << (mInstructions.size() - 1) << "\n";
					gBranchStack.push_back(mInstructions.size() - 1);
				}
				|
				source EQUAL constant
				{
					I.mSourceLine = GetCurrentLineNumber( yylloc );
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.SetBranchType( EBRANCH_IF_NOT_ZERO );
					if ($3 == "0")
						PopulateSourceRegisters( $1, "R0 . X X X", I);
					mInstructions.push_back(I);
					I.Clear();
										
					gBranchStack.push_back(mInstructions.size() - 1);
				}
				|
				source EQUAL source 
				{
					I.mSourceLine = GetCurrentLineNumber( yylloc );
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.SetBranchType( EBRANCH_IF_NOT_ZERO );
					PopulateSourceRegisters( $1, $3, I);
					mInstructions.push_back(I);
					I.Clear();
					
					//std::cout << "pushing code at position " << (mInstructions.size() - 1) << "\n";
					gBranchStack.push_back(mInstructions.size() - 1);
					
					//std::cout << "== \n";
				}
				|
				source NOT_EQUAL source 
				{
					I.mSourceLine = GetCurrentLineNumber( yylloc );
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.SetBranchType( EBRANCH_IF_ZERO );
					PopulateSourceRegisters( $1, $3, I);
					mInstructions.push_back(I);
					I.Clear();
					//std::cout << "pushing code at position " << (mInstructions.size() - 1) << "\n";
					gBranchStack.push_back(mInstructions.size() - 1);
					
					//std::cout << "!= \n";
				}
				|
				source GREATER_THAN source
				{
					I.mSourceLine = GetCurrentLineNumber( yylloc );
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.SetBranchType( EBRANCH_IF_ZERO_OR_SIGN );
					PopulateSourceRegisters( $1, $3, I);
					mInstructions.push_back(I);
					I.Clear();
					//std::cout << "pushing code at position " << (mInstructions.size() - 1) << "\n";
					gBranchStack.push_back(mInstructions.size() - 1);
					
					//std::cout << "> \n";
				}				
				|
				source LESS_THAN source
				{
					I.mSourceLine = GetCurrentLineNumber( yylloc );
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.SetBranchType( EBRANCH_IF_ZERO_OR_NOT_SIGN );
					PopulateSourceRegisters( $1, $3, I);
					mInstructions.push_back(I);
					I.Clear();
					//std::cout << "pushing code at position " << (mInstructions.size() - 1) << "\n";
					gBranchStack.push_back(mInstructions.size() - 1);
					
					//std::cout << "< \n";
				}
				|
				source LESS_OR_EQUAL_THAN source
				{
					I.mSourceLine = GetCurrentLineNumber( yylloc );
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.SetBranchType( EBRANCH_IF_NOT_SIGN );
					PopulateSourceRegisters( $1, $3, I);
					mInstructions.push_back(I);
					I.Clear();
					//std::cout << "pushing code at position " << (mInstructions.size() - 1) << "\n";
					gBranchStack.push_back(mInstructions.size() - 1);
					
					//std::cout << "<= \n";
				}				
				|
				source GREATER_OR_EQUAL_THAN source
				{
					I.mSourceLine = GetCurrentLineNumber( yylloc );
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.SetBranchType( EBRANCH_IF_SIGN );
					PopulateSourceRegisters( $1, $3, I);
					mInstructions.push_back(I);
					I.Clear();
					//std::cout << "pushing code at position " << (mInstructions.size() - 1) << "\n";
					gBranchStack.push_back(mInstructions.size() - 1);
					
					//std::cout << ">= \n";
				}
				|
				source GREATER_OR_EQUAL_THAN constant
				{
					I.mSourceLine = GetCurrentLineNumber( yylloc );
					I.SetCode( EOPERATION_ADD );
					I.SetSrc0SignX( true );
					I.SetSrc0SignY( true );
					I.SetSrc0SignZ( true );
					I.SetBranchFlag( true );
					I.SetBranchType( EBRANCH_IF_SIGN );
					if ($3 == "0")
					{
						PopulateSourceRegisters( $1, "R0 . X X X", I);
					}
					mInstructions.push_back(I);
					I.Clear();
					//std::cout << "pushing code at position " << (mInstructions.size() - 1) << "\n";
					gBranchStack.push_back(mInstructions.size() - 1);
					
					//std::cout << ">= \n";
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
			unsigned int Val;
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
			unsigned long Val;
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
			IDENTIFIER COMMA auto_var_list
			{
				if (gAutoVarMap.find($1) != gAutoVarMap.end())
				{
				std::ostringstream ret;
				ret << "Duplicated symbol " << $1 << "'\n";
				throw ret.str();
				}
				gAutoVarMap[ $1 ] = GetAutoVarIndex();
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
				gAutoVarMap[ $1 ] = GetAutoVarIndex();
				
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
				gAutoVarMap[ $1 ] = GetAutoVarIndex();
				
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
			IDENTIFIER
			{
				//std::cout << "\n\n\nHERE!!! " << $1 << "\n\n\n";
				if (gAutoVarMap.find($1) != gAutoVarMap.end())
				{
				std::ostringstream ret;
				ret << "Duplicated symbol " << $1 << "'\n";
				throw ret.str();
				}
				gAutoVarMap[ $1 ] = GetAutoVarIndex();
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

