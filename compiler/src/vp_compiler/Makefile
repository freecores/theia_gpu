all:
	bison parser.y
	flex scanner.l
	g++ -g lex.yy.cc Main.cpp parser.tab.c Preprocessor.cpp Instruction.cpp -o theia_vp_compile 
	mv -v theia_vp_compile ../../bin/	
clean:
	rm -rf parser.tab.c parser.tab.h location.hh position.hh stack.hh
	rm -rf lex.yy.cc
	rm -rf theia_compile
