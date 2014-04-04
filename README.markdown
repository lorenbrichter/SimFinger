#SimFinger
AWESOME SCREENCASTS

![Screenshot of SimFinger in Action](http://i.imgur.com/DktGiQr.png)

##Summary
SimFinger itself is composed of two parts. One is a fake “frame” that sits on top of the simulator. The frame consists of the most recent version of the iPhone or iPad (depending on what device your sim is set to). Clicking anywhere on it will just click-through to whatever is below. The other part is a little nub that follows around your cursor. It “indents” when you press down with your mouse, indicating what would be a “touch” on the phone.

A good screencapture tool is your friend. [SnapzProX](http://www.ambrosiasw.com/utilities/snapzprox/) and [ScreenFlow](http://www.telestream.net/screenflow/) are good choices. 

##Some Caveats
* Currently set to work with iOS 7.1 simulator in xCode 5.1
* Current imagery available for the following:
** iPhone 5S Vertical and Landscape
** iPhone 4S Vertical and Landscape (when sim is set to 3.5 inches)
** iPad Air Vertical and Landscape

##Instructions
1. [Launch the iOS Simulator](http://stackoverflow.com/a/5048572/776167)
2. Hide your dock with shortcut -Option-D (SimFinger locks itself to the lower left of your screen)
3. Make sure the simulator's scale (Window > Scale) fits SimFinger. For retina devices, scale @ 50%. For non-retina, just use 100%.
4. Set your simulator device type to whatever you want to take a screencast of. For example, if you want the landscape iPad, set your simulator device to the iPad and rotate. SimFinger will choose its overlay image based on the dimensions of your simulator.
5. Launch SimFinger
  - If you want to build from code, launch the [SimFinger.xcodeproj](Fake/SimFinger/FakeFinger.xcodeproj)
  - If you want a compiled version, download [SimFingerApp.zip](SimFingerApp.zip)

###Protips
*If you want to change the overlay image without restarting SimFinger, just go to Control > Reposition iPhone Simulator Window and it will auto adjust the overlay image.
*[Enable Universal Access](http://mizage.com/help/accessibility.html)

###If you run into issues with installing the homescreen apps, do the following:
1. Run buildFakeApps.sh from terminal (Should be lots of happy success messages)
2. From the simfinger source folder, go to Fake > SimFinger > SimAppCollection > FakeApps
3. Copy Everything out of the FakeApps folder
4. Paste everything into ~/Library/Application Support/iPhone Simulator/7.1/Applications/
5. Restart the simulator
6. The icons will be on the second screen, just swipe over. Look up pictures of the default iOS home screen and order the icons appropriately.
7. Profit?

Enjoy, fork away, email loren.brichter@atebits.com when you make it moar better and want me to check out your changes.
