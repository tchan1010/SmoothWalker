//
//  WalkingSpeedTimeline.swift
//  SmoothWalker
//
//  Created by Terence Chan on 3/24/21.
//  Copyright © 2021 Apple. All rights reserved.
//
// Utility functions to support the display of different
// timelines for average walking speed
//
import Foundation

enum Timeline : String, CaseIterable  {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

let DISPLAY_TIMELINE = "DisplayTimeLine"

//
// save user-selected display timeline for walking speed
//
internal func saveUserSelectedTimeline(_ timeline : Timeline) {
    
    UserDefaults.standard.set(timeline.rawValue, forKey:DISPLAY_TIMELINE)
}

//
// restore any user-selected display timeline for walking speed
//
internal func restoreUserSelectedTimeline() -> Timeline {
    
    /* restore the last user-selected display timeline */
    if let strTimeline = UserDefaults.standard.string(forKey:DISPLAY_TIMELINE) {
        return Timeline(rawValue: strTimeline) ?? .daily
    }
    return .daily
}
