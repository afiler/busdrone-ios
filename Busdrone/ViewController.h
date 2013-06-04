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

@interface ViewController : UIViewController <MKMapViewDelegate, SRWebSocketDelegate>

@end
