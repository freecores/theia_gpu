#include "theia.thh"
#include "code_block_header.thh"


scalar DstOffsetAndLen,SrcOffset,CoredId;
//First send the data into cores

SrcOffset = 0;
DstOffsetAndLen = (0x0 | (SIMPLE_RENDER_VP_INPUT_DATA_LEN << 20)  ); 

 while (CoredId <= THEIA_CAPABILTIES_MAX_CORES)
 {
	copy_data_block< CoredId, DstOffsetAndLen, SrcOffset>;
	SrcOffset += SIMPLE_RENDER_VP_INPUT_DATA_LEN;
	CoredId++;
}

 //wait until enqueued block transfers are complete
  while ( block_transfer_in_progress ) {}
  
  
  SrcOffset = SIMPLE_RENDER_VP_CODE_OFFSET;
  DstOffsetAndLen = (0x0 | SIMPLE_RENDER_VP_CODE_SIZE | VP_DST_CODE_MEM ); 
  copy_data_block < ALLCORES , DstOffsetAndLen  ,SrcOffset>;
  
  start <ALLCORES>; 
  
  exit ;