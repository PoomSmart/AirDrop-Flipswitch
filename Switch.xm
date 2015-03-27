#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import "FSSwitchSettingsViewController.h"
#import "../PS.h"

CFStringRef tweakIdentifier = CFSTR("com.PS.AirDropSwitch");
NSString *switchIdentifier = @"com.PS.AirDropToggle";
CFStringRef discoverableKey = CFSTR("AirDropDiscoverableMode");
CFStringRef showActionSheetKey = CFSTR("ShowAirDropActionSheet");
CFStringRef turnOffBluetoothKey = CFSTR("AutoTurnBluetoothOff");
NSString *sharingd = @"com.apple.sharingd";
NSString *sharingdNotification = @"com.apple.sharingd.DiscoverableModeChanged";

typedef enum {
	AirDropDiscoverableModeEveryone = 2,
	AirDropDiscoverableModeContact = 1,
	AirDropDiscoverableModeOff = 0,
} AirDropDiscoverableMode;

static AirDropDiscoverableMode defaultAirDropDiscoverableMode()
{
	CFPreferencesAppSynchronize(tweakIdentifier);
	Boolean valid;
	CFIndex value = CFPreferencesGetAppIntegerValue(discoverableKey, tweakIdentifier, &valid);
	return valid ? (AirDropDiscoverableMode)value : AirDropDiscoverableModeEveryone;
}

static BOOL defaultShowActionSheet()
{
	CFPreferencesAppSynchronize(tweakIdentifier);
	Boolean valid;
	Boolean value = CFPreferencesGetAppBooleanValue(showActionSheetKey, tweakIdentifier, &valid);
	return valid ? value : NO;
}

static BOOL defaultTurnOffBluetooth()
{
	CFPreferencesAppSynchronize(tweakIdentifier);
	Boolean valid;
	Boolean value = CFPreferencesGetAppBooleanValue(turnOffBluetoothKey, tweakIdentifier, &valid);
	return valid ? value : NO;
}

//extern NSString *kSFOperationDiscoverableModeDisabled;
extern NSString *kSFOperationDiscoverableModeOff;
extern NSString *kSFOperationDiscoverableModeContactsOnly;
extern NSString *kSFOperationDiscoverableModeEveryone;
extern NSString *kSFOperationDiscoverableModeKey;

@interface AirDropSwitch : NSObject <FSSwitchDataSource>
@end

@interface AirDropSwitchSettingsViewController : UITableViewController <FSSwitchSettingsViewController> {
	AirDropDiscoverableMode discoverableMode;
	BOOL showActionSheet;
	BOOL turnOffBluetooth;
}
@end

@interface SFAirDropDiscoveryController : NSObject
@property NSInteger discoverableMode;
- (NSString *)discoverableModeToString:(NSInteger)mode;
- (NSInteger)operationDiscoverableModeToInteger:(NSString *)mode;
- (UIActionSheet *)discoverableModeActionSheet;
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSUInteger)index;
@end

@interface SBCCAirStuffSectionController : NSObject
- (void)_airDropTapped:(id)arg1;
- (void)discoveryControllerSettingsDidChange:(SFAirDropDiscoveryController *)controller;
@end

@interface SBControlCenterViewController : UIViewController
@end

@interface SBControlCenterController : NSObject
+ (SBControlCenterController *)sharedInstanceIfExists;
@end

@interface SBControlCenterContentView : UIView
@property(retain, nonatomic) SBCCAirStuffSectionController *airplaySection;
@end

@implementation AirDropSwitch

- (NSString *)descriptionOfState:(FSSwitchState)state forSwitchIdentifier:(NSString *)switchIdentifier
{
	return defaultShowActionSheet() ? @"Configuration" : state == FSSwitchStateOn ? @"On" : @"Off";
}

- (SBCCAirStuffSectionController *)sbAirDropController
{
	SBControlCenterController *ccc = [%c(SBControlCenterController) sharedInstanceIfExists];
	if (ccc) {
		SBControlCenterViewController *ccvc = MSHookIvar<SBControlCenterViewController *>(ccc, "_viewController");
		if (ccvc) {
			SBControlCenterContentView *ccv = MSHookIvar<SBControlCenterContentView *>(ccvc, "_contentView");
			return ccv.airplaySection;
		}
	}
	return nil;
}

- (SFAirDropDiscoveryController *)airDropController
{
	if (self.sbAirDropController)
		return MSHookIvar<SFAirDropDiscoveryController *>(self.sbAirDropController, "_airDropDiscoveryController");
	return nil;
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
	if (defaultShowActionSheet())
		return FSSwitchStateOn;
	NSString *modeString = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:kSFOperationDiscoverableModeKey inDomain:sharingd];
	AirDropDiscoverableMode mode = modeString ? (AirDropDiscoverableMode)[self.airDropController operationDiscoverableModeToInteger:modeString] : AirDropDiscoverableModeContact;
	return mode != AirDropDiscoverableModeOff ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
	if (newState == FSSwitchStateIndeterminate)
		return;
	if (!defaultShowActionSheet()) {
		self.airDropController.discoverableMode = newState == FSSwitchStateOn ? defaultAirDropDiscoverableMode() : AirDropDiscoverableModeOff;
		NSInteger mode = (NSInteger)(newState == FSSwitchStateOn ? defaultAirDropDiscoverableMode() : AirDropDiscoverableModeOff);
		NSString *modeString = [self.airDropController discoverableModeToString:mode];
		NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:sharingd];
		[defaults setObject:modeString forKey:kSFOperationDiscoverableModeKey inDomain:sharingd];
		[defaults synchronize];
		[defaults release];
		[[NSNotificationCenter defaultCenter] postNotificationName:sharingdNotification object:nil]; // kStatusDiscoverableModeChanged
	}
	else
		[self applyAlternateActionForSwitchIdentifier:switchIdentifier];
}

- (void)applyAlternateActionForSwitchIdentifier:(NSString *)switchIdentifier
{
	[self.sbAirDropController _airDropTapped:nil];
}

@end

@implementation AirDropSwitchSettingsViewController

- (id)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		discoverableMode = defaultAirDropDiscoverableMode();
		showActionSheet = defaultShowActionSheet();
		turnOffBluetooth = defaultTurnOffBluetooth();
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table
{
	return 3;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"Default discoverable mode when enabled";
		case 1:
			return @"Show available discoverable modes page";
		case 2:
			return @"Auto turn off Bluetooth when disabled";
	}
	return nil;
}

- (NSString *)titleForIndex:(AirDropDiscoverableMode)index
{
	switch (index) {
		case AirDropDiscoverableModeEveryone:
			return kSFOperationDiscoverableModeEveryone;
		case AirDropDiscoverableModeContact:
			return kSFOperationDiscoverableModeContactsOnly;
		case AirDropDiscoverableModeOff:
			return kSFOperationDiscoverableModeOff;
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return section == 0 ? 2 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"] autorelease];
	cell.textLabel.text = indexPath.section == 0 ? [self titleForIndex:(AirDropDiscoverableMode)(indexPath.row + 1)] : @"Enabled";
	if (indexPath.section == 0)
		cell.accessoryType = (discoverableMode == (indexPath.row + 1)) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	else {
		switch (indexPath.section) {
			case 1:
				cell.accessoryType = showActionSheet ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case 2:
				cell.accessoryType = turnOffBluetooth ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
		}
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSInteger section = indexPath.section;
	NSInteger value = indexPath.row;
	CFStringRef key;
	switch (section) {
		case 0:
			key = discoverableKey;
			discoverableMode = (AirDropDiscoverableMode)(value + 1);
			for (NSInteger i = 0; i < ([self tableView:tableView numberOfRowsInSection:section]); i++) {
				[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]].accessoryType = (value == i) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			}
			CFPreferencesSetAppValue(key, (CFTypeRef)[NSNumber numberWithInteger:discoverableMode], tweakIdentifier);
			break;
		case 1:
			key = showActionSheetKey;
			showActionSheet = !defaultShowActionSheet();
			[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].accessoryType = showActionSheet ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			CFPreferencesSetAppValue(key, (CFTypeRef)[NSNumber numberWithBool:showActionSheet], tweakIdentifier);
			break;
		case 2:
			key = turnOffBluetoothKey;
			turnOffBluetooth = !defaultTurnOffBluetooth();
			[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]].accessoryType = turnOffBluetooth ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			CFPreferencesSetAppValue(key, (CFTypeRef)[NSNumber numberWithBool:turnOffBluetooth], tweakIdentifier);
			break;
	}
	CFPreferencesAppSynchronize(tweakIdentifier);
}

@end

%hook SBCCAirStuffSectionController

- (void)_updateForAirDropStateChange
{
	%orig;
	[[FSSwitchPanel sharedPanel] stateDidChangeForSwitchIdentifier:switchIdentifier];
	SFAirDropDiscoveryController *controller = MSHookIvar<SFAirDropDiscoveryController *>(self, "_airDropDiscoveryController");
	if (defaultTurnOffBluetooth() && controller.discoverableMode == AirDropDiscoverableModeOff) {
		[[FSSwitchPanel sharedPanel] setState:FSSwitchStateOff forSwitchIdentifier:@"com.a3tweaks.switch.bluetooth"];
	}
}

%end