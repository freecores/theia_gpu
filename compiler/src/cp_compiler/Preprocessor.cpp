#include "Preprocessor.h"
#include <iostream>
#include <fstream>
#include <map>
#include <vector>
using namespace std;
void find_and_replace( string& input_string,
                       const string& find_string,
                       const string& replace_string )
{
  if( find_string.empty()
      or find_string == replace_string
      or input_string.length() < find_string.length() )
  {
    return;
  }

  string output_string;
  output_string.reserve( input_string.length() );
  size_t last_pos = 0u;
  for( size_t new_pos = input_string.find( find_string );
       new_pos != string::npos;
       new_pos = input_string.find( find_string, new_pos ) )
  {
    bool did_replace = false;
    if( ( new_pos == 0u
          or not std::isalpha( input_string.at( new_pos - 1u ) ) )
        and ( new_pos + find_string.length() == input_string.length()
              or not std::isalpha( input_string.at( new_pos + find_string.length() ) ) ) )
    {
      output_string.append( input_string, last_pos, new_pos - last_pos );
      output_string.append( replace_string );
      did_replace = true;
    }
    new_pos += find_string.length();
    if( did_replace )
    {
      last_pos = new_pos;
    }
  }
  output_string.append( input_string, last_pos,
                        input_string.length() - last_pos );

  input_string.swap( output_string );
}
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
void Preprocessor::IncludeFile(  string aPath, vector<string> & NewFile )
{
	ifstream ifs;
	ifs.open(aPath.c_str());
	if (!ifs.is_open())
		throw string("Could not include file '") + aPath + "'";
					
	while( !ifs.eof())
	{
			char Buffer[1024];
			ifs.getline( Buffer,1024 );
			string Line = Buffer;
			ScanLine(Line,NewFile,ifs, false);
			//	NewFile.push_back("//" + Line);	
	}
	ifs.close();	
}
//----------------------------------------------------------------
void Preprocessor::ScanLine( string & Line , vector<string> & NewFile, ifstream & ifs, bool aAddLineToFile = true )
{
	 //replace tabs with spaces
		 int pos = 0;
		 while ((pos = Line.find("\t")) != string::npos)
					Line.replace(pos,1," ");
					
		 if (Line.find("#") == string::npos)
		 {
			
			NewFile.push_back(Line);
			return;
		 }
	
		 if (Line.find("#macro") != string::npos)
		 {
			  if (aAddLineToFile)
				NewFile.push_back("//" + Line);
			  PopulateMacroFunction(Line,ifs,NewFile);
			  return;
	     }
	
		vector<string> Tokens;
		Tokenize(Line,Tokens," ");
		if (Tokens.size() != 0)
		{
    
			if (Tokens[0] == "#define")
			{
				mMacros[ Tokens[1] ] = Tokens[2];
				if (aAddLineToFile)
					NewFile.push_back("//" + Line);	
			}
				
			if (Tokens[0] == "#include")
			{
				string IncludeFilaPath = Tokens[1];
			
				while(IncludeFilaPath.find("\"") != string::npos) IncludeFilaPath.erase(IncludeFilaPath.find("\""),1);
				IncludeFile( IncludeFilaPath, NewFile );
			/*	ifstream ifs;
				ifs.open(IncludeFilaPath.c_str());
				if (!ifs.is_open())
					throw string("Could not include file '") + IncludeFilaPath + "'";
					
				while( !ifs.eof())
				{
					char Buffer[1024];
					ifs.getline( Buffer,1024 );
					string Line = Buffer;
					ScanLine(Line,NewFile,ifs);
				//	NewFile.push_back("//" + Line);	
				}
				ifs.close();	*/
			}
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
		 ScanLine( Line,NewFile,ifs );
	
		
	}
	
			
	return NewFile;
}
//----------------------------------------------------------------
void Preprocessor::SubstitudeMacros( vector<string> & aFile, ofstream & ofs )
{
	//for (int i = 0; i < NewFile.size(); i++)
	int i = 0;
	for ( vector<string>::iterator I = aFile.begin(); (I != aFile.end() && i < aFile.size()); I++, i++)
	{
		
	//Now the macro literals
		for( map<string,string>::const_iterator it = mMacros.begin(); it != mMacros.end(); ++it )
		{
			string Key = it->first;
			string Value = it->second;
			string Line = aFile[i];
			if (Line.find("#define") != string::npos)
			{
				aFile[i] = Line;	
				continue;
			}
			find_and_replace(Line,Key,Value);
			
			aFile[i] = Line;
		}
		

		//Now the macro functions
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
		std::cout << "Cannot open file" << aFile << "\n";
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