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

#define INSTRUCTION_SIZE 32
#define OPERATION_SIZE   8
#define DESTINATION_SIZE 4
#define SOURCE1_SIZE     8
#define SOURCE0_SIZE     8
#define SRC_ADDR_SIZE    8
#define DST_ADDR_SIZE    8
#define DST_ID_SIZE      4
#define COPY_SIZE        8


#define SRC0_RNG 7,0
#define SRC1_RNG 15,8
#define DST_RNG  23,16
#define OP_RNG   31,24
#define COPY_DST_RNG 7,0
#define COPY_SRC_RNG 15,8
#define COPY_DSTID_RNG 23,16
//#define COPY_SIZE_RNG 23,20

#define LITERAL_RNG 15,0

#define STATUS_REG 2
#define BLOCK_DST_REG 3
////////////////////////////////////////////////////////

typedef enum
{
	EOPERATION_NOP=0,
	EOPERATION_DELIVERCOMMAND,
	EOPERATION_ADD,
	EOPERATION_SUB,
	EOPERATION_AND,
	EOPERATION_OR,
	EOPERATION_BRANCH,
	EOPERATION_BEQ,
	EOPERATION_BNE,
	EOPERATION_BG,
	EOPERATION_BL,
	EOPERATION_BGE,
	EOPERATION_BLE,
	EOPERATION_ASSIGN,
	EOPERATION_COPYBLOCK,
	EOPERATION_EXIT,
	EOPERATION_NOT,
	EOPERATION_SHL,
	EOPERATION_SHR
	
} EOPERATION;


typedef enum
{
	VP_COMMAND_START_MAIN_THREAD = 0,
	VP_COMMAND_STOP_MAIN_THREAD = 1
} EVPCOMMAD;

class CControlInstruction
{
  public:
	CControlInstruction();
	~CControlInstruction();
  public:
	
	void Clear( void );
	
  public:
    void SetOperation( EOPERATION aCode );
	void SetDestinationAddress( unsigned int aDestinationAddress );
	void SetSrc1Address( unsigned int aAddress );
	void SetSrc0Address( unsigned int aAddress );
	void SetCopyDestinationAddress( unsigned int aAddress );
	void SetCopySourceAddress( unsigned int aAddress );
	void SetCopyDestinationId( unsigned int aAddress );
	void SetCopySize( unsigned int aAddress ); //High part or SRC0
	void SetLiteral(  unsigned int aLiteral );
	std::string PrintAssembly( void );
  //private:
	unsigned int     mOperation;
	unsigned int     mDestination;
	unsigned int     mSource1;
	unsigned int     mSource0;
	unsigned int     mCopyDestinationAddress;
	unsigned int     mCopySourceAddress;
	unsigned int     mCopyDestinationId;
	unsigned int     mCopySize;
	unsigned int     mLiteral;
	
public:	
	int                     	  mSourceLine;
	std::string                   mComment;
  private:	

};

#endif