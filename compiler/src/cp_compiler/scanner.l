%{

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

	#include "Scanner.h"
	// used to keep track of location
	#define YY_USER_ACTION yylloc->columns(yyleng);
	int LineNumber = 1;
%}

%option nodefault yyclass="Scanner" noyywrap c++

comment     "//"(.*)*\n
separator   ([ \t""])+
character   [a-zA-Z]
hexchar     [a-fA-F]
digit       [0-9]
decconstant    {digit}({digit})*
hexconstant 0x({digit}|{hexchar})+
binconstant 0b(1|0)+
registry    (r|R)({digit})+
identifier ([a-wA-Z])({character}|{digit}|_)*


%%

%{
	yylloc->step();
%}

{comment}    {yylloc->lines(); ;LineNumber++; ;}
"\n"         {yylloc->lines(); ;LineNumber++;}
{separator}  {/* do nothing */}
{decconstant}   { *yylval = yytext; return Theia::Parser::token::DECCONST; }
{hexconstant}   { *yylval = yytext; return Theia::Parser::token::HEXCONST; }
{binconstant}   { *yylval = yytext; return Theia::Parser::token::BINCONST; }
"if"            {return Theia::Parser::token::IF;}
"else"            {return Theia::Parser::token::ELSE;}
"while"		 {return Theia::Parser::token::WHILE;}
"&"			 {return Theia::Parser::token::BITWISE_AND;}
"|"			 {return Theia::Parser::token::BITWISE_OR;}
"exit"         {return Theia::Parser::token::EXIT;}
"scalar"       {return Theia::Parser::token::SCALAR;}
"start"       {return Theia::Parser::token::START;}
"copy_data_block"       {return Theia::Parser::token::COPY_DATA_BLOCK;}
"copy_code_block"       {return Theia::Parser::token::COPY_CODE_BLOCK;}
block_transfer_in_progress"" {return Theia::Parser::token::BLOCK_TRANSFER_IN_PROGRESS;}
"("            {return Theia::Parser::token::OPEN_ROUND_BRACE;}
")"            {return Theia::Parser::token::CLOSE_ROUND_BRACE;}
"{"            {return Theia::Parser::token::OPEN_BRACE;}
"}"            {return Theia::Parser::token::CLOSE_BRACE;}
"-"          {*yylval = yytext;return Theia::Parser::token::MINUS;   }
"=="          {return Theia::Parser::token::EQUAL; }
"!="          {return Theia::Parser::token::NOT_EQUAL; }
"<="          {return Theia::Parser::token::LESS_OR_EQUAL_THAN; }
">="          {return Theia::Parser::token::GREATER_OR_EQUAL_THAN; }
"="          {return Theia::Parser::token::ASSIGN; }
"<<"        { return Theia::Parser::token::SHL;}
">>"         { return Theia::Parser::token::SHR;}
">"          {return Theia::Parser::token::GREATER_THAN; }
"<"          {return Theia::Parser::token::LESS_THAN; }
"+"          {return Theia::Parser::token::ADD;   }
";"          {return Theia::Parser::token::EOS;   }
","          {return Theia::Parser::token::COMMA;   }

{identifier} {*yylval = yytext; return Theia::Parser::token::IDENTIFIER;}
.		     {
				std::ostringstream ret;
				ret << "Unknown Indetifier at line " << LineNumber << " '" << yytext << "'\n";
				throw ret.str();
			 };
%%
