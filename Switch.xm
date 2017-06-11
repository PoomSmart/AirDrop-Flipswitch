#import <Flipswitch/FSSwitchDataSource.h>
#import <Flipswitch/FSSwitchPanel.h>
#import <Foundation/NSUserDefaults+Private.h>
#import "Header.h"
#import "Settings.h"

@interface AirDropSwitch : NSObject <FSSwitchDataSource>
@end

@implementation AirDropSwitch

- (NSString *)descriptionOfState:(FSSwitchState)state forSwitchIdentifier:(NSString *)switchIdentifier {
    return [AirDropSwitchSettingsViewController defaultShowActionSheet] ? @"Configuration" : state == FSSwitchStateOn ? @"On" : @"Off";
}

- (SBCCAirStuffSectionController *)sbAirDropController {
    SBControlCenterController *ccc = [%c(SBControlCenterController) sharedInstanceIfExists];
    if (ccc) {
        id ccvc = MSHookIvar<id>(ccc, "_viewController"); // CCUIControlCenterViewController (iOS 10) or SBControlCenterViewController (iOS 7-9)
        if (isiOS10Up)
            return MSHookIvar<SBCCAirStuffSectionController *>(MSHookIvar<id>(ccvc, "_systemControlsPage"), "_airStuffSection");
        else
            return MSHookIvar<SBControlCenterContentView *>(ccvc, "_contentView").airplaySection;
    }
    return nil;
}

- (SFAirDropDiscoveryController *)airDropController {
    if (self.sbAirDropController)
        return MSHookIvar<SFAirDropDiscoveryController *>(self.sbAirDropController, "_airDropDiscoveryController");
    return nil;
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier {
    if ([AirDropSwitchSettingsViewController defaultShowActionSheet])
        return FSSwitchStateOn;
    NSString *modeString = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:kSFOperationDiscoverableModeKey inDomain:sharingd];
    AirDropDiscoverableMode mode = modeString ? (AirDropDiscoverableMode)[self.airDropController operationDiscoverableModeToInteger:modeString] : AirDropDiscoverableModeContact;
    return mode != AirDropDiscoverableModeOff ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier {
    if (newState == FSSwitchStateIndeterminate)
        return;
    if (![AirDropSwitchSettingsViewController defaultShowActionSheet]) {
        self.airDropController.discoverableMode = newState == FSSwitchStateOn ? [AirDropSwitchSettingsViewController defaultAirDropDiscoverableMode] : AirDropDiscoverableModeOff;
        NSInteger mode = (NSInteger)(newState == FSSwitchStateOn ? [AirDropSwitchSettingsViewController defaultAirDropDiscoverableMode] : AirDropDiscoverableModeOff);
        NSString *modeString = [self.airDropController discoverableModeToString:mode];
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:sharingd];
        [defaults setObject:modeString forKey:kSFOperationDiscoverableModeKey inDomain:sharingd];
        [defaults synchronize];
        [defaults release];
        [[NSNotificationCenter defaultCenter] postNotificationName:sharingdNotification object:nil]; // kStatusDiscoverableModeChanged
    } else
        [self applyAlternateActionForSwitchIdentifier:switchIdentifier];
}

- (void)applyAlternateActionForSwitchIdentifier:(NSString *)switchIdentifier {
    [self.sbAirDropController _airDropTapped:nil];
}

@end

static void updateForAirDropStateChange(id <airStuffDelegate> self) {
    [[FSSwitchPanel sharedPanel] stateDidChangeForSwitchIdentifier:switchIdentifier];
    SFAirDropDiscoveryController *controller = MSHookIvar<SFAirDropDiscoveryController *>(self, "_airDropDiscoveryController");
    if ([AirDropSwitchSettingsViewController defaultTurnOffBluetooth] && controller.discoverableMode == AirDropDiscoverableModeOff)
        [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOff forSwitchIdentifier:@"com.a3tweaks.switch.bluetooth"];
}

%group iOS10Up

%hook CCUIAirStuffSectionController

- (void)_updateForAirDropStateChange {
    %orig;
    updateForAirDropStateChange(self);
}

%end

%end

%group preiOS10

%hook SBCCAirStuffSectionController

- (void)_updateForAirDropStateChange {
    %orig;
    updateForAirDropStateChange(self);
}

%end

%end

%ctor {
    if (isiOS10Up) {
        %init(iOS10Up)
    } else {
        %init(preiOS10);
    }
}
