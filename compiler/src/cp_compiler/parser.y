
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
%parse-param { std::vector< CControlInstruction > &mInstructions }
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
	CControlInstruction I;
	std::vector< unsigned int > gBranchStack;
	static int gInsertedInstructions = 0;
	static int gWhileLoopAddress = 0;
#define FUNCTION_PARAM_START_REGION 4
#define FUNCTION_PARAM_LAST_REGION  7
	std::map<std::string, unsigned int> gVaribleMap;
	
#define AUTOVAR_START_REGION 9
#define TEMP_VAR_START_OFFSET 128
unsigned int gAutoVarIndex = AUTOVAR_START_REGION;

unsigned int gFunctionParameterIndex = FUNCTION_PARAM_START_REGION;
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
unsigned int GetAddressFromIdentifier( std::string aIdentifier, Theia::Parser::location_type  yylloc )
{
	if (aIdentifier.find("R") != std::string::npos)
	{
		return atoi(aIdentifier.c_str()+1);
	}
	if (gVaribleMap.find(aIdentifier) == gVaribleMap.end())
	{
			std::ostringstream ret;
			ret << "Undefined variable '" << aIdentifier << "' at line " << yylloc << " \n";
			throw ret.str();
	}
		
	return gVaribleMap[ aIdentifier ];

}
//----------------------------------------------------------
unsigned int gTempRegisterIndex = TEMP_VAR_START_OFFSET;
//----------------------------------------------------------			
unsigned int GetFreeTempRegister( void )
{
	
	return gTempRegisterIndex++;
	
}
//----------------------------------------------------------			
void ResetTempRegisterIndex( void )
{
	
	gTempRegisterIndex = TEMP_VAR_START_OFFSET;
}
//----------------------------------------------------------
unsigned int AllocateVariable( )
{
		gAutoVarIndex++;
		return gAutoVarIndex;
	
}	
//----------------------------------------------------------
	// Prototype for the yylex function
	static int yylex(Theia::Parser::semantic_type * yylval,
	                 Theia::Parser::location_type * yylloc,
	                 Theia::Scanner &scanner);
}

%token SHL SHR SCALAR RETURN EXIT EQUAL NOT_EQUAL GREATER_THAN LESS_THAN LESS_OR_EQUAL_THAN GREATER_OR_EQUAL_THAN IF ELSE OPEN_ROUND_BRACE CLOSE_ROUND_BRACE OPEN_BRACE CLOSE_BRACE ASSIGN ADD DECCONST HEXCONST BINCONST EOS MINUS 
%token IDENTIFIER  COMMA OPEN_SQUARE_BRACE CLOSE_SQUARE_BRACE WHILE START BITWISE_AND BITWISE_OR COPY_DATA_BLOCK COPY_CODE_BLOCK BLOCK_TRANSFER_IN_PROGRESS
%%

statement_list: //empty
	|
	statement_list statement
	|
	statement
	;

statement
	:
	START LESS_THAN constant GREATER_THAN EOS
	{
	
		unsigned int ImmediateValue;
		std::string StringHex = $3;
		std::stringstream ss;
		ss << std::hex << StringHex;
		ss >> ImmediateValue;
		
		
		I.mComment = "Start";
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation(EOPERATION_DELIVERCOMMAND);
		I.SetDestinationAddress( ImmediateValue+1 );
		I.SetSrc1Address( VP_COMMAND_START_MAIN_THREAD );
		mInstructions.push_back(I);
		I.Clear();
	}
	|
	SCALAR scalar_list EOS
	|
	COPY_DATA_BLOCK LESS_THAN expression COMMA expression COMMA expression GREATER_THAN EOS
	{
	
		I.SetOperation( EOPERATION_ADD );
		I.mComment = "Setting destination ID SPR for Copy data block";
		I.SetDestinationAddress( BLOCK_DST_REG );
		I.SetSrc1Address( GetAddressFromIdentifier($3,yylloc));
		I.SetSrc0Address(0);
		mInstructions.push_back(I);
		I.Clear();
		
		std::cout << "COPY_DATA_BLOCK I(" << GetAddressFromIdentifier($3,yylloc) << ") " << GetAddressFromIdentifier($5,yylloc) << " " << GetAddressFromIdentifier($7,yylloc) << "\n";
		I.mComment = "Copy data block";
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation(EOPERATION_COPYBLOCK);
		//I.SetCopyDestinationId(ImmediateValue);
		I.SetCopyDestinationId(0);
		I.SetCopyDestinationAddress(GetAddressFromIdentifier($5,yylloc));
		I.SetCopySourceAddress(GetAddressFromIdentifier($7,yylloc));
		I.SetCopySize(GetAddressFromIdentifier($9,yylloc));
		mInstructions.push_back(I);
		I.Clear();
	}
	|
	EXIT EOS
	{
		//Insert a stupid NOP before the exit... is a bug but easier to just patch like this...
		
		I.mComment = "Exit";
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation(EOPERATION_EXIT);
		mInstructions.push_back(I);
		I.Clear();
	}
	
	 |
	 IDENTIFIER MINUS MINUS EOS
	 {
		
		I.mComment = "Storing constant '1'";
		I.SetOperation( EOPERATION_SUB );
		unsigned int TmpReg  = GetFreeTempRegister(); 
		I.SetDestinationAddress( TmpReg );
		I.SetLiteral(1);
		mInstructions.push_back( I );
		I.Clear();
		
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation( EOPERATION_ADD );
		I.SetDestinationAddress( GetAddressFromIdentifier($1,yylloc) );
		I.SetSrc1Address( GetAddressFromIdentifier($3,yylloc));
		I.SetSrc0Address( TmpReg );
		mInstructions.push_back( I );
		I.Clear();
		gInsertedInstructions = 0;	
		ResetTempRegisterIndex();
	 }
	 |
	 IDENTIFIER ADD ADD EOS
	 {
	 
	    I.mComment = "Storing constant '1'";
		I.SetOperation( EOPERATION_ADD );
		unsigned int TmpReg  = GetFreeTempRegister(); 
		I.SetDestinationAddress( TmpReg );
		I.SetLiteral(1);
		mInstructions.push_back( I );
		I.Clear();
		
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation( EOPERATION_ADD );
		I.SetDestinationAddress( GetAddressFromIdentifier($1,yylloc) );
		I.SetSrc1Address( GetAddressFromIdentifier($3,yylloc));
		I.SetSrc0Address( TmpReg );
		mInstructions.push_back( I );
		I.Clear();
		gInsertedInstructions = 0;	
		ResetTempRegisterIndex();
	
	 }
	 |
	 IDENTIFIER ASSIGN expression  EOS
	{
	    mInstructions[mInstructions.size()-gInsertedInstructions].mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation( EOPERATION_ADD );
		I.SetDestinationAddress( GetAddressFromIdentifier($1,yylloc) );
		I.SetSrc1Address( GetAddressFromIdentifier($3,yylloc));
		I.SetSrc0Address(0);
		mInstructions.push_back( I );
		I.Clear();
		gInsertedInstructions = 0;
		ResetTempRegisterIndex();
	}
	|
	IDENTIFIER ADD ASSIGN expression EOS
	{
		mInstructions[mInstructions.size()-gInsertedInstructions].mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation( EOPERATION_ADD );
		I.SetDestinationAddress( GetAddressFromIdentifier($1,yylloc) );
		I.SetSrc1Address( GetAddressFromIdentifier($4,yylloc));
		I.SetSrc0Address( GetAddressFromIdentifier($1,yylloc) );
		mInstructions.push_back( I );
		I.Clear();
		gInsertedInstructions = 0;	
	}
	|
	WHILE {gWhileLoopAddress = (mInstructions.size());} OPEN_ROUND_BRACE boolean_expression CLOSE_ROUND_BRACE OPEN_BRACE statement_list CLOSE_BRACE
	{
		mInstructions[gBranchStack.back()].SetDestinationAddress(mInstructions.size()+1);
		gBranchStack.pop_back();
		//Now I need to put a GOTO so that the while gets evaluated again...
		//jump out of the if
	   I.Clear();
	   I.SetOperation( EOPERATION_BRANCH );
	   I.mComment = "while loop goto re-eval boolean";
	   I.SetDestinationAddress( gWhileLoopAddress );
	   mInstructions.push_back(I);
	   I.Clear();
	   
	   I.SetOperation( EOPERATION_NOP );
	   I.mComment = "branch delay";
	   I.SetDestinationAddress( gWhileLoopAddress );
	   mInstructions.push_back(I);
	   I.Clear();
	   gInsertedInstructions = 0;
	}
	|
	START IDENTIFIER EOS
	{
		
	}
	;
	

			 
expression
		:
		expression ADD term
		{
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_ADD );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier($1,yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier($3,yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			$$ = ss.str();
			
			//$$ = ss.str();
			
		}
		|
		expression BITWISE_OR term
		{
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_OR );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier($1,yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier($3,yylloc));
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
			I.SetOperation( EOPERATION_SUB );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier($1,yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier($3,yylloc));
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
		factor SHL factor
		{
			
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_SHL );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier($1,yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier($3,yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			$$ = ss.str();
		}
		|
		factor SHR factor
		{
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_SHR );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier($1,yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier($3,yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			$$ = ss.str();
		}
		|
		factor BITWISE_AND factor
		{
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_AND );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier($1,yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier($3,yylloc));
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
		IDENTIFIER
		{
			$$ = $1;
		}
		|
		OPEN_ROUND_BRACE expression CLOSE_ROUND_BRACE
		{
			$$ = $2;
		}
		|
		constant
		{
			unsigned int ImmediateValue;
			std::string StringHex = $1;
			std::stringstream ss;
			ss << std::hex << StringHex;
			ss >> ImmediateValue;
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_ASSIGN );
		//	I.mSourceLine = GetCurrentLineNumber( yylloc );
			
			I.SetDestinationAddress( TempRegIndex );
			
			I.SetLiteral(ImmediateValue);
			
			mInstructions.push_back(I);
			
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss2;
			ss2 << "R" << TempRegIndex;
			$$ = ss2.str();
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
			ss2 << std::hex <<  Bitset;
			$$ = ss2.str();
		}
	;
	
boolean_expression
	:
	BLOCK_TRANSFER_IN_PROGRESS
	{
	
			unsigned int ImmediateValue = 0x1; 
			unsigned int TempRegIndex0  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_ASSIGN );
			I.SetDestinationAddress( TempRegIndex0 );
			I.SetLiteral(ImmediateValue);
			mInstructions.push_back(I);
			gInsertedInstructions++;
	
			
			I.SetOperation( EOPERATION_BEQ );
			I.SetDestinationAddress( 0 );
			I.SetSrc1Address( STATUS_REG );
			I.SetSrc0Address(TempRegIndex0);
			mInstructions.push_back(I);
			gInsertedInstructions++;
			gBranchStack.push_back(mInstructions.size() - 1);
			I.Clear();
			
			I.SetOperation( EOPERATION_NOP );
			I.mComment = "branch delay";
			I.SetDestinationAddress( gWhileLoopAddress );
			mInstructions.push_back(I);
			I.Clear();
			
			
		
	}
	|
	expression EQUAL expression
	{
			
			I.SetOperation( EOPERATION_BNE );
			I.SetDestinationAddress( 0 );
			I.SetSrc1Address( GetAddressFromIdentifier($1,yylloc) );
			I.SetSrc0Address( GetAddressFromIdentifier($3,yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			gBranchStack.push_back(mInstructions.size() - 1);
			I.Clear();
			
			I.SetOperation( EOPERATION_NOP );
			I.mComment = "branch delay";
			I.SetDestinationAddress( gWhileLoopAddress );
			mInstructions.push_back(I);
			I.Clear();
			
	}
	|
	expression LESS_OR_EQUAL_THAN expression
	{
			
			I.SetOperation( EOPERATION_BLE );
			I.SetDestinationAddress( 0 );
			I.SetSrc1Address( GetAddressFromIdentifier($1,yylloc) );
			I.SetSrc0Address( GetAddressFromIdentifier($3,yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			gBranchStack.push_back(mInstructions.size() - 1);
			I.Clear();
			
			I.SetOperation( EOPERATION_NOP );
			I.mComment = "branch delay";
			I.SetDestinationAddress( gWhileLoopAddress );
			mInstructions.push_back(I);
			I.Clear();
			
	}
;	
scalar_list
			:
			IDENTIFIER COMMA scalar_list
			{
				if (gVaribleMap.find($1) != gVaribleMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << $1 << "'\n";
					throw ret.str();
				}
			
				gVaribleMap[ $1 ] = AllocateVariable();
			}
			|
			IDENTIFIER ASSIGN constant COMMA scalar_list
			{
				if (gVaribleMap.find($1) != gVaribleMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << $1 << "'\n";
					throw ret.str();
				}
			
				gVaribleMap[ $1 ] = AllocateVariable();
				I.mSourceLine = GetCurrentLineNumber( yylloc );
				I.SetOperation( EOPERATION_ASSIGN );
				I.SetDestinationAddress( gVaribleMap[ $1 ] );
				I.SetLiteral( atoi($3.c_str() ) );
				mInstructions.push_back( I );
				I.Clear();
				
			}
			|
			IDENTIFIER ASSIGN constant
			{
				if (gVaribleMap.find($1) != gVaribleMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << $1 << "'\n";
					throw ret.str();
				}
				unsigned int ImmediateValue;
				std::string StringHex = $3;
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				gVaribleMap[ $1 ] = AllocateVariable();
				I.mSourceLine = GetCurrentLineNumber( yylloc );
				I.SetOperation( EOPERATION_ASSIGN );
				I.SetDestinationAddress( gVaribleMap[ $1 ] );
				I.SetLiteral( ImmediateValue );
				mInstructions.push_back( I );
				I.Clear();
			}
			|
			IDENTIFIER  
			{
				if (gVaribleMap.find($1) != gVaribleMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << $1 << "'\n";
					throw ret.str();
				}
			
				gVaribleMap[ $1 ] = AllocateVariable();
			}
			;


%%



// Error function throws an exception (std::string) with the location and error message
void Theia::Parser::error(const Theia::Parser::location_type &loc,
                                          const std::string &msg) {
	std::ostringstream ret;
	ret << "\ncp_compile -- Parser Error at " << loc << ": "  << msg;
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

