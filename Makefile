CC = arm-apple-darwin-cc
LD = $(CC)

CFLAGS = -Wall -Werror -std=c99
LDFLAGS = -ObjC -framework CoreFoundation -framework Foundation \
          -framework UIKit -framework LayerKit -framework CoreGraphics \
          -framework OfficeImport

all:	MobilePushr package

MobilePushr: main.o MobilePushr.o
	$(LD) $(LDFLAGS) -o $@ $^

%.o:	%.m
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

package: MobilePushr
	rm -fr Pushr.app
	mkdir -p Pushr.app
	cp MobilePushr Pushr.app/MobilePushr
	cp Info.plist Pushr.app/Info.plist
	cp icon.png Pushr.app/icon.png
	cp background.png Pushr.app/background.png

Muffler: Muffler.m
	cc -o Muffler Muffler.m -framework Foundation -std=c99 -ObjC 

clean:	
	rm -fr *.o MobilePushr Pushr.app

