# A sample Mobility Health App

This app accesses ussers' health data via the IOS Health store, and depicts users' mobility health data in the app. 

Specifically, this app collects your average daily walking speed from the Health store, and depicts those data in three charts: daily average walking speed, weekly average walking speed and monthly average walking speed.

This app runs on iPhone with iOS 14 or the latest.

## Disclosure

- Note: This sample code project is associated with WWDC20 session [10664: Getting Started in HealthKit](https://developer.apple.com/wwdc20/10664/) and WWDC20 session [10184: Synchronizing Your Health Data with HealthKit](https://developer.apple.com/wwdc20/10184/).


## Installation and Run Instruction 

Run the following commands on a Mac computer:

1. git clone https://github.com/tchan1010/SmoothWalker.git

2. cd SmoothWalker

3. Run Xcode on the SmoothWalker.xcodeproj file

4. Install the app onto your iPhone via Xcode

Once you have the app installed on iPhone, open the app and click the Walking Speed icon at the bottom tab bar.

To enable the walking speed page, you need to authorize the app to have access right to the walking speed data in the Health store. You may do that via the app's Welcome page, or when prompted when you access the walking speed page the first time. If you deny authorizing the app to have the walking speed access right, you will not see any data in the walking speed page, and you will need to authorize the app with the walking speed access right in the Health app. Furthermore, The app's error messages may provide a Settings button which, when clicked, will direct you to the Settings app where you can access the Health app to authorize the app with access rights. When you return to the app, if you see a Fetch button appears on the top right corner of the walking speed page, click that button to manually load the walking speed data from the Health store to the app.

Once the app obtains the walking speed data, you will see three charts appear on the walking speed page. The charts depict the daily, weekly and monthly average walking speed data. You may click on any chart, and it will depict a detailed page for that chart. The detailed page shows the selected chart, and a table listing all the raw data for that chart. You may dismiss a detailed page by tapping on anywhere in that page.

There are a branch in this release:

* depictWalkingSpeed  

    Show the average walking speed charts based on a set of mocked data


## Version History

3/23/21  Created the SmoothWalker GitHub repository

         Created the depictWalkingSpeed branch

3/26/21  Checked-in updated code for Walking Speed feature.

3/27/21  Show all charts on the Walking Speed main page.

         When user taps on any chart, show a detailed page for that chart (chart and table).

         Added a Settings button in the error message dialog to re-direct user to the Settings app to authorize the app has access to the Health store.

         Show a Fetch button whenever user needs to manually fetch walking speed data from the Health store for the app.

3/28/21  Updated README and checked in final code.

         Created the depictLatestWalkingSpeed branch to fetch the real (last week) walking speed data from the Health store.

4/6/21   Merged the depictLatestWalkingSpeed branch to the main branch.

         Deleted the depictLatestWalkingSpeed branch.
