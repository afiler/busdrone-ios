//
//  ViewController.h
//  Busdrone
//
//  Created by andyf on 2013/06/03.
//  Copyright (c) 2013 Busdrone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "SRWebSocket.h"
#import <CoreLocation/CoreLocation.h>
#import "HoverToolbar.h"

@interface ViewController : UIViewController <MKMapViewDelegate, SRWebSocketDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet HoverToolbar *toolbar;

@end
