# A sample Mobility Health App

This app accesses ussers' health data via the IOS HealthStore, and depicts users' mobility
health data in the app. 

This app runs on iPhone with iOS 14 or the latest.

## Overview

This app displays your latest walking speed data, as obtained from your device's Health store, in three charts: daily, weekly and monthly.  

- Note: This sample code project is associated with WWDC20 session [10664: Getting Started in HealthKit](https://developer.apple.com/wwdc20/10664/) and WWDC20 session [10184: Synchronizing Your Health Data with HealthKit](https://developer.apple.com/wwdc20/10184/).


## Installation and Run Instruction

Run the following commands on a Mac computer:

1  git clone https://github.com/tchan1010/SmoothWalker.git

2. cd SmoothWalker

3. git checkout depictLatestWalkingSpeed

4. Run Xcode on the SmoothWalker.xcodeproj file

5. Install the app onto your iPhone via Xcode

Once you have the app installed on iPhone, open the app and click the Walking Speed icon at the bottom tab bar.

To enable the walking speed page, you need to authorize the app to have access right to the walking speed data in the Health store. You may do that via the app's Welcome page, or when prompted when you access the walking speed page the first time. If you deny authorizing the app to have the walking speed access right, you will not see any data in the walking speed page, and you will need to authorize the app with the walking speed access right in the Health app. Furthermore, The app's error messages may provide a Settings button which, when clicked, will direct you to the Settings app where you can access the Health app to authorize the app with access rights. When you return to the app, if you see a Fetch button appears on the top right corner of the walking speed page, click that button to manually load the walking speed data from the Health store to the app.

Once the app obtains the walking speed data, you will see three charts appear on the walking speed page. The charts depict the daily, weekly and monthly average walking speed data. You may click on any chart, and it will depict a detailed page for that chart. The detailed page shows the selected chart, and a table listing all the raw data for that chart. You may dismiss a detailed page by tapping on anywhere in that page.

There are two branches in this release:

1. depictWalkingSpeed

    Show the walking speed charts based on a set of mock data

2. depictLatestWalkingSpeed  

    Show the walking speed charts based on the latest and real data as obtained from the Health store.
