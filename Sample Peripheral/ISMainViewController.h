//
//  ISMainViewController.h
//  Sample Peripheral
//
//  Created by ispluser on 1/28/14.
//  Copyright (c) 2014 ISC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ISMainViewController : UIViewController <CBPeripheralManagerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *advertisingSwitch;
@property (weak, nonatomic) IBOutlet UISlider *heartRateMeasurementSlider;
@property (weak, nonatomic) IBOutlet UISegmentedControl *heartRateSizeSeg;
@property CBPeripheralManager * peripheralManager;

@property CBMutableCharacteristic *heartRateMeasurement;
- (IBAction)startAdvertising:(id)sender;
@property CBMutableCharacteristic *bodySensorLocation;
- (IBAction)heartRateSliderValueChanged:(id)sender;
@property CBMutableService *heartRateService;
@property BOOL bluetoothEnabled;
@end
