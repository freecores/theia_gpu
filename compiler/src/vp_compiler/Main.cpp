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
	if (argc < 2) {
		std::cerr << "Usage: ./theia_compile -i [FILENAME] [-f <hex32|hex64>]" << std::endl;
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
	
	char * inputFile, * outputMode; 
	TheiaCompiler * Compiler;
	bool OutputMode32 = false;
	bool FilePathDefined = false;
	bool StdIn = false;
	try {
	
	for (int i = 1; i < argc; i++)
	{
		
			if (!strcmp(argv[i],"-i"))
			{
				inputFile = argv[i+1];
				FilePathDefined = true;
				i++;
			} 
			else if (!strcmp(argv[i],"-stdin"))
			{
				StdIn = true;
			}
			else if (!strcmp(argv[i],"-hex32"))
			{
					OutputMode32 = true;
				
			}
			else
			{
				std::cout << "Error: Invalid option " <<  argv[i] << "\n";
				return 255;
			}
						
			
		
	}
	if (!FilePathDefined)
	{
		std::cout << "Error: Input file not defined\n ";
		return 255;
	}
	
	if (StdIn)
	{
		Compiler = new TheiaCompiler(std::cin);
	} else {
		PP.Execute(inputFile);
		Compiler = new TheiaCompiler( std::string(inputFile)+ ".preprocessed",OutputMode32);
		
		
	}
	/*
		// - means stdin, not a file named '-'
		if (strcmp(argv[1], "-") == 0) {
			
			Compiler = new TheiaCompiler(std::cin);
		} else {
			PP.Execute(argv[1]);
			
			Compiler = new TheiaCompiler( std::string(argv[1])+ ".preprocessed");
		}
		*/
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
	std::string Command = "rm " + std::string(inputFile)+ ".preprocessed";
	system(Command.c_str());
	std::cout << "Code successfully compiled!\n";
	return 0;
}

