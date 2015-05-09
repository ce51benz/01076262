all:lex.yy.c ass4.tab.c ass4.tab.h
	gcc lex.yy.c ass4.tab.c `pkg-config --cflags --libs glib-2.0,gio-unix-2.0` -o fff
lex.yy.c:lexass4.flex
	flex lexass4.flex
ass4.tab.c ass4.tab.h:ass4.y
	bison -d ass4.y
clean:
	rm lex.yy.c ass4.tab.c ass4.tab.h fff

