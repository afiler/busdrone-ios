//
//  ViewController.m
//  Busdrone
//
//  Created by andyf on 2013/06/03.
//  Copyright (c) 2013 Busdrone. All rights reserved.
//

#import "ViewController.h"
#import "SRWebSocket.h"
#import "VehicleAnnotation.h"
#import "VehicleAnnotationView.h"
#import "MapOptionsView.h"

@implementation ViewController {
    SRWebSocket *_webSocket;
    NSMutableDictionary *vehicles;
    bool locationSet;
    MKUserTrackingBarButtonItem *trackingButton;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear");
    vehicles = [NSMutableDictionary dictionaryWithCapacity:1024];
    
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 47.606395;
    zoomLocation.longitude= -122.333136;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 4000, 4000);
    
    [_mapView setRegion:viewRegion animated:YES];
    [_mapView setDelegate:self];
    //[_mapView setMapType:MKMapTypeHybrid];

    trackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:_mapView];
    
    MapOptionsView *optionsView = [[MapOptionsView alloc] initWithFrame:self.view.bounds];
    [optionsView setPaddingTop:round(CGRectGetHeight(self.view.frame)/2.0f)];
    [optionsView setMapView:self.mapView];
    [optionsView setDelegate:self];
    [optionsView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    self.optionsView = optionsView;
    [self.view insertSubview:self.optionsView belowSubview:self.mapView];
    
    FDCurlViewControl *curlButton = [[FDCurlViewControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 30.0f, 30.0f)];
    [curlButton setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [curlButton setHidesWhenAnimating:NO];
    [curlButton setTargetView:self.mapView];
    UIBarButtonItem *curlButtonItem = [[UIBarButtonItem alloc] initWithCustomView:curlButton];
    self.curlButton = curlButton;
    UIBarButtonItem *spacerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    
    
    [_toolbar setItems:[NSArray arrayWithObjects:trackingButton, spacerItem, curlButtonItem, nil] animated:YES];
    [_toolbar setTranslucent:YES];
    
    [self reconnect];
    
    self.locationManager = [[CLLocationManager alloc] init];
    if ( [CLLocationManager locationServicesEnabled] ) {
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = 1000;
        [self.locationManager startUpdatingLocation];
    }
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(disconnect)
     name:UIApplicationWillResignActiveNotification
     object:NULL];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(reconnect)
     name:UIApplicationDidBecomeActiveNotification
     object:NULL];
}

- (void)reconnect;
{
    NSLog(@"Reconnecting");
    _webSocket.delegate = nil;
    [_webSocket close];
    
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"ws://busdrone.com:28737/"]]];
    _webSocket.delegate = self;
    
    [_webSocket open];
    
}

- (void)disconnect;
{
    NSLog(@"Disconnecting");
    [_webSocket close];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket connected");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@"Websocket failed with error: %@", error);
    
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    NSError *jsonParsingError = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:&jsonParsingError];
    if (jsonParsingError) return;
    
    NSString *type = [data objectForKey:@"type"];
    if ([type isEqualToString:@"init"]) {
        //NSLog(@"message: init");
        for (NSDictionary *vehicle in [data objectForKey:@"vehicles"]) {
            [self addOrUpdateVehicle:vehicle];
        }
    } else if ([type isEqualToString:@"update_vehicle"]) {
        //NSLog(@"message: update_vehicle");
        [self addOrUpdateVehicle:[data objectForKey:@"vehicle"]];
    } else if ([type isEqualToString:@"remove_vehicle"]) {
        //NSLog(@"message: remove_vehicle");
        [self removeMarker:[data objectForKey:@"vehicle_uid"]];
    }
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    _webSocket = nil;
}

- (void)addOrUpdateVehicle:(NSDictionary *)vehicleUpdateDict;
{
    NSString *uid = [vehicleUpdateDict objectForKey:@"uid"];
    NSString *newRoute = [vehicleUpdateDict objectForKey:@"route"];
    NSString *newColor = [vehicleUpdateDict objectForKey:@"color"];
    
    VehicleAnnotation *v = [vehicles objectForKey:uid];
    
    if (v && [v.route isEqualToString:newRoute] && [v.color isEqualToString:newColor]) {
        [v updateWithDict:vehicleUpdateDict];
    } else {    
        if (v) [self removeMarker:uid];
            
        v = [[VehicleAnnotation alloc] initWithDict:vehicleUpdateDict];
        [vehicles setObject:v forKey:uid];
        [_mapView addAnnotation:v];
    }
}

- (void)removeMarker:(NSString *)uid;
{
    NSLog(@"Removing %@", uid);
    VehicleAnnotation *marker = [vehicles objectForKey:uid];
    
    if (marker) {
        [_mapView removeAnnotation:marker];
        [vehicles removeObjectForKey:uid];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if (![annotation isKindOfClass:[VehicleAnnotation class]]) return nil;
    
    VehicleAnnotation *v = (VehicleAnnotation *)annotation;
    
    NSString *VehicleAnnotationIdentifier = [v getAnnotationIdentifier];
    
    VehicleAnnotationView *annotationView =
        (VehicleAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:VehicleAnnotationIdentifier];
    if (annotationView == nil)
    {
        annotationView = [[VehicleAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:VehicleAnnotationIdentifier];
        annotationView.canShowCallout = YES;
    }
    return annotationView;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    if (locationSet) return;
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
    
    [self.mapView setRegion:region animated:YES];
    self.mapView.showsUserLocation = YES;
    locationSet = true;
}

- (void) checkMapFitsNeatly {
    MKMapRect currentRect = _mapView.visibleMapRect;
    MKMapPoint bottomRight = MKMapPointMake(currentRect.size.width+currentRect.origin.x, currentRect.size.height+currentRect.origin.y);
    
    CLLocationCoordinate2D bottomRightCoordinate = MKCoordinateForMapPoint(bottomRight);
    
    if ((bottomRightCoordinate.latitude<-85)||(bottomRightCoordinate.longitude>180)) {
        // map is showing grey areas, adjust
        float deltaLatitude = fminf(-85-bottomRightCoordinate.latitude,0);
        float deltaLongitude = fmaxf(bottomRightCoordinate.longitude-180,0);
        CLLocationCoordinate2D topLeftCoordinate = MKCoordinateForMapPoint(MKMapPointMake(currentRect.origin.x, currentRect.origin.y));
        CLLocationCoordinate2D newTopLeftCoordinate = CLLocationCoordinate2DMake(topLeftCoordinate.latitude+deltaLatitude,topLeftCoordinate.longitude-deltaLongitude);
        MKMapPoint newTopLeftVisiblePoint = MKMapPointForCoordinate(newTopLeftCoordinate);
        MKMapRect newMapRect = currentRect;
        newMapRect.origin = newTopLeftVisiblePoint;
        [_mapView setVisibleMapRect:newMapRect];
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self checkMapFitsNeatly];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    
    return YES;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark CurlMapOptionsViewDelegate methods
- (void)mapOptionsViewDidCaptureTouchOnPaddingRegion:(MapOptionsView *)mapOptionsView {
    [self.curlButton curlViewDown];
}

- (void)viewDidUnload {
    [self setMapView:nil];
    [self setToolbar:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
}
@end
