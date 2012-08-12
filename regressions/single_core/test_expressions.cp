#include "code_block_header.thh"
#define VP_DST_CODE_MEM (1<<31)
#define VP02                2

  scalar SrcOffset = TEST_EXPRESSIONS_OFFSET,DstOffset;
  DstOffset = (0x0 | TEST_EXPRESSIONS_SIZE | VP_DST_CODE_MEM ); 
  copy_data_block < VP02 , DstOffset  ,SrcOffset>;
  
  
  //wait until enqueued block transfers are complete
  while ( block_transfer_in_progress ) {}
  
  start <VP02>; 
  
  exit ;

