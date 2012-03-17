/* This program is free software. It comes without any warranty, to
 * the extent permitted by applicable law. You can redistribute it
 * and/or modify it under the terms of the Do What The Fuck You Want
 * To Public License, Version 2, as published by Sam Hocevar. See
 * http://sam.zoy.org/wtfpl/COPYING for more details. */
 
#include "Compiler.h"
#include "Preprocessor.h"
#include <string>
#include <iostream>
#include <fstream>
#include <cstring>

Preprocessor PP;

int main(int argc, char * argv[]) {
	// make sure we received a filename
	if (argc != 2) {
		std::cerr << "Usage: ./ini-parser [FILENAME]" << std::endl;
		return 255;
	}

	
std::cout << "---------------------------------------------------------------\n";
std::cout << "  \n";
std::cout << " _/_/_/_/_/  _/                  _/            \n";
std::cout << "   _/      _/_/_/      _/_/          _/_/_/   \n";
std::cout << "  _/      _/    _/  _/_/_/_/  _/  _/    _/    \n";
std::cout << " _/      _/    _/  _/        _/  _/    _/     \n";
std::cout << "_/      _/    _/    _/_/_/  _/    _/_/_/      \n";
std::cout << "\n";
std::cout << "\n";
std::cout << "---------------------------------------------------------------\n";
	// try and open the INI file
	TheiaCompiler * Compiler;
	try {
		// - means stdin, not a file named '-'
		if (strcmp(argv[1], "-") == 0) {
			
			Compiler = new TheiaCompiler(std::cin);
		} else {
			PP.Execute(argv[1]);
			
			Compiler = new TheiaCompiler( std::string(argv[1])+ ".preprocessed");
		}
	} catch (std::string error) {
		std::cerr << "ERROR: " << error << std::endl;
		return 255;
	}
	Compiler->Print();
	
	std::ofstream ofs;
	ofs.open("code.list");
	if (!ofs.good())
	{
		std::cout << "Error could not open file for write 'code.mem'\n";
		return 0;
	}	
		
	ofs << Compiler->GetHexCodeDump();
	ofs.close();
	ofs.open("code.mem");
	ofs << Compiler->PostProcess("code.list");
	ofs.close();

    delete Compiler;
	return 0;
}

