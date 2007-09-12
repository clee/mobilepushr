CC = arm-apple-darwin-cc
LD = arm-apple-darwin-ld

CFLAGS = -Wall -Werror -Wno-unused -std=c99
LDFLAGS = -lcrypto -lobjc -framework CoreFoundation -framework Foundation -framework UIKit -framework LayerKit -framework CoreGraphics -framework OfficeImport

all: MobilePushr package

MobilePushr: main.o MobilePushr.o
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.m
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

package: MobilePushr
	rm -fr Pushr.app
	mkdir -p Pushr.app
	cp MobilePushr Pushr.app/MobilePushr
	cp Info.plist Pushr.app/Info.plist
	cp icon.png Pushr.app/icon.png
	cp background.png Pushr.app/background.png

Muffler: Muffler.m
	cc -o Muffler Muffler.m -framework Foundation -std=c99 -lobjc -lssl -lcrypto

setdefaults: setdefaults.m
	cc -o setdefaults setdefaults.m -framework Foundation -std=c99 -lobjc

clean:	
	rm -fr *.o MobilePushr Pushr.app

