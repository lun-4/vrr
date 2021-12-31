RESOURCES = main.lua lovr-luasocket
PROJECT_NAME = vrr_client

.PHONY = package

clean:
	rm -f funny.so

funny.so: funny.c
	gcc -I/usr/include/lua5.1 $(shell pkg-config --cflags --libs libavcodec libavformat libswscale libavutil lua5.1) -g -shared -o funny.so funny.c
    
package: $(RESOURCES)
	zip -9r $(PROJECT_NAME).lovr $(RESOURCES)

send-%: %
	adb push --sync $< /sdcard/Android/data/org.lovr.hotswap/files/.lodr

send: send-main.lua
