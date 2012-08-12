
#include <string>
#include <map>
#include <vector>
using namespace std;
//-----------------------------------------------------------------------
#define MAX_MACRO_FUNCTION_LINE_COUNT 100
class TMacroFunction
{
public:
	vector<string> GetSubstitudedMacro( void );
	string mName;
	string mReturnSymbol;
	string mReturnValue;
	vector<string> mParamterSymbol;
	vector<string> mParamterValue;
	vector<string> mLines;
} ;
//--------------------------------------------------------
class Preprocessor
{
 public:
	Preprocessor();
	~Preprocessor();
public:
	void Execute( string aFile );
	
 private:
	vector<string> ScanFile(  ifstream & ifs );
	void SubstitudeMacros( vector<string> & aFile, ofstream & ofs );
	void PopulateMacroFunction(string aSignature,  ifstream & ifs, vector<string> & aNewFile);
	
	map<string, TMacroFunction> 	mMacroFunctions;
	map <string,string> 		mMacros;
	
};
//--------------------------------------------------------