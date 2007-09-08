CC = arm-apple-darwin-cc
LD = $(CC)
LDFLAGS = -ObjC -framework CoreFoundation -framework Foundation \
          -framework UIKit -framework LayerKit -framework CoreGraphics
CFLAGS = -Wall -Werror

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

clean:	
	rm -fr *.o MobilePushr Pushr.app
