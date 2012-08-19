#include "Preprocessor.h"
#include <iostream>
#include <fstream>
#include <map>
#include <vector>
using namespace std;

//----------------------------------------------------------------
Preprocessor::Preprocessor()
{
}
//----------------------------------------------------------------
Preprocessor::~Preprocessor()
{
}
//-----------------------------------------------------------------------
void Tokenize(const string& str,
                      vector<string>& tokens,
                      const string& delimiters = " ")
{
    
    string::size_type lastPos = str.find_first_not_of(delimiters, 0);
      string::size_type pos     = str.find_first_of(delimiters, lastPos);

    while (string::npos != pos || string::npos != lastPos)
    {
    
        tokens.push_back(str.substr(lastPos, pos - lastPos));
        lastPos = str.find_first_not_of(delimiters, pos);
        pos = str.find_first_of(delimiters, lastPos);
    }
}
//----------------------------------------------------------------
vector<string> Preprocessor::ScanFile(  std::ifstream & ifs )
{
	vector<string> NewFile;
	while (!ifs.eof())
	{
		 char Buffer[1024];
		 ifs.getline( Buffer,1024 );
		 string Line = Buffer;
	
		 //replace tabs with spaces
		 int pos = 0;
		 while ((pos = Line.find("\t")) != string::npos)
					Line.replace(pos,1," ");
					
		 if (Line.find("#") == string::npos)
		 {
		    NewFile.push_back(Line);
			continue;
		 }
	
		 if (Line.find("#macro") != string::npos)
		 {
	
			  NewFile.push_back("//" + Line);
			  PopulateMacroFunction(Line,ifs,NewFile);
			  continue;
	     }
	
		vector<string> Tokens;
		Tokenize(Line,Tokens," ");
		if (Tokens.size() != 0)
		{
    
		if (Tokens[0] == "#define")
			mMacros[ Tokens[1] ] = Tokens[2];
		}
	
		NewFile.push_back("//" + Line);	
	
	}
	
	//for( map<string,string>::const_iterator it = mMacros.begin(); it != mMacros.end(); ++it )
		//cout << "macro " << it->first << " = " << it->second << "\n";
	//cout << "\n";
	//for( map<string,TMacroFunction>::iterator it = mMacroFunctions.begin(); it != mMacroFunctions.end(); ++it )
		//cout << "macro function " << it->first << "\n";
		
	return NewFile;
}
//----------------------------------------------------------------
void Preprocessor::SubstitudeMacros( vector<string> & aFile, ofstream & ofs )
{
	//for (int i = 0; i < NewFile.size(); i++)
	int i = 0;
	for ( vector<string>::iterator I = aFile.begin(); (I != aFile.end() && i < aFile.size()); I++, i++)
	{
		//cout << "Line " << *I << "\n";
	//Now the macro literals
		for( map<string,string>::const_iterator it = mMacros.begin(); it != mMacros.end(); ++it )
		{
			string Key = it->first;
			string Value = it->second;
			string Line = aFile[i];
			while (Line.find(Key) != string::npos)
				Line.replace(Line.find(Key),Key.length(),Value);
			aFile[i] = Line;
		}
		

		//First the macro functions
		for( map<string,TMacroFunction>::iterator it = mMacroFunctions.begin(); it != mMacroFunctions.end(); ++it )
		{
			string Key = it->first;
			TMacroFunction MacroFunction = it->second;
			string Line =*I;
			if (Line.find("//") != string::npos)
				Line.erase(Line.find("//"),Line.length()-Line.find("//"));
				//continue;

			if (Line.find(Key) != string::npos)
			{
				int pos = 0;
				 while ((pos = Line.find(" ")) != string::npos)
					Line.erase(pos,1);
				  vector<string> Tokens;
				Tokenize(Line,Tokens,"=");
			
				MacroFunction.mReturnValue = Tokens[0];
				vector<string> Tokens2;
				string Tmp = Tokens[1];
				Tokens.clear();
				Tokenize(Tmp,Tokens,"(");
				Tmp = Tokens[1];
				 while ((pos = Tmp.find(")")) != string::npos)
					 Tmp.erase(pos,1);
				 while ((pos = Tmp.find(";")) != string::npos)
					 Tmp.erase(pos,1);
				 Tokens.clear();
				 Tokenize(Tmp,Tokens,",");
				 MacroFunction.mParamterValue = Tokens;

				 vector<string> MacroString = MacroFunction.GetSubstitudedMacro();
				 aFile[i] = "//" + aFile[i];
				 I = aFile.begin() + i+1;
				 aFile.insert(I,MacroString.begin(),MacroString.end());
				
				 I = aFile.begin() + i;
			}
		}
		
	//	cout <<  aFile[i].c_str() << std::endl;
		ofs << aFile[i].c_str() << std::endl;
	}
}
//----------------------------------------------------------------
void Preprocessor::Execute( string aFile )
{
	ifstream ifs;
	ifs.open(aFile.c_str());
	if (!ifs.good())
		throw string("Cannot open file" + aFile + "\n");
		
	cout << "Scanning file " << aFile << "\n";
	vector<string> NewFile = ScanFile( ifs );
	ifs.close();	
	cout << "Preprocessing file " << aFile << "\n";
	ofstream ofs(string(aFile + ".preprocessed").c_str());
	SubstitudeMacros( NewFile, ofs );
	ofs.close();
}
//----------------------------------------------------------------
vector<string> TMacroFunction::GetSubstitudedMacro()
	{
		vector<string> ReturnString;
		for (int i = 0; i < mLines.size(); i++)
		{
			
			string Line = mLines[i];
			for (int j = 0; j < mParamterSymbol.size(); j++)
			{
				while(  Line.find(mParamterSymbol[j]) != string::npos )
					Line.replace(Line.find(mParamterSymbol[j]),mParamterSymbol[j].length(),mParamterValue[j]);

				while(  Line.find(mReturnSymbol) != string::npos )
					Line.replace(Line.find(mReturnSymbol),mReturnSymbol.length(),mReturnValue);
				
			}	
			
			ReturnString.push_back( Line );
		}
		return ReturnString;
	}
//----------------------------------------------------------------
void Preprocessor::PopulateMacroFunction(string aSignature, std::ifstream & ifs, vector<string> & aNewFile)
{
	
	 //Get rid of spaces
	 int pos = 0;
	 while ((pos = aSignature.find(" ")) != string::npos)
				 aSignature.erase(pos,1);
	//Delete the "#macro" string
	aSignature.erase(0,6);
	vector<string> Tokens;
	Tokenize(aSignature,Tokens,"=");
	TMacroFunction M;		
	M.mReturnSymbol = Tokens[0];
	
	string Tmp = Tokens[1];
	Tokens.clear();
	Tokenize(Tmp,Tokens,"(");
	M.mName = Tokens[0];
	Tmp = Tokens[1];
	while ((pos = Tmp.find(")")) != string::npos)
		 Tmp.erase(pos,1);
	 Tokens.clear();
	 Tokenize(Tmp,Tokens,",");
	 M.mParamterSymbol = Tokens;

	 int MacroLineCount = 0;
	 while (MacroLineCount < MAX_MACRO_FUNCTION_LINE_COUNT)
	 {
		char Buffer[1024];
		 ifs.getline( Buffer,1024 );
		 string Line = Buffer;
	     aNewFile.push_back("//" + Line);
		 if (Line.find("#endmacro") != string::npos)
				 break;
		 M.mLines.push_back( Line );
		 MacroLineCount++;
	 }

	 mMacroFunctions[M.mName] = M;
	 M.mLines.clear();
}
//----------------------------------------------------------------