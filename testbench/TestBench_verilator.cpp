#include "Theia.h"
#include "verilated.h"

int main( int argc, char ** argv, char ** env)
{
	Verilated::commandArgs(argc, argv);
	Vour * top = new Vour;
	while ( !Verilated::gotFinish())
	{
		top->eval();
	}
}
