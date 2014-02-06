//
//  ISMainViewController.m
//  Sample Peripheral
//
//  Created by ispluser on 1/28/14.
//  Copyright (c) 2014 ISC. All rights reserved.
//

#import "ISMainViewController.h"

@interface ISMainViewController ()

@end

@implementation ISMainViewController
{
    CBMutableCharacteristic *subscribedChar;
    CBCentral *connectedCentral;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        _bluetoothEnabled=NO;
        
        _peripheralManager =[[CBPeripheralManager alloc] initWithDelegate:self queue:nil ];
        
    }
    return self;
}
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    
    
    CBUUID *heartRateServiceUUID = [CBUUID UUIDWithString: @"0x180D"];
    
    CBUUID *heartRateMeasurementCharUUID = [CBUUID UUIDWithString: @"0x2A37"];
    
    CBUUID *bodySensorLocationUUID = [CBUUID UUIDWithString: @"0x2A38"];
    CBUUID *descriptorUUID1 = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    CBUUID *descriptorUUID2 = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
   
    
    
    self.heartRateMeasurement =[[CBMutableCharacteristic alloc] initWithType:heartRateMeasurementCharUUID
                                                                  properties:CBCharacteristicPropertyNotify
                                                                       value:nil permissions:CBAttributePermissionsReadable];
    
    CBMutableDescriptor *d1 = [[CBMutableDescriptor alloc]initWithType:descriptorUUID1 value:@"Heart Rate Measurement"];
    
    
    self.heartRateMeasurement.descriptors=@[d1];
   
    Byte b=0x02;
    self.bodySensorLocation =[[CBMutableCharacteristic alloc] initWithType:bodySensorLocationUUID
                                                                properties:CBCharacteristicPropertyRead
                                                                     value:[NSData dataWithBytes:&b length:1] permissions:CBAttributePermissionsReadable];
    
//    CBDescriptor *d2 = [[CBDescriptor alloc]init];
//    [d2 setValue:@"Body Sensor Location" forKey:@"title"];
//    self.bodySensorLocation.descriptors=@[d2];
  CBMutableDescriptor *d2 = [[CBMutableDescriptor alloc]initWithType:descriptorUUID2 value:@"Body Sensor Location"];
    
    
    
    
    self.bodySensorLocation.descriptors=@[d2];
    
    self.heartRateService = [[CBMutableService alloc] initWithType:heartRateServiceUUID primary:YES];
    self.heartRateService.characteristics=@[self.heartRateMeasurement,self.bodySensorLocation];
    
   
    [self.peripheralManager addService:self.heartRateService];
    self.bluetoothEnabled=YES;
    NSLog(@"peripheral started");
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"Heart Rate Peripheral Service";
   // self.peripheralManager =[[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];

    // Do any additional setup after loading the view from its nib.
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }
}
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error advertising: %@", [error localizedDescription]);
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request {
    
    if ([request.characteristic.UUID isEqual:self.bodySensorLocation.UUID]) {
        
        if (request.offset > self.bodySensorLocation.value.length) {
            [self.peripheralManager respondToRequest:request
                                       withResult:CBATTErrorInvalidOffset];
            return;
        }
        request.value = [self.bodySensorLocation.value
                         subdataWithRange:NSMakeRange(request.offset,
                                                      self.bodySensorLocation.value.length - request.offset)];
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        
        
    }
    else if ([request.characteristic.UUID isEqual:self.heartRateMeasurement.UUID])
    {
        if (request.offset > self.heartRateMeasurement.value.length) {
            [self.peripheralManager respondToRequest:request
                                          withResult:CBATTErrorInvalidOffset];
            return;
        }
        self.heartRateMeasurement.value=[self calculateHeartRate];
        request.value = [self.heartRateMeasurement.value
                         subdataWithRange:NSMakeRange(request.offset,
                                                      self.heartRateMeasurement.value.length - request.offset)];
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveWriteRequests:(NSArray *)requests {

    
    [self.peripheralManager respondToRequest:[requests objectAtIndex:0]
                               withResult:CBATTErrorWriteNotPermitted];
}

-(NSData *)calculateHeartRate
{
    NSData *d;
    if (self.heartRateSizeSeg.selectedSegmentIndex==0) {
        //8bit
        
        UInt8 h=[[ NSNumber numberWithFloat:self.heartRateMeasurementSlider.value] intValue];
        
        Byte buffer[2];
        buffer[0]=0;
        buffer[1]=h;
        
        
        
        d=[NSData dataWithBytes:buffer length:2];
        
        
    }
    else
    {
        //16bit
        UInt16 h=[[ NSNumber numberWithFloat:self.heartRateMeasurementSlider.value] intValue];
        
        Byte buffer[3];
        buffer[0]=1;
        buffer[1]=h & 0xff;
        buffer[2]=(h >> 8);
 
        d=[NSData dataWithBytes:buffer length:3];

    }
    NSLog(@"%@",d);
    return d;
    
    
}



- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
                    didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
     NSLog(@"%@ %@",characteristic.UUID,self.heartRateMeasurement.UUID);
    
    if ([characteristic.UUID isEqual:self.heartRateMeasurement.UUID]) {
        subscribedChar=(CBMutableCharacteristic*)characteristic;
        connectedCentral=central;
        NSLog(@"Central subscribed to characteristic %@", characteristic);
        NSData *updatedValue = [self calculateHeartRate];
        subscribedChar.value=updatedValue;
        BOOL didSendValue = [self.peripheralManager updateValue:updatedValue
                                              forCharacteristic:subscribedChar onSubscribedCentrals:@[connectedCentral]];
        NSLog(@"Central subscribed to  %@", characteristic);
        NSLog(@"value sent:%hhd",didSendValue);
    }
}
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
     NSData *updatedValue = [self calculateHeartRate];
    subscribedChar.value=updatedValue;
    BOOL didSendValue = [self.peripheralManager updateValue:updatedValue
                                          forCharacteristic:subscribedChar onSubscribedCentrals:@[connectedCentral]];
    
    NSLog(@"value sent:%hhd",didSendValue);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startAdvertising:(id)sender {
    if (self.bluetoothEnabled==YES) {
        
    
    if(self.advertisingSwitch.on==YES)
    {
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey :
                                                 @[self.heartRateService.UUID] ,
                                                CBAdvertisementDataLocalNameKey: @"Sample Peripheral Device"}];
        NSLog(@"Advertising started");
    }
    else
    {

        [self.peripheralManager stopAdvertising];
                NSLog(@"Advertising stopped");
    }
    }
}
- (IBAction)heartRateSliderValueChanged:(id)sender {
    NSData *updatedValue = [self calculateHeartRate];
    NSLog(@"%@",subscribedChar.UUID);
    subscribedChar.value=updatedValue;
    BOOL didSendValue = [self.peripheralManager updateValue:updatedValue
                                          forCharacteristic:subscribedChar onSubscribedCentrals:@[connectedCentral]];
    
    NSLog(@"value sent:%hhd",didSendValue);
}
@end
