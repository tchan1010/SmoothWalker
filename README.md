# A sample Mobility Health App

This app accesses ussers' health data via the IOS HealthStore, and depicts users' mobility
health data in the app. 

This app runs on iPhone with iOS 14 or the latest.

## Overview

- Note: This sample code project is associated with WWDC20 session [10664: Getting Started in HealthKit](https://developer.apple.com/wwdc20/10664/) and WWDC20 session [10184: Synchronizing Your Health Data with HealthKit](https://developer.apple.com/wwdc20/10184/).


Installation and Run Instruction 

Run the following commands on a Mac computer:

1  git clone https://github.com/tchan1010/SmoothWalker.git
2. cd SmoothWalker
3. git checkout depictWalkingSpeed
4. Run Xcode on the SmoothWalker.xcodeproj
5. Install the app onto your iPhone via Xcode

Once you have the app installed on iPhone, open the app and 
click the Walking Speed icon on the bottom tab bar. 

To enable the Walking Speed page, you need to authorize the
app to have access (read and write) to the Walking Speed category
in the Health Store. You may do that via the app's Welcome page,
Health app, or when your are prompted when you access the Walking 
Speed page the very first time.  

On the Walking Speed page, click the Fetch button to load the
mocked data to the health store. You may then click the Show button 
to see the following information:

1. Daily average walking speed - chart and table
2. Weekly average walking speed - chart and table
3. Monthly average walking speed - chart and table
4. Daily, weekly and monthly walking speed charts all on the same page


Version History

3/23/21  Created the SmoothWalker GitHub respository
         Created the depictWalkingSpeed branch

3/26/21  Checked-in updated code for Walking Speed feature.
