APP_ID = org.eclipse.Sdk
APP_PLUGIN = org.eclipse.sdk

all:
	true && true

install:
	cp -ar /usr/lib/sdk/openjdk9/jvm/openjdk-9 java
	rm -rf java/man java/demo
	mkdir -p /app/eclipse
	mv java artifacts.xml configuration dropins eclipse eclipse.ini features p2 plugins readme /app/eclipse
	mkdir -p /app/bin
	echo "export PATH=\"$$PATH:/app/eclipse/java/bin\"" >> /app/bin/eclipse
	echo "/app/eclipse/eclipse" >> /app/bin/eclipse
	chmod +x /app/bin/eclipse
	mkdir -p /app/share/applications
	mkdir -p /app/share/appdata
	mv $(APP_ID).desktop /app/share/applications
	mv $(APP_ID).appdata.xml /app/share/appdata
	mkdir -p /app/share/icons/hicolor/32x32/apps
	mkdir -p /app/share/icons/hicolor/48x48/apps
	mkdir -p /app/share/icons/hicolor/256x256/apps
	cp -p /app/eclipse/plugins/$(APP_PLUGIN)_*/eclipse32.png /app/share/icons/hicolor/32x32/apps/$(APP_ID).png
	cp -p /app/eclipse/plugins/$(APP_PLUGIN)_*/eclipse48.png /app/share/icons/hicolor/48x48/apps/$(APP_ID).png
	cp -p /app/eclipse/plugins/$(APP_PLUGIN)_*/eclipse256.png /app/share/icons/hicolor/256x256/apps/$(APP_ID).png

