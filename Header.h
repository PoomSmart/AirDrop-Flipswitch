#import "../../PS.h"

static CFStringRef tweakIdentifier = CFSTR("com.PS.AirDropSwitch");
static NSString *switchIdentifier = @"com.PS.AirDropToggle";
static CFStringRef discoverableKey = CFSTR("AirDropDiscoverableMode");
static CFStringRef showActionSheetKey = CFSTR("ShowAirDropActionSheet");
static CFStringRef turnOffBluetoothKey = CFSTR("AutoTurnBluetoothOff");
static NSString *sharingd = @"com.apple.sharingd";
static NSString *sharingdNotification = @"com.apple.sharingd.DiscoverableModeChanged";

@interface SFAirDropDiscoveryController : NSObject
@property NSInteger discoverableMode;
- (NSString *)discoverableModeToString:(NSInteger)mode;
- (NSInteger)operationDiscoverableModeToInteger:(NSString *)mode;
- (UIActionSheet *)discoverableModeActionSheet;
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSUInteger)index;
@end

@protocol airStuffDelegate
- (void)_airDropTapped:(id)arg1;
- (void)discoveryControllerSettingsDidChange:(SFAirDropDiscoveryController *)controller;
@end

@interface SBCCAirStuffSectionController : NSObject <airStuffDelegate>
@end

@interface CCUIAirStuffSectionController : NSObject <airStuffDelegate>
@end

@interface SBControlCenterViewController : UIViewController
@end

@interface CCUIControlCenterViewController : UIViewController
@end

@interface SBControlCenterController : NSObject
+ (SBControlCenterController *)sharedInstanceIfExists;
@end

@interface SBControlCenterContentView : UIView
@property(retain, nonatomic) SBCCAirStuffSectionController *airplaySection;
@end

typedef enum {
	AirDropDiscoverableModeEveryone = 2,
	AirDropDiscoverableModeContact = 1,
	AirDropDiscoverableModeOff = 0,
} AirDropDiscoverableMode;

//extern NSString *kSFOperationDiscoverableModeDisabled;
extern NSString *kSFOperationDiscoverableModeOff;
extern NSString *kSFOperationDiscoverableModeContactsOnly;
extern NSString *kSFOperationDiscoverableModeEveryone;
extern NSString *kSFOperationDiscoverableModeKey;
