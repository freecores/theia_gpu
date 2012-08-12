
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



/* Line 318 of lalr1.cc  */
#line 133 "parser.tab.c"

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
#line 201 "parser.tab.c"
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
  Parser::Parser (Theia::Scanner &scanner_yyarg, std::map<std::string,unsigned int>  & mSymbolMap_yyarg, std::vector< CControlInstruction > &mInstructions_yyarg, bool &mGenerateFixedPointArithmetic_yyarg)
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
	  case 5:

/* Line 678 of lalr1.cc  */
#line 158 "parser.y"
    {
	
		unsigned int ImmediateValue;
		std::string StringHex = (yysemantic_stack_[(5) - (3)]);
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
    break;

  case 7:

/* Line 678 of lalr1.cc  */
#line 179 "parser.y"
    {
	
		I.SetOperation( EOPERATION_ADD );
		I.mComment = "Setting destination ID SPR for Copy data block";
		I.SetDestinationAddress( BLOCK_DST_REG );
		I.SetSrc1Address( GetAddressFromIdentifier((yysemantic_stack_[(9) - (3)]),yylloc));
		I.SetSrc0Address(0);
		mInstructions.push_back(I);
		I.Clear();
		
		std::cout << "COPY_DATA_BLOCK I(" << GetAddressFromIdentifier((yysemantic_stack_[(9) - (3)]),yylloc) << ") " << GetAddressFromIdentifier((yysemantic_stack_[(9) - (5)]),yylloc) << " " << GetAddressFromIdentifier((yysemantic_stack_[(9) - (7)]),yylloc) << "\n";
		I.mComment = "Copy data block";
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation(EOPERATION_COPYBLOCK);
		//I.SetCopyDestinationId(ImmediateValue);
		I.SetCopyDestinationId(0);
		I.SetCopyDestinationAddress(GetAddressFromIdentifier((yysemantic_stack_[(9) - (5)]),yylloc));
		I.SetCopySourceAddress(GetAddressFromIdentifier((yysemantic_stack_[(9) - (7)]),yylloc));
		I.SetCopySize(GetAddressFromIdentifier((yysemantic_stack_[(9) - (9)]),yylloc));
		mInstructions.push_back(I);
		I.Clear();
	}
    break;

  case 8:

/* Line 678 of lalr1.cc  */
#line 203 "parser.y"
    {
		//Insert a stupid NOP before the exit... is a bug but easier to just patch like this...
		
		I.mComment = "Exit";
		I.mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation(EOPERATION_EXIT);
		mInstructions.push_back(I);
		I.Clear();
	}
    break;

  case 9:

/* Line 678 of lalr1.cc  */
#line 215 "parser.y"
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
		I.SetDestinationAddress( GetAddressFromIdentifier((yysemantic_stack_[(4) - (1)]),yylloc) );
		I.SetSrc1Address( GetAddressFromIdentifier((yysemantic_stack_[(4) - (3)]),yylloc));
		I.SetSrc0Address( TmpReg );
		mInstructions.push_back( I );
		I.Clear();
		gInsertedInstructions = 0;	
		ResetTempRegisterIndex();
	 }
    break;

  case 10:

/* Line 678 of lalr1.cc  */
#line 237 "parser.y"
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
		I.SetDestinationAddress( GetAddressFromIdentifier((yysemantic_stack_[(4) - (1)]),yylloc) );
		I.SetSrc1Address( GetAddressFromIdentifier((yysemantic_stack_[(4) - (3)]),yylloc));
		I.SetSrc0Address( TmpReg );
		mInstructions.push_back( I );
		I.Clear();
		gInsertedInstructions = 0;	
		ResetTempRegisterIndex();
	
	 }
    break;

  case 11:

/* Line 678 of lalr1.cc  */
#line 260 "parser.y"
    {
	    mInstructions[mInstructions.size()-gInsertedInstructions].mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation( EOPERATION_ADD );
		I.SetDestinationAddress( GetAddressFromIdentifier((yysemantic_stack_[(4) - (1)]),yylloc) );
		I.SetSrc1Address( GetAddressFromIdentifier((yysemantic_stack_[(4) - (3)]),yylloc));
		I.SetSrc0Address(0);
		mInstructions.push_back( I );
		I.Clear();
		gInsertedInstructions = 0;
		ResetTempRegisterIndex();
	}
    break;

  case 12:

/* Line 678 of lalr1.cc  */
#line 273 "parser.y"
    {
		mInstructions[mInstructions.size()-gInsertedInstructions].mSourceLine = GetCurrentLineNumber( yylloc );
		I.SetOperation( EOPERATION_ADD );
		I.SetDestinationAddress( GetAddressFromIdentifier((yysemantic_stack_[(5) - (1)]),yylloc) );
		I.SetSrc1Address( GetAddressFromIdentifier((yysemantic_stack_[(5) - (4)]),yylloc));
		I.SetSrc0Address( GetAddressFromIdentifier((yysemantic_stack_[(5) - (1)]),yylloc) );
		mInstructions.push_back( I );
		I.Clear();
		gInsertedInstructions = 0;	
	}
    break;

  case 13:

/* Line 678 of lalr1.cc  */
#line 284 "parser.y"
    {gWhileLoopAddress = (mInstructions.size());}
    break;

  case 14:

/* Line 678 of lalr1.cc  */
#line 285 "parser.y"
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
    break;

  case 15:

/* Line 678 of lalr1.cc  */
#line 306 "parser.y"
    {
		
	}
    break;

  case 16:

/* Line 678 of lalr1.cc  */
#line 316 "parser.y"
    {
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_ADD );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (1)]),yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (3)]),yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			(yyval) = ss.str();
			
			//$$ = ss.str();
			
		}
    break;

  case 17:

/* Line 678 of lalr1.cc  */
#line 334 "parser.y"
    {
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_OR );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (1)]),yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (3)]),yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			(yyval) = ss.str();
		}
    break;

  case 18:

/* Line 678 of lalr1.cc  */
#line 349 "parser.y"
    {
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_SUB );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (1)]),yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (3)]),yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			(yyval) = ss.str();
		}
    break;

  case 19:

/* Line 678 of lalr1.cc  */
#line 364 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(1) - (1)]);
		}
    break;

  case 20:

/* Line 678 of lalr1.cc  */
#line 372 "parser.y"
    {
			
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_SHL );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (1)]),yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (3)]),yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			(yyval) = ss.str();
		}
    break;

  case 21:

/* Line 678 of lalr1.cc  */
#line 388 "parser.y"
    {
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_SHR );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (1)]),yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (3)]),yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			(yyval) = ss.str();
		}
    break;

  case 22:

/* Line 678 of lalr1.cc  */
#line 403 "parser.y"
    {
			unsigned int TempRegIndex  = GetFreeTempRegister();
			I.SetOperation( EOPERATION_AND );
			I.SetDestinationAddress( TempRegIndex );
			I.SetSrc1Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (1)]),yylloc));
			I.SetSrc0Address(GetAddressFromIdentifier((yysemantic_stack_[(3) - (3)]),yylloc));
			mInstructions.push_back(I);
			gInsertedInstructions++;
			I.Clear();
			std::stringstream ss;
			ss << "R" << TempRegIndex;
			(yyval) = ss.str();
		}
    break;

  case 23:

/* Line 678 of lalr1.cc  */
#line 418 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(1) - (1)]);
		}
    break;

  case 24:

/* Line 678 of lalr1.cc  */
#line 426 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(1) - (1)]);
		}
    break;

  case 25:

/* Line 678 of lalr1.cc  */
#line 431 "parser.y"
    {
			(yyval) = (yysemantic_stack_[(3) - (2)]);
		}
    break;

  case 26:

/* Line 678 of lalr1.cc  */
#line 436 "parser.y"
    {
			unsigned int ImmediateValue;
			std::string StringHex = (yysemantic_stack_[(1) - (1)]);
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
			(yyval) = ss2.str();
		}
    break;

  case 27:

/* Line 678 of lalr1.cc  */
#line 465 "parser.y"
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

  case 28:

/* Line 678 of lalr1.cc  */
#line 478 "parser.y"
    {
			std::string StringHex = (yysemantic_stack_[(1) - (1)]);
			// Get rid of the 0x
			StringHex.erase(StringHex.begin(),StringHex.begin()+2);
			std::stringstream ss;
			ss << std::hex << StringHex;
			
			(yyval) = ss.str();
		}
    break;

  case 29:

/* Line 678 of lalr1.cc  */
#line 489 "parser.y"
    {
			// Transform to HEX string
			std::string StringBin = (yysemantic_stack_[(1) - (1)]);
			// Get rid of the 0b
			StringBin.erase(StringBin.begin(),StringBin.begin()+2);
			std::bitset<32> Bitset( StringBin );
			std::stringstream ss2;
			ss2 << std::hex <<  Bitset;
			(yyval) = ss2.str();
		}
    break;

  case 30:

/* Line 678 of lalr1.cc  */
#line 504 "parser.y"
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
    break;

  case 31:

/* Line 678 of lalr1.cc  */
#line 535 "parser.y"
    {
			
			I.SetOperation( EOPERATION_BNE );
			I.SetDestinationAddress( 0 );
			I.SetSrc1Address( GetAddressFromIdentifier((yysemantic_stack_[(3) - (1)]),yylloc) );
			I.SetSrc0Address( GetAddressFromIdentifier((yysemantic_stack_[(3) - (3)]),yylloc));
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
    break;

  case 32:

/* Line 678 of lalr1.cc  */
#line 555 "parser.y"
    {
			
			I.SetOperation( EOPERATION_BLE );
			I.SetDestinationAddress( 0 );
			I.SetSrc1Address( GetAddressFromIdentifier((yysemantic_stack_[(3) - (1)]),yylloc) );
			I.SetSrc0Address( GetAddressFromIdentifier((yysemantic_stack_[(3) - (3)]),yylloc));
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
    break;

  case 33:

/* Line 678 of lalr1.cc  */
#line 577 "parser.y"
    {
				if (gVaribleMap.find((yysemantic_stack_[(3) - (1)])) != gVaribleMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << (yysemantic_stack_[(3) - (1)]) << "'\n";
					throw ret.str();
				}
			
				gVaribleMap[ (yysemantic_stack_[(3) - (1)]) ] = AllocateVariable();
			}
    break;

  case 34:

/* Line 678 of lalr1.cc  */
#line 589 "parser.y"
    {
				if (gVaribleMap.find((yysemantic_stack_[(5) - (1)])) != gVaribleMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << (yysemantic_stack_[(5) - (1)]) << "'\n";
					throw ret.str();
				}
			
				gVaribleMap[ (yysemantic_stack_[(5) - (1)]) ] = AllocateVariable();
				I.mSourceLine = GetCurrentLineNumber( yylloc );
				I.SetOperation( EOPERATION_ASSIGN );
				I.SetDestinationAddress( gVaribleMap[ (yysemantic_stack_[(5) - (1)]) ] );
				I.SetLiteral( atoi((yysemantic_stack_[(5) - (3)]).c_str() ) );
				mInstructions.push_back( I );
				I.Clear();
				
			}
    break;

  case 35:

/* Line 678 of lalr1.cc  */
#line 608 "parser.y"
    {
				if (gVaribleMap.find((yysemantic_stack_[(3) - (1)])) != gVaribleMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << (yysemantic_stack_[(3) - (1)]) << "'\n";
					throw ret.str();
				}
				unsigned int ImmediateValue;
				std::string StringHex = (yysemantic_stack_[(3) - (3)]);
				std::stringstream ss;
				ss << std::hex << StringHex;
				ss >> ImmediateValue;
				gVaribleMap[ (yysemantic_stack_[(3) - (1)]) ] = AllocateVariable();
				I.mSourceLine = GetCurrentLineNumber( yylloc );
				I.SetOperation( EOPERATION_ASSIGN );
				I.SetDestinationAddress( gVaribleMap[ (yysemantic_stack_[(3) - (1)]) ] );
				I.SetLiteral( ImmediateValue );
				mInstructions.push_back( I );
				I.Clear();
			}
    break;

  case 36:

/* Line 678 of lalr1.cc  */
#line 630 "parser.y"
    {
				if (gVaribleMap.find((yysemantic_stack_[(1) - (1)])) != gVaribleMap.end())
				{
					std::ostringstream ret;
					ret << "Duplicated symbol '" << (yysemantic_stack_[(1) - (1)]) << "'\n";
					throw ret.str();
				}
			
				gVaribleMap[ (yysemantic_stack_[(1) - (1)]) ] = AllocateVariable();
			}
    break;



/* Line 678 of lalr1.cc  */
#line 1082 "parser.tab.c"
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
  const signed char Parser::yypact_ninf_ = -21;
  const signed char
  Parser::yypact_[] =
  {
        17,   -19,    12,    65,   -21,    16,     7,     4,   -21,   -14,
      22,   -21,    76,    73,    -3,    29,    34,    28,    76,   -21,
     -21,    34,   -19,   -21,    76,   -21,   -21,   -21,   -21,    46,
     -21,     9,   -21,    76,    40,    57,    39,    85,   -21,    47,
      78,   -21,    43,    76,   -21,    76,    76,    76,    76,    76,
      53,   -21,   -21,   -21,    20,    84,    86,    76,   -19,   -21,
     -21,   -21,   -21,   -21,   -21,   -21,   -21,    76,    76,    92,
     -21,    62,   -21,    63,    63,    17,    76,    -2,     0,   -21,
      87,   -21
  };

  /* YYDEFACT[S] -- default rule to reduce with in state S when YYTABLE
     doesn't specify something else to do.  Zero means the default is an
     error.  */
  const unsigned char
  Parser::yydefact_[] =
  {
         2,     0,     0,     0,    13,     0,     0,     0,     4,    36,
       0,     8,     0,     0,     0,     0,     0,     0,     0,     1,
       3,     0,     0,     6,     0,    27,    28,    29,    24,     0,
      19,    23,    26,     0,     0,     0,     0,     0,    15,     0,
      35,    33,     0,     0,    11,     0,     0,     0,     0,     0,
       0,    10,     9,    30,     0,     0,     0,     0,     0,    25,
      16,    18,    17,    20,    21,    22,    12,     0,     0,     0,
       5,     0,    34,    31,    32,     2,     0,     0,     0,    14,
       0,     7
  };

  /* YYPGOTO[NTERM-NUM].  */
  const signed char
  Parser::yypgoto_[] =
  {
       -21,    38,    -7,   -21,   -17,    59,    60,    -1,   -21,   -20
  };

  /* YYDEFGOTO[NTERM-NUM].  */
  const signed char
  Parser::yydefgoto_[] =
  {
        -1,     7,     8,    15,    29,    30,    31,    32,    55,    10
  };

  /* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
     positive, shift that token.  If negative, reduce the rule which
     number is the opposite.  If zero, do what YYDEFACT says.  */
  const signed char Parser::yytable_ninf_ = -1;
  const unsigned char
  Parser::yytable_[] =
  {
        20,    39,    41,     1,    19,     2,    21,    42,     9,     1,
      80,     2,    47,    48,    22,    37,    50,    79,    18,    54,
      40,    43,     1,    35,     2,     3,    45,    16,    67,     4,
       5,     3,    68,     6,    46,     4,     5,    11,    72,     6,
      71,    43,    49,    17,     3,    36,    45,    23,     4,     5,
      73,    74,     6,    38,    46,    24,    25,    26,    27,    78,
      59,    25,    26,    27,    43,    51,    28,    43,    43,    45,
      20,    44,    45,    45,    43,    57,    53,    46,    66,    45,
      46,    46,    52,    43,    43,    12,    13,    46,    45,    45,
      76,    14,    24,    33,    34,    56,    46,    46,    25,    26,
      27,    69,    60,    28,    61,    62,    58,    63,    64,    65,
      75,    70,    81,    77
  };

  /* YYCHECK.  */
  const unsigned char
  Parser::yycheck_[] =
  {
         7,    18,    22,     5,     0,     7,    20,    24,    27,     5,
      10,     7,     3,     4,    28,    16,    33,    19,    11,    36,
      21,    21,     5,    26,     7,    27,    26,    11,     8,    31,
      32,    27,    12,    35,    34,    31,    32,    25,    58,    35,
      57,    21,    33,    27,    27,    16,    26,    25,    31,    32,
      67,    68,    35,    25,    34,    16,    22,    23,    24,    76,
      17,    22,    23,    24,    21,    25,    27,    21,    21,    26,
      77,    25,    26,    26,    21,    28,    37,    34,    25,    26,
      34,    34,    25,    21,    21,    20,    21,    34,    26,    26,
      28,    26,    16,    20,    21,    10,    34,    34,    22,    23,
      24,    17,    43,    27,    45,    46,    28,    47,    48,    49,
      18,    25,    25,    75
  };

  /* STOS_[STATE-NUM] -- The (internal number of the) accessing
     symbol of state STATE-NUM.  */
  const unsigned char
  Parser::yystos_[] =
  {
         0,     5,     7,    27,    31,    32,    35,    39,    40,    27,
      47,    25,    20,    21,    26,    41,    11,    27,    11,     0,
      40,    20,    28,    25,    16,    22,    23,    24,    27,    42,
      43,    44,    45,    20,    21,    26,    16,    45,    25,    42,
      45,    47,    42,    21,    25,    26,    34,     3,     4,    33,
      42,    25,    25,    37,    42,    46,    10,    28,    28,    17,
      43,    43,    43,    44,    44,    44,    25,     8,    12,    17,
      25,    42,    47,    42,    42,    18,    28,    39,    42,    19,
      10,    25
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
     285,   286,   287,   288,   289,   290,   291,   292
  };
#endif

  /* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
  const unsigned char
  Parser::yyr1_[] =
  {
         0,    38,    39,    39,    39,    40,    40,    40,    40,    40,
      40,    40,    40,    41,    40,    40,    42,    42,    42,    42,
      43,    43,    43,    43,    44,    44,    44,    45,    45,    45,
      46,    46,    46,    47,    47,    47,    47
  };

  /* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
  const unsigned char
  Parser::yyr2_[] =
  {
         0,     2,     0,     2,     1,     5,     3,     9,     2,     4,
       4,     4,     5,     0,     8,     3,     3,     3,     3,     1,
       3,     3,     3,     1,     1,     3,     1,     1,     1,     1,
       1,     3,     3,     3,     5,     3,     1
  };

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
  /* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
     First, the terminals, then, starting at \a yyntokens_, nonterminals.  */
  const char*
  const Parser::yytname_[] =
  {
    "$end", "error", "$undefined", "SHL", "SHR", "SCALAR", "RETURN", "EXIT",
  "EQUAL", "NOT_EQUAL", "GREATER_THAN", "LESS_THAN", "LESS_OR_EQUAL_THAN",
  "GREATER_OR_EQUAL_THAN", "IF", "ELSE", "OPEN_ROUND_BRACE",
  "CLOSE_ROUND_BRACE", "OPEN_BRACE", "CLOSE_BRACE", "ASSIGN", "ADD",
  "DECCONST", "HEXCONST", "BINCONST", "EOS", "MINUS", "IDENTIFIER",
  "COMMA", "OPEN_SQUARE_BRACE", "CLOSE_SQUARE_BRACE", "WHILE", "START",
  "BITWISE_AND", "BITWISE_OR", "COPY_DATA_BLOCK", "COPY_CODE_BLOCK",
  "BLOCK_TRANSFER_IN_PROGRESS", "$accept", "statement_list", "statement",
  "$@1", "expression", "term", "factor", "constant", "boolean_expression",
  "scalar_list", 0
  };
#endif

#if YYDEBUG
  /* YYRHS -- A `-1'-separated list of the rules' RHS.  */
  const Parser::rhs_number_type
  Parser::yyrhs_[] =
  {
        39,     0,    -1,    -1,    39,    40,    -1,    40,    -1,    32,
      11,    45,    10,    25,    -1,     5,    47,    25,    -1,    35,
      11,    42,    28,    42,    28,    42,    10,    25,    -1,     7,
      25,    -1,    27,    26,    26,    25,    -1,    27,    21,    21,
      25,    -1,    27,    20,    42,    25,    -1,    27,    21,    20,
      42,    25,    -1,    -1,    31,    41,    16,    46,    17,    18,
      39,    19,    -1,    32,    27,    25,    -1,    42,    21,    43,
      -1,    42,    34,    43,    -1,    42,    26,    43,    -1,    43,
      -1,    44,     3,    44,    -1,    44,     4,    44,    -1,    44,
      33,    44,    -1,    44,    -1,    27,    -1,    16,    42,    17,
      -1,    45,    -1,    22,    -1,    23,    -1,    24,    -1,    37,
      -1,    42,     8,    42,    -1,    42,    12,    42,    -1,    27,
      28,    47,    -1,    27,    20,    45,    28,    47,    -1,    27,
      20,    45,    -1,    27,    -1
  };

  /* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
     YYRHS.  */
  const unsigned char
  Parser::yyprhs_[] =
  {
         0,     0,     3,     4,     7,     9,    15,    19,    29,    32,
      37,    42,    47,    53,    54,    63,    67,    71,    75,    79,
      81,    85,    89,    93,    95,    97,   101,   103,   105,   107,
     109,   111,   115,   119,   123,   129,   133
  };

  /* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
  const unsigned short int
  Parser::yyrline_[] =
  {
         0,   148,   148,   150,   152,   157,   176,   178,   202,   214,
     236,   259,   272,   284,   284,   305,   315,   333,   348,   363,
     371,   387,   402,   417,   425,   430,   435,   464,   477,   488,
     503,   534,   554,   576,   588,   607,   629
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
      35,    36,    37
    };
    if ((unsigned int) t <= yyuser_token_number_max_)
      return translate_table[t];
    else
      return yyundef_token_;
  }

  const int Parser::yyeof_ = 0;
  const int Parser::yylast_ = 113;
  const int Parser::yynnts_ = 10;
  const int Parser::yyempty_ = -2;
  const int Parser::yyfinal_ = 19;
  const int Parser::yyterror_ = 1;
  const int Parser::yyerrcode_ = 256;
  const int Parser::yyntokens_ = 38;

  const unsigned int Parser::yyuser_token_number_max_ = 292;
  const Parser::token_number_type Parser::yyundef_token_ = 2;


/* Line 1054 of lalr1.cc  */
#line 28 "parser.y"
} // Theia

/* Line 1054 of lalr1.cc  */
#line 1574 "parser.tab.c"


/* Line 1056 of lalr1.cc  */
#line 643 "parser.y"




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


