#!/bin/sh

build() {
	cd fake$1
	xcodebuild -configuration Debug -sdk iphonesimulator4.2
	if [ "$2" ]
	then
	mkdir -p "../SimFinger/SimAppCollection/FakeApps/Fake$1/$2.app"
	cp -rf "build/Debug-iphonesimulator/$2.app" "../SimFinger/SimAppCollection/FakeApps/Fake$1/"
	else
	mkdir -p ../SimFinger/SimAppCollection/FakeApps/Fake$1/$1.app
	cp -rf build/Debug-iphonesimulator/$1.app ../SimFinger/SimAppCollection/FakeApps/Fake$1/
	fi
	cd ..
}

build "AppStore" "App Store"
build "Calculator"
build "Calendar"
build "Camera"
build "Clock"
build "Compass"
build "iPod"
build "iTunes"
build "Mail"
build "Maps"
build "Notes"
build "Phone"
build "Stocks"
build "Text" "Messages"
build "VoiceMemos" "Voice Memos"
build "Weather"
build "YouTube"