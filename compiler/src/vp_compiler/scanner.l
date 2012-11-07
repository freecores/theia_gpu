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
"sqrt"			{return Theia::Parser::token::SQRT;}
"if"            {return Theia::Parser::token::IF;}
"else"            {return Theia::Parser::token::ELSE;}
"while"		 {return Theia::Parser::token::WHILE;}
"&"			 {return Theia::Parser::token::BITWISE_AND;}
"|"			 {return Theia::Parser::token::BITWISE_OR;}
"function"   {return Theia::Parser::token::FUNCTION;}
"jmp"        {return Theia::Parser::token::JMP;} 
"return"          {return Theia::Parser::token::RETURN;}
"exit"         {return Theia::Parser::token::EXIT;}
"vector"         {return Theia::Parser::token::AUTO;}
"thread"       {return Theia::Parser::token::THREAD;}
"start"       {return Theia::Parser::token::START;}
"("            {return Theia::Parser::token::OPEN_ROUND_BRACE;}
")"            {return Theia::Parser::token::CLOSE_ROUND_BRACE;}
"{"            {return Theia::Parser::token::OPEN_BRACE;}
"}"            {return Theia::Parser::token::CLOSE_BRACE;}
"-"          {*yylval = yytext;return Theia::Parser::token::MINUS;   }
"=="          {return Theia::Parser::token::EQUAL; }
"!="          {return Theia::Parser::token::NOT_EQUAL; }
"scale"		  {return Theia::Parser::token::SCALE; }
"unscale"	  {return Theia::Parser::token::UNSCALE; }
"using"		  {return Theia::Parser::token::USING; }
"out"         {return Theia::Parser::token::OUT; }
"in"         {return Theia::Parser::token::IN; }
"fixed_point_arithmetic" {return Theia::Parser::token::FIXED_POINT; }
"<="          {return Theia::Parser::token::LESS_OR_EQUAL_THAN; }
">="          {return Theia::Parser::token::GREATER_OR_EQUAL_THAN; }
"="          {return Theia::Parser::token::ASSIGN; }
">"          {return Theia::Parser::token::GREATER_THAN; }
"<"          {return Theia::Parser::token::LESS_THAN; }
"["			 {return Theia::Parser::token::OPEN_SQUARE_BRACE; }
"]"          {return Theia::Parser::token::CLOSE_SQUARE_BRACE; }
"*"           {return Theia::Parser::token::MUL;   }
"/"          {return Theia::Parser::token::DIV;   }
"+="         {return Theia::Parser::token::ADD_EQ; }
"+"          {return Theia::Parser::token::ADD;   }
";"          {return Theia::Parser::token::EOS;   }
","          {return Theia::Parser::token::COMMA;   }
"."          {return Theia::Parser::token::DOT;   }
x	         {*yylval = yytext;return Theia::Parser::token::TK_X;  }
y            {*yylval = yytext;return Theia::Parser::token::TK_Y;  }
z            {*yylval = yytext;return Theia::Parser::token::TK_Z;  }
"n"	         {*yylval = yytext;return Theia::Parser::token::TK_N;  }
{registry} { *yylval = yytext; return Theia::Parser::token::REG;}
{identifier} {*yylval = yytext; return Theia::Parser::token::IDENTIFIER;}
.		     {
				std::ostringstream ret;
				ret << "Unknown Indetifier at line " << LineNumber << " '" << yytext << "'\n";
				throw ret.str();
			 };
%%
