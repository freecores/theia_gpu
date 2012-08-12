#ifndef INSTRUCTION_H
#define INSTRUCTION_H

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

#include <bitset>
#include <string>
#include <fstream>

#define OPERATION_SIZE 16
#define DESTINATION_SIZE 14
#define SOURCE1_SIZE 17
#define SOURCE0_SIZE 17
#define RETURN_VALUE_REGISTER   1
#define RETURN_ADDRESS_REGISTER 2//31
#define SPR_CONTROL_REGISTER    3  //30
#define SPR_CONTROL_REGISTER0   2

//----------------------------------------------------------------------------------
//#define DEBUG 1
//Use this macro instead of std::cout, it is easier to turn off
class NullStream 
{
    public:
    NullStream() { }
    template<typename T> NullStream& operator<<(T const&) { return *this; }
};


#ifdef DEBUG
	#define DCOUT std::cout
#else
	#define DCOUT NullStream()
#endif
//----------------------------------------------------------------------------------



typedef enum
{
	ECHANNEL_X=4,
	ECHANNEL_Y=2,
	ECHANNEL_Z=1,
	ECHANNEL_XYZ=7
	
} ECHANNEL;

typedef enum
{
	SWX_X=0,
	SWX_Z,
	SWX_Y
} ESWIZZLE_X;

typedef enum
{
	SWY_Y=0,
	SWY_Z,
	SWY_X
} ESWIZZLE_Y;

typedef enum
{
	SWZ_Z=0,
	SWZ_Y,
	SWZ_X
} ESWIZZLE_Z;

typedef enum
{
	EOPERATION_NOP=0,
	EOPERATION_ADD=1,
	EOPERATION_DIV,
	EOPERATION_MUL,
	EOPERATION_SQRT,
	EOPERATION_LOGIC,
	EOPERATION_OUT
	
} EOPERATION;


typedef enum
{
ELOGIC_AND = 0,
ELOGIC_OR,
ELOGIC_NOT,
ELOGIC_SHL,
ELOGIC_SHR

}	ELOGIC_OPERATION;

typedef enum
{
	EROT_NONE = 0,
	EROT_SRC0_LEFT =1,
	EROT_SRC1_LEFT =2,
	EROT_SRC1_SCR0_LEFT = 3,
	EROT_SRC0_RIGHT=9,
	EROT_SRC1_RIGHT=10,
	EROT_SRC1_SRC0_RIGHT=11,
	EROT_RESULT_RIGHT=12
} EROTATION;

typedef enum
{
EBRANCH_ALWAYS=0,             
EBRANCH_IF_ZERO,            
EBRANCH_IF_NOT_ZERO,        
EBRANCH_IF_SIGN,            
EBRANCH_IF_NOT_SIGN,        
EBRANCH_IF_ZERO_OR_SIGN,    
EBRANCH_IF_ZERO_OR_NOT_SIGN 
	
} EBRANCHTYPE;

class Instruction
{
  public:
	Instruction();
	~Instruction();
  public:
	std::string PrintHex();
	std::string PrintBin();
	std::string PrintAssembly();
	void PrintFields();
	std::string PrintHex32();
	void Clear( void );
	bool mBisonFlagTrippleConstAssign;
	
  public:
    void SetFields( unsigned int aOperation, unsigned int aDestination, unsigned int aSrc1, unsigned int aSrc0 );
	void SetCode( EOPERATION aCode );
	void SetImm( unsigned int aLiteral );
	void SetImmBit( bool aImm );
	void SetDestZero( bool aZero );
	void SetSrc0Displace( bool aDisplace );
	void SetSrc1Displace( bool aDisplace );
	void SetLogicOperation(ELOGIC_OPERATION aOperation );
	void SetAddressingMode( bool, bool, bool  );
	
	void SetEofFlag( bool aEof );
	void SetWriteChannel( ECHANNEL aChannel );
	void ClearWriteChannel();
	void SetDestinationAddress( unsigned int aDestinationAddress );
	void SetDestination( std::bitset<DESTINATION_SIZE> aDestination );
	void SetDestinationSymbol( std::string aSymbol );
	void SetBranchFlag( bool aBranch );
	void SetBranchType( EBRANCHTYPE aType );
	//Source 1
	void SetSrc1SignX( bool aSign );
	void SetSrc1SignY( bool aSign );
	void SetSrc1SignZ( bool aSign );
	void SetSrc1SwizzleX( ESWIZZLE_X aChannel );
	void SetSrc1SwizzleY( ESWIZZLE_Y aChannel );
	void SetSrc1SwizzleZ( ESWIZZLE_Z aChannel );
	void SetSrc1Address( unsigned int aAddress );
	void SetSrc1Rotation( EROTATION aRotation );
	//Source 0
	void SetSrc0SignX( bool aSign );
	void SetSrc0SignY( bool aSign );
	void SetSrc0SignZ( bool aSign );
	void SetSrc0SwizzleX( ESWIZZLE_X aChannel );
	void SetSrc0SwizzleY( ESWIZZLE_Y aChannel );
	void SetSrc0SwizzleZ( ESWIZZLE_Z aChannel );
	void SetSrc0Address( unsigned int aAddress );
	void SetSrc0Rotation( EROTATION aRotation );
	
	std::bitset<DESTINATION_SIZE> GetDestination( void );
	unsigned int GetOperation( void );
	unsigned int GetAddressingMode( void );
	unsigned int GetDestinationAddress( void );
	bool         GetImm( void); 
	ECHANNEL	GetWriteChannel( void );
 
  private:
	std::bitset<OPERATION_SIZE>   mOperation;
	std::string                   mOperationString;
	std::bitset<DESTINATION_SIZE> mDestination;
	std::bitset<SOURCE1_SIZE>     mSource1;
	std::bitset<SOURCE0_SIZE>     mSource0;
	unsigned int                  mLiteral;
	bool                          mDestinationIsSymbol;
	std::string                   mDestinationSymbol;
public:	
	int                     	  mSourceLine;
	std::string                   mComment;
  private:	
	//std::ofstream                 mOutputFile;
};

#endif