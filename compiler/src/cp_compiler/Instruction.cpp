
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


#include "Instruction.h"
#include <sstream>
#include <iostream>
#include <iomanip>


//--------------------------------------------------------------
template <std::size_t N > 
inline void SetbitRange( std::bitset<N> & aBitset , unsigned int aEnd, unsigned int aStart, unsigned int aValue)
{
	unsigned long mask = 1;
	unsigned long result = 0;
	for (int i = aStart; i <= aEnd; ++i) 
	{
		aBitset[i] =  ( mask & aValue );
		mask <<= 1;
	}

}
//--------------------------------------------------------------
template <std::size_t N > 
inline unsigned int GetbitRange( std::bitset<N> & aBitset , unsigned int aEnd, unsigned int aStart)
{
	
	unsigned long Result = 0;
	int j = 0;
	for (int i = aStart; i <= aEnd; ++i) 
	{
		Result |=  ( aBitset[i] << j++);
		
	}

	return Result;

}
//--------------------------------------------------------------
const char lookuparrbin2hex[] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

char convert_bin2hex(std::string bits)
{
	unsigned int result = 0;
	unsigned int shifter0 = 0;
	unsigned int shifter1 = 1;

	for(int n=0; n < bits.length(); n++)
	{
		result <<= 1; //shift result to the left by 1
		if(bits[n] == '1') result = (result | shifter1);
		else result = (result | shifter0);
	}
	return lookuparrbin2hex[result];
}
//--------------------------------------------------------------

std::string BinStringToHexString(std::string aBinString )
{
	std::string endresult = "";
	for(int i = 0; i < aBinString.length(); i = i+4)
	{
		endresult += convert_bin2hex(aBinString.substr(i,4));
	}
	return endresult;
}

//--------------------------------------------------------------
CControlInstruction::CControlInstruction()
{

mSourceLine = -1;
}
//--------------------------------------------------------------
CControlInstruction::~CControlInstruction()
{
	
}

//--------------------------------------------------------------
void CControlInstruction::Clear()
{
	mOperation = 0;
	mDestination = 0;
	mSource1 = 0;
	mSource0 = 0;
	mComment.clear();
	mCopyDestinationAddress = 0;
	mCopySourceAddress = 0;
	mCopyDestinationId = 0;
	mCopySize = 0;
	mSourceLine = -1;
}

//--------------------------------------------------------------
void CControlInstruction::SetDestinationAddress( unsigned int aAddress )
{
	
	mDestination = aAddress;
	
}
//--------------------------------------------------------------
void CControlInstruction::SetSrc1Address(unsigned int aAddress )
{
	mSource1 = aAddress;
}
//--------------------------------------------------------------
void CControlInstruction::SetSrc0Address(unsigned int aAddress )
{
	mSource0 = aAddress;
}
//--------------------------------------------------------------
void CControlInstruction::SetOperation( EOPERATION aCode )
{
	mOperation = aCode;
}
//--------------------------------------------------------------
void CControlInstruction::SetCopyDestinationAddress( unsigned int aAddress )
{
	mCopyDestinationAddress = aAddress;
}
//--------------------------------------------------------------
void CControlInstruction::SetCopySourceAddress( unsigned int aAddress )
{
	mCopySourceAddress = aAddress;
}
//--------------------------------------------------------------
void CControlInstruction::SetCopyDestinationId( unsigned int aId )
{
	mCopyDestinationId = aId;
}
//--------------------------------------------------------------

void CControlInstruction::SetCopySize( unsigned int aSize )
{
	mCopyDestinationAddress = mCopyDestinationAddress;
}

//--------------------------------------------------------------
void CControlInstruction::SetLiteral(  unsigned int aLiteral )
{
	mLiteral = aLiteral;
}
//--------------------------------------------------------------
std::string OperationStrings[] =
{
	"NOP",
	"DELIVERCOMMAND",
	"ADD",
	"SUB",
	"AND",
	"OR",
	"BRANCH",
	"BEQ",
	"BNE",
	"BG",
	"BL",
	"BGE",
	"BLE",
	"ASSIGN",
	"COPYBLOCK",
	"EXIT",
	"NOT",
	"SHL",
	"SHR"
	
};

//--------------------------------------------------------------
std::string CControlInstruction::PrintAssembly( void )
{
	std::ostringstream oss;
	std::bitset<INSTRUCTION_SIZE> Bitset;
	 
	
	SetbitRange<INSTRUCTION_SIZE>( Bitset ,OP_RNG , mOperation);
	switch (mOperation)
	{
		case EOPERATION_COPYBLOCK:
		{
		SetbitRange<INSTRUCTION_SIZE>( Bitset ,COPY_DST_RNG,  mCopyDestinationAddress);
		SetbitRange<INSTRUCTION_SIZE>( Bitset ,COPY_SRC_RNG,  mCopySourceAddress);
		SetbitRange<INSTRUCTION_SIZE>( Bitset ,COPY_DSTID_RNG,  mCopyDestinationId);
		//SetbitRange<INSTRUCTION_SIZE>( Bitset ,COPY_SIZE_RNG,  mCopyDestinationAddress);
		
		/*std::bitset<32> BitsetWord32_0( GetbitRange<INSTRUCTION_SIZE>(Bitset,31,0) );
		std::bitset<32> BitsetWord32_1( GetbitRange<INSTRUCTION_SIZE>(Bitset,63,32) );
		std::bitset<32> BitsetWord32_2( GetbitRange<INSTRUCTION_SIZE>(Bitset,84,64) );*/
		
		//oss << std::hex << BitsetWord32_2 << " " << BitsetWord32_1 << " "<< BitsetWord32_0;
		oss << std::hex << Bitset.to_ulong();
		oss << "\t\t//" << OperationStrings[mOperation];
		oss << std::dec  << " DstId: R"  << mCopyDestinationId << " SrcOffset: R" << mCopySourceAddress << " DstOffsetAndLen: R" << mCopyDestinationAddress;
		}
		break;
		case EOPERATION_ASSIGN:
		{
		
		SetbitRange<INSTRUCTION_SIZE>( Bitset ,DST_RNG , mDestination);
		SetbitRange<INSTRUCTION_SIZE>( Bitset ,LITERAL_RNG , mLiteral);
		//SetbitRange<INSTRUCTION_SIZE>( Bitset ,63,32 , 0);
		
		/*std::bitset<32> BitsetWord32_0( GetbitRange<INSTRUCTION_SIZE>(Bitset,31,0) );
		std::bitset<32> BitsetWord32_1( GetbitRange<INSTRUCTION_SIZE>(Bitset,63,32) );
		std::bitset<32> BitsetWord32_2( GetbitRange<INSTRUCTION_SIZE>(Bitset,84,64) );
		
		oss << std::hex << BitsetWord32_2 << " " << BitsetWord32_1 << " "<< BitsetWord32_0;*/
		oss << std::hex << Bitset.to_ulong();
		oss << "\t\t//" << OperationStrings[mOperation];
		oss << std::dec << " R"  << mDestination << " I(" << mLiteral << " )";
		}
		break;
		default:
		{
		SetbitRange<INSTRUCTION_SIZE>( Bitset ,SRC0_RNG, mSource0);
		SetbitRange<INSTRUCTION_SIZE>( Bitset ,SRC1_RNG, mSource1);
		SetbitRange<INSTRUCTION_SIZE>( Bitset ,DST_RNG , mDestination);
		/*
		std::bitset<32> BitsetWord32_0( GetbitRange<INSTRUCTION_SIZE>(Bitset,31,0) );
		std::bitset<32> BitsetWord32_1( GetbitRange<INSTRUCTION_SIZE>(Bitset,63,32) );
		std::bitset<32> BitsetWord32_2( GetbitRange<INSTRUCTION_SIZE>(Bitset,84,64) );
		
		
		oss << std::hex << BitsetWord32_2 << " " << BitsetWord32_1 << " "<< BitsetWord32_0;*/
		oss << std::hex << Bitset.to_ulong();
		oss << "\t\t//" << OperationStrings[mOperation];
		oss << std::dec << " R"  << mDestination << " R" << mSource1 << " R" << mSource0;
		}
	}
	
	return oss.str();
}
//--------------------------------------------------------------