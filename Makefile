all:
	bison parser.y
	flex scanner.l
	g++ lex.yy.cc Main.cpp parser.tab.c Preprocessor.cpp Instruction.cpp -o theia_compile 
	
clean:
	rm -rf parser.tab.c parser.tab.h location.hh position.hh stack.hh
	rm -rf lex.yy.cc
	rm -rf theia_compile
