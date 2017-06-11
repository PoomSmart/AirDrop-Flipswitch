#import "Header.h"
#import <Flipswitch/FSSwitchSettingsViewController.h>

@interface AirDropSwitchSettingsViewController : UITableViewController <FSSwitchSettingsViewController> {
	AirDropDiscoverableMode discoverableMode;
	BOOL showActionSheet;
	BOOL turnOffBluetooth;
}
+ (AirDropDiscoverableMode)defaultAirDropDiscoverableMode;
+ (BOOL)defaultShowActionSheet;
+ (BOOL)defaultTurnOffBluetooth;
@end
