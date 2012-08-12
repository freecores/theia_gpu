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
		std::cerr << "Usage: ./theia_cp_compile [FILENAME]" << std::endl;
		return 255;
	}


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
		std::cout << "ERROR: " << error << std::endl;
		return 255;
	}
	
	
	std::ofstream ofs;
	ofs.open("cp_code.list");
	if (!ofs.good())
	{
		std::cout << "Error could not open file for write 'code.mem'\n";
		return 0;
	}	
		
	ofs << Compiler->GetHexCodeDump();
	ofs.close();
	ofs.open("control_code.mem");
	ofs << Compiler->PostProcess("code.list");
	ofs.close();

    delete Compiler;
	std::string Command = "rm " + std::string(argv[1])+ ".preprocessed";
	system(Command.c_str());
	std::cout << "Code successfully compiled!\n";
	return 0;
}

