/* This program is free software. It comes without any warranty, to
 * the extent permitted by applicable law. You can redistribute it
 * and/or modify it under the terms of the Do What The Fuck You Want
 * To Public License, Version 2, as published by Sam Hocevar. See
 * http://sam.zoy.org/wtfpl/COPYING for more details. */
 
#pragma once

#include <fstream>
#include "Scanner.h"
#include <vector>
#include "Instruction.h"
#include <iostream>
#include <string>
#include <iterator>


	class TheiaCompiler 
	{
		public:
			std::vector<std::string> mPreprocessedFile;
			// can instantiate with either a file name or an already open stream
			inline explicit TheiaCompiler(std::string fileName) throw(std::string);
			inline explicit TheiaCompiler(std::istream &iniStream) throw(std::string);

			// Get a value from section and key
			const char * getValue(const char * const section, const char * const key) const;
			//-------------------------------------------------------------------------------------
			void PrependCodeInitialization()
			{
				
				Instruction I;
				I.mComment ="Make sure R0 has the appropiate values";
				I.SetCode( EOPERATION_ADD );
				I.SetDestinationAddress( 0 );
				I.SetImm( 0 );
				I.SetDestZero( true );
				I.SetWriteChannel(ECHANNEL_X);
				mInstructions.push_back( I );
				I.Clear();
				
				
				I.SetCode( EOPERATION_ADD );
				I.SetDestinationAddress( 0 );
				I.SetImm( 1 );
				I.SetDestZero( true );
				I.SetWriteChannel(ECHANNEL_Y);
				mInstructions.push_back( I );
				I.Clear();
				
				
				I.SetCode( EOPERATION_ADD );
				I.SetDestinationAddress( 0 );
				I.SetImm( 2 );
				I.SetDestZero( true );
				I.SetWriteChannel(ECHANNEL_Z);
				mInstructions.push_back( I );
				I.Clear();
		
				
				I.mComment = "Make sure R30 (Frame Offset) is initialized to zero";
				I.SetCode( EOPERATION_ADD );
				I.SetDestinationAddress( SPR_CONTROL_REGISTER );
				I.SetImm( 0 );
				I.SetDestZero( true );
				I.SetWriteChannel(ECHANNEL_XYZ);
				mInstructions.push_back( I );
				I.Clear();
			}
			//-------------------------------------------------------------------------------------
			std::string GetHexCodeDump(void)
			{
				std::ostringstream oss;
				//Add the header
				oss << "//List file created by theia_compile\n";
				
			
				for ( int i = 0; i < mInstructions.size(); i++)
				{
				
					oss  << GetLineSymbolDefintion( i );
						
					if (mInstructions[i].mSourceLine > 0)
							oss << "//" << mPreprocessedFile[ mInstructions[i].mSourceLine -1 ] << "\n";
					
					if (mInstructions[i].mComment.size())
							oss << "//" << mInstructions[i].mComment<< "\n";
							
						oss << std::dec << i ;
						//oss << std::hex << " (0x"  <<  i << ") " ;
						oss << ":\t" << mInstructions[i].PrintAssembly() << "\n";
				}
					
				return oss.str();	
			}
			//-------------------------------------------------------------------------------------
			std::string GetLineSymbolDefintion( unsigned int aLine )
			{
				
				std::map<std::string, unsigned int>::const_iterator it;
				for (it = mSymbolMap.begin(); it != mSymbolMap.end(); ++it)
				{
					if (it->second == aLine)
						return "\n//" + it->first + "\n";		
					
				}
				return std::string("");
			}
			//-------------------------------------------------------------------------------------
			void Print(void)
			{
				for (int i = 0; i < mInstructions.size(); i++)
				{
					//std::cout << "EA      : " << i << "\n";
					//std::cout << mInstructions[i].PrintHex() << "\n";
					mInstructions[i].PrintFields();
					//std::cout << "\n";
				}
			}
			//--------------------------------------------------------------------------------------------------
			std::string PostProcess( std::string fileName )
			{
				std::string Result;
				std::ifstream ifs(fileName.c_str());
				if (!ifs.good()) 
					throw std::string("Unable to open file "+ fileName);
				
				while (!ifs.eof())		
				{
					char Buffer[1024];
					ifs.getline( Buffer,1024 );
					std::string Line = Buffer;
					
					//Ignore comments
					if (Line.find("//") != std::string::npos)
						Line.erase(Line.find("//"),Line.length());
					
					while (Line.find("\t") != std::string::npos)
						Line.replace(Line.find("\t"),1," ");
					//Ignore blank lines
					if (Line.length() == 0)
						continue;
					
					std::stringstream ss;
					ss << Line;
					std::string LineNumber,DestinationSymbol;
					unsigned int Operation,Destination,Src1,Src0;
					if (Line.find("@") != std::string::npos)
					{
						ss >> std::hex>> LineNumber >> Operation >> DestinationSymbol >>  Src1 >> Src0;
						DestinationSymbol.erase(0,1);
						//std::cout << "XXXX DestinationSymbol " << DestinationSymbol << "\n";
						std::ostringstream oss;
						Destination = mSymbolMap[ DestinationSymbol ]; 
						//std::cout << "XXXX Destination " << Destination << "\n";
					}
					else
						ss >> std::hex>> LineNumber >> Operation >> Destination >> Src1 >> Src0;
						
						//std::cout << "'" << Line << "'" << std::hex << LineNumber << "," << Operation << "," << Destination << "," << Src1 << "," << Src0 << "\n";
					Instruction I;
					I.SetFields(Operation,Destination,Src1,Src0);
					Result += I.PrintHex() + "\n";
				}
				return Result;
			}
			//--------------------------------------------------------------------------------------------------
			
		private:
			// supress default constructor
			TheiaCompiler();
			// supress default copy constructor
			TheiaCompiler(TheiaCompiler const &rhs);
			// supress default assignment operator
			TheiaCompiler &operator=(TheiaCompiler const &rhs);
			
			std::vector< Instruction >          mInstructions;
			std::map<std::string,unsigned int>  mSymbolMap;
			bool 								mGenerateFixedPointArithmetic;
	};
	
//-------------------------------------------------------------------------------------------------------
	TheiaCompiler::TheiaCompiler(std::string fileName) throw(std::string) 
	{
		mGenerateFixedPointArithmetic = false;
		std::ifstream inFile(fileName.c_str());
		if (!inFile.good()) 
			throw std::string("Unable to open file "+ fileName);
		
		//First get me a local copy of the file into a vector
		std::string Line; //int  i = 1;
		while( std::getline(inFile, Line) )
		{
				mPreprocessedFile.push_back( Line );
				////std::cout << i++ << " " << Line << "\n";
		}
			
		inFile.close();
		inFile.open(fileName.c_str());
		if (!inFile.good()) 
			throw std::string("Unable to open file "+ fileName);
			
		PrependCodeInitialization();
		
		Theia::Scanner scanner(&inFile);
		Theia::Parser parser(scanner, mSymbolMap , mInstructions, mGenerateFixedPointArithmetic);
		std::cout << "parsing file\n";
		parser.parse();
	}
//-------------------------------------------------------------------------------------------------------
	
	TheiaCompiler::TheiaCompiler(std::istream &iniStream) throw(std::string) 
	{
		mGenerateFixedPointArithmetic = false;
		Theia::Scanner scanner(&iniStream);
		Theia::Parser parser(scanner, mSymbolMap, mInstructions, mGenerateFixedPointArithmetic);
		parser.parse();
	}

//-------------------------------------------------------------------------------------------------------
