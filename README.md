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
click the Walking Speed icon in the bottom tab bar. 

To enable the walking speed page, you need to authorize the
app to have the walking speed access right in the Health Store.
You may do that via the app's Welcome page or when prompted 
when you access the walking speed page the first time. However, 
if you deny authorizing the walking speed access for the app, 
you will not see any data in the walking speed page, and you 
will need to authorize the walking Speed access right to the
app in the Health app.  

Once you have authorized the walking speed access right to the
app, open the walking speed page, and you will see three charts
that show the daily, weekly and monthly average walking speed, 
respectively. You may tap on a chart to view the detailed page
of that chart. You may dismiss the detailed page by tapping on 
anywhere in that view.


Version History

3/23/21  Created the SmoothWalker GitHub respository
         Created the depictWalkingSpeed branch

3/26/21  Checked-in updated code for Walking Speed feature.

3/27/21  Show all charts on the Walking Speed main page.
         When user taps on a chart, show the detailed page 
         for that chart (chart and table).
