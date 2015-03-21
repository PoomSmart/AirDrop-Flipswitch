#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import "FSSwitchSettingsViewController.h"
#import "../PS.h"

CFStringRef tweakIdentifier = CFSTR("com.PS.AirDropSwitch");
NSString *switchIdentifier = @"com.PS.AirDropToggle";
CFStringRef discoverableKey = CFSTR("AirDropDiscoverableMode");
CFStringRef showActionSheetKey = CFSTR("ShowAirDropActionSheet");

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

//extern NSString *kSFOperationDiscoverableModeDisabled;
extern NSString *kSFOperationDiscoverableModeOff;
extern NSString *kSFOperationDiscoverableModeContactsOnly;
extern NSString *kSFOperationDiscoverableModeEveryone;

@interface AirDropSwitch : NSObject <FSSwitchDataSource>
@end

@interface AirDropSwitchSettingsViewController : UITableViewController <FSSwitchSettingsViewController> {
	AirDropDiscoverableMode discoverableMode;
	BOOL showActionSheet;
}
@end

@interface SFAirDropDiscoveryController : NSObject
@property NSInteger discoverableMode;
- (NSString *)discoverableModeToString:(NSInteger)mode;
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
	return nil;
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
	return self.airDropController.discoverableMode != AirDropDiscoverableModeOff ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
	if (newState == FSSwitchStateIndeterminate)
		return;
	if (!defaultShowActionSheet())
		self.airDropController.discoverableMode = newState == FSSwitchStateOn ? defaultAirDropDiscoverableMode() : AirDropDiscoverableModeOff;
	else
		[self.sbAirDropController _airDropTapped:nil];
}

@end

@implementation AirDropSwitchSettingsViewController

- (id)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		discoverableMode = defaultAirDropDiscoverableMode();
		showActionSheet = defaultShowActionSheet();
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table
{
	return 2;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"Default discoverable mode when enabled";
		case 1:
			return @"Show available discoverable modes page";
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
	else
		cell.accessoryType = showActionSheet ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSInteger section = indexPath.section;
	NSInteger value = indexPath.row;
	CFStringRef key;
	if (section == 0) {
		key = discoverableKey;
		discoverableMode = (AirDropDiscoverableMode)(value + 1);
	} else {
		key = showActionSheetKey;
		showActionSheet = !defaultShowActionSheet();
	}
	if (section == 0) {
		for (NSInteger i = 0; i < ([self tableView:tableView numberOfRowsInSection:section]); i++) {
			[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]].accessoryType = (value == i) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		}
	} else
		[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].accessoryType = showActionSheet ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	CFPreferencesSetAppValue(key, section == 0 ? (CFTypeRef)[NSNumber numberWithInteger:discoverableMode] : (CFTypeRef)[NSNumber numberWithBool:showActionSheet], tweakIdentifier);
	CFPreferencesAppSynchronize(tweakIdentifier);
}

@end

%hook SBCCAirStuffSectionController

- (void)_updateAirDropControlAsEnabled:(BOOL)enabled
{
	%orig;
	[[FSSwitchPanel sharedPanel] stateDidChangeForSwitchIdentifier:switchIdentifier];
}

%end