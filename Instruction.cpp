
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
//----------------------------------------------------------------
#define OP_SIZE        16            

#define OP_RNG         63,48         
#define OP_BIT_IMM     15
#define OP_SCALE_RNG   14,11
#define OP_EOF         10
#define OP_BRANCH      9
#define OP_BTYPE_RNG   8,6

#define OP_CODE_RNG    2,0

#define DST_ADDR            7,0
#define DST_WE_RNG      10,8
#define DST_WE_Z        8
#define DST_WE_Y        9
#define DST_WE_X        10

#define DST_ZERO            13
#define SRC1_DISPLACED      12
#define SRC0_DISPLACED      11

#define DST_RNG             47,34
#define SCR1_RNG            33,17
#define SRC0_RNG            16,0
// Source0 structure
#define SRC0_SIZE           17
#define SRC0_RNG            16,0
#define SRC0_ADDR_SIZE      8
#define SRC0_SIGN_RNG       16,14
#define SRC0_SIGN_X         16
#define SRC0_SIGN_Y         15
#define SRC0_SIGN_Z         14
#define SRC0_SWZX_RNG       13,8  
#define SRC0_SWZ_X          13,12  
#define SRC0_SWZ_Y          11,10
#define SRC0_SWZ_Z          9,8
#define SRC0_ADDR_RNG       7,0
// Source1 structure 
#define SRC1_SIZE           17
#define SRC1_RNG            33,17
#define SRC1_ADDR_SIZE      8
#define SRC1_SIGN_RNG       16,14
#define SRC1_SIGN_X         16
#define SRC1_SIGN_Y         15
#define SRC1_SIGN_Z         14
#define SRC1_SWZX_RNG       13,8
#define SRC1_SWZ_X          13,12  
#define SRC1_SWZ_Y          11,10
#define SRC1_SWZ_Z          9,8
#define SRC1_ADDR_RNG       7,0


std::string gOperationStrings[] = 
{
	"NOP",
	"ADD",
	"DIV",
	"MUL",
	"SQRT"
};

std::string gBranchTypeStrings[] =
{
"ALWAYS",             
"ZERO",            
"NOT_ZERO",        
"SIGN",            
"NOT_SIGN",        
"ZERO_OR_SIGN",    
"ZERO_OR_NOT_SIGN" 
};

std::string gSwizzleXTypeStrings[] =
{
"x",             
"z",            
"y"        
};

std::string gSwizzleYTypeStrings[] =
{
"y",             
"z",            
"x"        
};

std::string gSwizzleZTypeStrings[] =
{
"z",             
"y",            
"x"        
};

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
Instruction::Instruction()
{
mDestinationIsSymbol = false;
mSourceLine = -1;
}
//--------------------------------------------------------------
Instruction::~Instruction()
{
	
}
//--------------------------------------------------------------
void Instruction::SetFields( unsigned int aOperation, unsigned int aDestination, unsigned int aSrc1, unsigned int aSrc0 )
{
	SetbitRange<16>(mOperation,16,0,aOperation);
	SetbitRange<14>(mDestination,14,0,aDestination);
	SetbitRange<17>(mSource1,17,0,aSrc1);
	SetbitRange<17>(mSource0,17,0,aSrc0);
}
//--------------------------------------------------------------
void Instruction::Clear()
{
	mOperation.reset();
	mDestination.reset();
	mSource1.reset();
	mSource0.reset();
	mComment.clear();
	mDestinationIsSymbol = false;
	mSourceLine = -1;
}
//--------------------------------------------------------------
std::string Instruction::PrintHex()
{
	std::string  I;
	if (mDestinationIsSymbol)
	{
		I = PrintBin();
	} else
		I =  BinStringToHexString( PrintBin() );
	//mOutputFile << I << "\n";
	return I;
	
}
//--------------------------------------------------------------
std::string Instruction::PrintAssembly()
{

	unsigned int Scale = GetbitRange<16>(mOperation,OP_SCALE_RNG);
	std::bitset<4> bScale( Scale );
	
	std::ostringstream oss,oss2;
			
	oss << std::hex << mOperation.to_ulong() << " ";
	if (mDestinationIsSymbol)
		oss << mDestinationSymbol;
	else
		oss << mDestination.to_ulong();
		
	oss << " " << mSource1.to_ulong() << " " << mSource0.to_ulong();

	std::string tmpString = oss.str();
	while (tmpString.size() < 50) tmpString.push_back(' ');
	
	oss2 << tmpString << "//";
			
	oss2 << mOperationString << " ";
	if (mOperation[OP_BRANCH])
	{
		
		oss2 << "<BRANCH." << gBranchTypeStrings[ GetbitRange<16>(mOperation,OP_BTYPE_RNG) ] << "> ";
	}
		
	if (mDestinationIsSymbol)
		oss2 << mDestinationSymbol;
	else
	{	
		if (bScale[2] && bScale[3])
			oss2 << "(unscaled) ";
		else if (bScale[2])
			oss2 << "(scaled) ";
	
		if (mOperation[OP_BIT_IMM])
		{
			if (mDestination[SRC0_DISPLACED])
				oss2 << ((mOperation[OP_BRANCH])?"@*R[":"R[") <<  GetbitRange<14>(mDestination,DST_ADDR) << "+ offset]";
			else
				oss2 << ((mOperation[OP_BRANCH])?"@*R":"R") <<  GetbitRange<14>(mDestination,DST_ADDR);
		}
		else
		{
			if (mDestination[DST_ZERO])
				oss2 << ((mOperation[OP_BRANCH])?"@[":"R[") <<  GetbitRange<14>(mDestination,DST_ADDR) << "+ offset]";
			else		
				oss2 << ((mOperation[OP_BRANCH])?"@":"R") <<  GetbitRange<14>(mDestination,DST_ADDR);
		}	
	}
	//Now print the write channels
	oss2 << ".";
	if (mDestination[DST_WE_X])
		oss2 << "x";
	else
		oss2 << "_";	
		
	if (mDestination[DST_WE_Y])
		oss2 << "y";
	else
		oss2 << "_";	

	if (mDestination[DST_WE_Z])
		oss2 << "z";
	else
		oss2 << "_";			
		
	oss2 << " ";	
	
	if (mOperation[OP_BIT_IMM])
	{
		oss2 << std::hex << (mSource0.to_ulong() + (mSource1.to_ulong() << 17));
	} else {
		
		
		if (bScale[0] && bScale[3])
			oss2 << "(unscaled) ";
		else if (bScale[0])
			oss2 << "(scaled) ";
			
		
		oss2 << "R";
		if (mDestination[SRC1_DISPLACED])
			oss2 << "[" << GetbitRange<17>(mSource1,SRC1_ADDR_RNG) << " + offset]";
		else
			oss2 << GetbitRange<17>(mSource1,SRC1_ADDR_RNG);
			
		oss2 << "."
		
		<< ((mSource1[SRC1_SIGN_X]) ? "-":"") << gSwizzleXTypeStrings[ GetbitRange<17>(mSource1,SRC1_SWZ_X) ]
		<< ((mSource1[SRC1_SIGN_Y]) ? "-":"") <<gSwizzleYTypeStrings[ GetbitRange<17>(mSource1,SRC1_SWZ_Y) ]
		<< ((mSource1[SRC1_SIGN_Z]) ? "-":"") <<gSwizzleZTypeStrings[ GetbitRange<17>(mSource1,SRC1_SWZ_Z) ] << " ";
		
		
		if (bScale[1] && bScale[3])
			oss2 << "(unscaled) ";
		else if (bScale[1])
			oss2 << "(scaled) ";
				
		oss2 << "R";
		if (mDestination[SRC0_DISPLACED])
			oss2 << "[" << GetbitRange<17>(mSource0,SRC0_ADDR_RNG) << " + offset]";
		else
			oss2 << GetbitRange<17>(mSource0,SRC0_ADDR_RNG);
			
		oss2 << "."
		
		<< ((mSource0[SRC0_SIGN_X]) ? "-":"") << gSwizzleXTypeStrings[ GetbitRange<17>(mSource0,SRC0_SWZ_X) ]
		<< ((mSource0[SRC0_SIGN_Y]) ? "-":"") << gSwizzleYTypeStrings[ GetbitRange<17>(mSource0,SRC0_SWZ_Y) ]
		<< ((mSource0[SRC0_SIGN_Z]) ? "-":"") << gSwizzleZTypeStrings[ GetbitRange<17>(mSource0,SRC0_SWZ_Z) ];
	}
	
	
	return oss2.str();
}
//--------------------------------------------------------------
void Instruction::PrintFields()
{
	if (mOperation[OP_BRANCH])
	{
		//std::cout << "BRANCH to " << mDestination.to_ulong() << "\n";
	}
	//std::cout << "Imm      :" << mOperation[OP_BIT_IMM] << "\n";
	//std::cout << "Branch   :" << mOperation[OP_BRANCH] << "\n";
	//std::cout << "WE.x     :" << mDestination[DST_WE_X] << "\n";
	//std::cout << "WE.y     :" << mDestination[DST_WE_Y] << "\n";
	//std::cout << "WE.z     :" << mDestination[DST_WE_Z] << "\n";
	//std::cout << "EOF      :" << mOperation[OP_EOF] << "\n";
	
	//std::cout << "OP       :" << mOperation.to_string() << "\n";
	//if (mDestinationIsSymbol)
		//std::cout << "DST      :" << mDestinationSymbol << "\n";
	//else
		//std::cout << "DST      :" << mDestination.to_string() << "\n";
	//std::cout << "SRC1     :" << mSource1.to_string() << "\n";
	//std::cout << "SRC0     :" << mSource0.to_string() << "\n";
}
//--------------------------------------------------------------
std::string Instruction::PrintBin()
{
	
	std::bitset<64> Bitset;
	
	
	SetbitRange<64>(Bitset,OP_RNG,mOperation.to_ulong());
	SetbitRange<64>(Bitset,DST_RNG,mDestination.to_ulong());
	SetbitRange<64>(Bitset,SRC1_RNG,mSource1.to_ulong());
	SetbitRange<64>(Bitset,SRC0_RNG,mSource0.to_ulong());
	return Bitset.to_string();
	
}
//--------------------------------------------------------------
void Instruction::SetEofFlag( bool aEof )
{
	mOperation[ OP_EOF ] = aEof;
}
//--------------------------------------------------------------
void Instruction::SetCode( EOPERATION aCode )
{
	SetbitRange<16>(mOperation,OP_CODE_RNG,aCode);
	mOperationString = gOperationStrings[aCode];
}
//--------------------------------------------------------------
void Instruction::SetImm( unsigned int aLiteral )
{
	
	
	mOperation[OP_BIT_IMM] = true;
	mSource0 = aLiteral;
	mSource1 = (aLiteral >> SOURCE0_SIZE);
}
//--------------------------------------------------------------
/*void SetAddressingMode( EADDRESSINGTYPE aAddressMode )
{
	std::bitset<4> AddressingMode( aAddressMode );
	AddressingMode[3] = mOperation[OP_BIT_IMM] ;
	
	switch ( AddressingMode )
	{
		case EDIRECT_ADDRESSING:
			SetDestZero( false );
			SetSrc1Displace( false );
			SetSrc0Displace( false );
			break;
		case EDIRECT_DISP_SRC0:
			SetDestZero( false );
			SetSrc1Displace( false );
			SetSrc0Displace( true );
			break;
		EDIRECT_DISP_SRC1:
			SetDestZero( false );
			SetSrc1Displace( true );
			SetSrc0Displace( false );
			break;
		EDIRECT_DISP_SRC1_SRC0:
			SetDestZero( false );
			SetSrc1Displace( true );
			SetSrc0Displace( true );
			break;
		EDIRECT_DISP_DST:
			SetDestZero( true );
			SetSrc1Displace( false );
			SetSrc0Displace( false );
			break;
		EDIRECT_DISP_DST_SRC0:
			SetDestZero( true );
			SetSrc1Displace( false );
			SetSrc0Displace( true );
			break;
		case EDIRECT_DISP_DST_SRC1:
			SetDestZero( true );
			SetSrc1Displace( true );
			SetSrc0Displace( false );
			break;
		case EDIRECT_DISP_DST_SRC1_SRC0:
			SetDestZero( true );
			SetSrc1Displace( true );
			SetSrc0Displace( true );
			break;
		EDIRECT_IMM:				//R[DSTINDEX ] = IMMV op R[DSTINDEX]
			SetDestZero( false );
			SetSrc1Displace( false );
			SetSrc0Displace( false );
			break;
		EDIRECT_IMM_ZERO:			//R[DSTINDEX ] = IMMV op 32'b0
			SetDestZero( true );
			SetSrc1Displace( false );
			SetSrc0Displace( false );
			break;
		EDIRECT_IMM_DISPALCE:		//R[DSTINDEX + offset] = IMMV op R[DSTINDEX]
			SetDestZero( false );
			SetSrc1Displace( false );
			SetSrc0Displace( true );
			break;
		EDIRECT_IMM_DISPALCE_ZERO: //R[DSTINDEX + offset] = IMMV op 32'b0
			SetDestZero( true );
			SetSrc1Displace( false );
			SetSrc0Displace( true );
			break;
		EINDIRECT_IMM_DISP: 		// DST = R[ DSTINDEX ] + OFFSET
			SetDestZero( false );
			SetSrc1Displace( false );
			SetSrc0Displace( false );
			break;
		break;
		EINDIRECT_IMM_DISP_ZERO:
		break;
		EINDIRECT_NO_IMM:
		break;
		EINDIRECT_NO_IMM_DISP:
		break;
	}
}*/
//--------------------------------------------------------------
void Instruction::SetDestZero(  bool aZero )
{
	mDestination[DST_ZERO] = aZero;
}
//--------------------------------------------------------------
void Instruction::SetSrc0Displace( bool aDisplace )
{
	mDestination[SRC0_DISPLACED] = aDisplace;
}
//--------------------------------------------------------------
void Instruction::SetSrc1Displace( bool aDisplace )
{
	mDestination[SRC1_DISPLACED] = aDisplace;
}
//--------------------------------------------------------------
void Instruction::SetBranchFlag( bool aBranch )
{
	mOperation[OP_BRANCH] = aBranch;
}
//--------------------------------------------------------------
void Instruction::SetBranchType( EBRANCHTYPE aBranchType )
{
	SetbitRange<16>(mOperation,OP_BTYPE_RNG,aBranchType);
}
//--------------------------------------------------------------
void Instruction::ClearWriteChannel()
{

	mDestination[DST_WE_X] = false;
	mDestination[DST_WE_Y] = false;
	mDestination[DST_WE_Z] = false;
}
//--------------------------------------------------------------
void Instruction::SetWriteChannel( ECHANNEL aChannel )
{

	if (aChannel == ECHANNEL_XYZ)
	{
		mDestination[DST_WE_X] = true;
		mDestination[DST_WE_Y] = true;
		mDestination[DST_WE_Z] = true;
		return;
	}

	switch ( aChannel )
	{
		case ECHANNEL_X:
		mDestination[DST_WE_X] = true;
		break;
		case ECHANNEL_Y:
		mDestination[DST_WE_Y] = true;
		break;
		case ECHANNEL_Z:
		mDestination[DST_WE_Z] = true;
		break;
	}

}
//--------------------------------------------------------------
void Instruction::SetDestinationAddress( unsigned int aAddress )
{
	
	SetbitRange<14>(mDestination,DST_ADDR,aAddress);
	
}
//--------------------------------------------------------------
void Instruction::SetDestinationSymbol( std::string aSymbol )
{
	mDestinationIsSymbol = true;
	mDestinationSymbol = aSymbol;
}
//--------------------------------------------------------------
void Instruction::SetSrc1SignX( bool aSign )
{
	mSource1[SRC1_SIGN_X] = aSign;
}
//--------------------------------------------------------------
void Instruction::SetSrc1SignY( bool aSign )
{
	mSource1[SRC1_SIGN_Y] = aSign;
}
//--------------------------------------------------------------
void Instruction::SetSrc1SignZ( bool aSign )
{
	mSource1[SRC1_SIGN_Z] = aSign;
}
//--------------------------------------------------------------
void Instruction::SetSrc1SwizzleX(ESWIZZLE_X aChannel)
{
	SetbitRange<17>(mSource1,SRC1_SWZ_X,aChannel);

}
//--------------------------------------------------------------
void Instruction::SetSrc1SwizzleY(ESWIZZLE_Y aChannel)
{
	SetbitRange<17>(mSource1,SRC1_SWZ_Y,aChannel);
	
}
//--------------------------------------------------------------
void Instruction::SetSrc1SwizzleZ(ESWIZZLE_Z aChannel)
{
	SetbitRange<17>(mSource1,SRC1_SWZ_Z,aChannel);

}
//--------------------------------------------------------------
void Instruction::SetSrc1Address(unsigned int aAddress )
{
	SetbitRange<17>(mSource1,SRC1_ADDR_RNG,aAddress);
}
//--------------------------------------------------------------
void Instruction::SetSrc1Rotation( EROTATION aRotation )
{
	unsigned int OldVal = GetbitRange<16>(mOperation,OP_SCALE_RNG);
	
	SetbitRange<16>(mOperation,OP_SCALE_RNG,(OldVal | aRotation) );
}
//--------------------------------------------------------------
void Instruction::SetSrc0Rotation( EROTATION aRotation )
{
	unsigned int OldVal = GetbitRange<16>(mOperation,OP_SCALE_RNG);
	
	SetbitRange<16>(mOperation,OP_SCALE_RNG,(OldVal | aRotation ) );
}
//--------------------------------------------------------------
void Instruction::SetSrc0SignX( bool aSign )
{
	mSource0[SRC0_SIGN_X] = aSign;
}
//--------------------------------------------------------------
void Instruction::SetSrc0SignY( bool aSign )
{
	mSource0[SRC0_SIGN_Y] = aSign;
}
//--------------------------------------------------------------
void Instruction::SetSrc0SignZ( bool aSign )
{
	mSource0[SRC0_SIGN_Z] = aSign;
}
//--------------------------------------------------------------
void Instruction::SetSrc0SwizzleX(ESWIZZLE_X aChannel)
{
SetbitRange<17>(mSource0,SRC0_SWZ_X,aChannel);

}
//--------------------------------------------------------------
void Instruction::SetSrc0SwizzleY(ESWIZZLE_Y aChannel)
{
	SetbitRange<17>(mSource0,SRC0_SWZ_Y,aChannel);

	
}
//--------------------------------------------------------------
void Instruction::SetSrc0SwizzleZ(ESWIZZLE_Z aChannel)
{
SetbitRange<17>(mSource0,SRC0_SWZ_Z,aChannel);

}
//--------------------------------------------------------------
void Instruction::SetSrc0Address(unsigned int aAddress )
{
	SetbitRange<17>(mSource0,SRC0_ADDR_RNG,aAddress);
}
//--------------------------------------------------------------
 std::bitset<DESTINATION_SIZE> Instruction::GetDestination( )
{
	return mDestination;
}
//--------------------------------------------------------------
ECHANNEL Instruction::GetWriteChannel(  )
{
	//std::cout << "Ecahhhannel " << GetbitRange<DESTINATION_SIZE>(mDestination,DST_WE_RNG) << "\n";
	
	return ((ECHANNEL)GetbitRange<DESTINATION_SIZE>(mDestination,DST_WE_RNG));
}
//--------------------------------------------------------------
/*
void Instruction::SetDestination( std::bitset<DESTINATION_SIZE> aDestination )
{
	mDestination = aDestination;
}
*/
//--------------------------------------------------------------