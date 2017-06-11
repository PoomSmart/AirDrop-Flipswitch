#import "Header.h"
#import "Settings.h"

@implementation AirDropSwitchSettingsViewController

+ (AirDropDiscoverableMode)defaultAirDropDiscoverableMode {
    CFPreferencesAppSynchronize(tweakIdentifier);
    Boolean valid;
    CFIndex value = CFPreferencesGetAppIntegerValue(discoverableKey, tweakIdentifier, &valid);
    return valid ? (AirDropDiscoverableMode)value : AirDropDiscoverableModeEveryone;
}

+ (BOOL)defaultShowActionSheet {
    CFPreferencesAppSynchronize(tweakIdentifier);
    Boolean valid;
    Boolean value = CFPreferencesGetAppBooleanValue(showActionSheetKey, tweakIdentifier, &valid);
    return valid ? value : NO;
}

+ (BOOL)defaultTurnOffBluetooth {
    CFPreferencesAppSynchronize(tweakIdentifier);
    Boolean valid;
    Boolean value = CFPreferencesGetAppBooleanValue(turnOffBluetoothKey, tweakIdentifier, &valid);
    return valid ? value : NO;
}

- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        discoverableMode = [[self class] defaultAirDropDiscoverableMode];
        showActionSheet = [[self class] defaultShowActionSheet];
        turnOffBluetooth = [[self class] defaultTurnOffBluetooth];
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 3;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section {
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

- (NSString *)titleForIndex:(AirDropDiscoverableMode)index {
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 2 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ? : [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"] autorelease];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger section = indexPath.section;
    NSInteger value = indexPath.row;
    CFStringRef key;
    switch (section) {
        case 0:
            key = discoverableKey;
            discoverableMode = (AirDropDiscoverableMode)(value + 1);
            for (NSInteger i = 0; i < ([self tableView:tableView numberOfRowsInSection:section]); i++)
                [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]].accessoryType = (value == i) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            CFPreferencesSetAppValue(key, (CFTypeRef)[NSNumber numberWithInteger:discoverableMode], tweakIdentifier);
            break;
        case 1:
            key = showActionSheetKey;
            showActionSheet = ![[self class] defaultShowActionSheet];
            [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].accessoryType = showActionSheet ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            CFPreferencesSetAppValue(key, (CFTypeRef)[NSNumber numberWithBool:showActionSheet], tweakIdentifier);
            break;
        case 2:
            key = turnOffBluetoothKey;
            turnOffBluetooth = ![[self class] defaultTurnOffBluetooth];
            [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]].accessoryType = turnOffBluetooth ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            CFPreferencesSetAppValue(key, (CFTypeRef)[NSNumber numberWithBool:turnOffBluetooth], tweakIdentifier);
            break;
    }
    CFPreferencesAppSynchronize(tweakIdentifier);
}

@end
