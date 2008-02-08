PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/opt/local/bin
CC = arm-apple-darwin-gcc
LD = arm-apple-darwin-ld

CFLAGS = -Wall -Werror -Wno-unused -std=c99 -isysroot /Developer/SDKs/MacOSX10.4u.sdk
LDFLAGS = -lcrypto -lobjc -framework CoreFoundation -framework CFNetwork -framework Foundation -framework UIKit -multiply_defined suppress -Wl,-macosx_version_min,10.4 -framework LayerKit -framework GraphicsServices -framework CoreGraphics -framework OfficeImport
RESOURCES = Info.plist Default.png bottombar.png icon.png mainbutton.png mainbutton_pressed.png mainbutton_inactive.png

all: MobilePushr package

MobilePushr: main.o MobilePushr.o FlickrCategory.o Flickr.o PushablePhotos.o PushrNetUtil.o ExtendedAttributes.o PushrSettings.o PushrPhotoProperties.o
	@echo "Linking $@... "
	@$(CC) $(LDFLAGS) -o $@ $^
	@echo "done."

%.o: %.m
	@echo "Compiling $<... "
	@$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	@echo "done."

package: MobilePushr
	@echo "Creating package... "
	@rm -fr Pushr.app
	@mkdir -p Pushr.app
	@cp MobilePushr Pushr.app/MobilePushr
	@cp ${RESOURCES} Pushr.app/
	@echo "done."

clean:
	@echo "Cleaning... "
	@rm -fr *.o MobilePushr Pushr.app
	@echo "done."
