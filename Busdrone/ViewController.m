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
#import "MKPolyline+EncodedString.h"

@implementation ViewController {
    SRWebSocket *_webSocket;
    NSMutableDictionary *vehicles;
    NSMutableDictionary *tripPolylines;
    bool locationSet;
    MKUserTrackingBarButtonItem *trackingButton;
    NSString *selectedTripUid;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear");
    vehicles = [NSMutableDictionary dictionaryWithCapacity:1024];
    tripPolylines = [NSMutableDictionary dictionaryWithCapacity:32];
    
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 47.606395;
    zoomLocation.longitude= -122.333136;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 4000, 4000);
    
    [_mapView setRegion:viewRegion animated:YES];
    [_mapView setDelegate:self];
    [_mapView setAutoresizingMask:
     (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    //[_mapView setMapType:MKMapTypeHybrid];

    trackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:_mapView];
    
    [_toolbar setItems:[NSArray arrayWithObjects:trackingButton, nil] animated:YES];
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
    //_webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"ws://10.0.79.64:28741/"]]];
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
    } else if ([type isEqualToString:@"trip_polyline"]) {
        [self addTripPolylineWithEncodedString:[data objectForKey:@"polyline"] tripUid:[data objectForKey:@"trip_uid"]];
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
    //NSLog(@"Removing %@", uid);
    VehicleAnnotation *marker = [vehicles objectForKey:uid];
    
    if (marker) {
        [_mapView removeAnnotation:marker];
        [vehicles removeObjectForKey:uid];
    }
}

- (void)addTripPolylineWithEncodedString:(NSString *)encodedString tripUid:(NSString *)tripUid;
{
    NSLog(@"addTripPolylineWithEncodedString: %@, %@", tripUid, encodedString);
    MKPolyline *polyline = [MKPolyline polylineWithEncodedString:encodedString];
    NSLog(@"polyline: %@", polyline);
    [tripPolylines setObject:polyline forKey:tripUid];
    
    if (!selectedTripUid) return;
    [_mapView addOverlay:[tripPolylines objectForKey:selectedTripUid]];
}

- (void)requestTripPolyline:(NSString *)tripUid;
{
    NSLog(@"requestTripPolyline");
    
    MKPolyline *polyline = [tripPolylines objectForKey:tripUid];
    
    if (polyline) {
        [_mapView addOverlay:polyline];
    } else {
        NSMutableDictionary *request = [NSMutableDictionary dictionaryWithCapacity:4];
        
        [request setObject:@"type" forKey:@"trip_polyline"];
        [request setObject:tripUid forKey:@"trip_uid"];
        
        NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:request options:0 error:nil] encoding:NSUTF8StringEncoding];

        
        NSLog(@"JSON: %@", json);
        [_webSocket send:json];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view;
{
    NSLog(@"didSelectAnnotationView");
    if (![view.annotation isKindOfClass:[VehicleAnnotation class]]) return;
    VehicleAnnotation *annotation = (VehicleAnnotation*) view.annotation;
    
    [self requestTripPolyline:[annotation tripUid]];
    
    selectedTripUid = [annotation tripUid];
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    [_mapView removeOverlay:[tripPolylines objectForKey:selectedTripUid]];
    selectedTripUid = nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if (![annotation isKindOfClass:[VehicleAnnotation class]]) {
        NSLog(@"Is another class");
        return nil;
    }
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
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    MKPolylineView *view = [[MKPolylineView alloc] initWithOverlay:overlay];

    if ([overlay isKindOfClass:[MKPolyline class]]) {
        view.strokeColor = [UIColor grayColor];
        view.lineWidth = 3;
        
    }

    return view;
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

- (void)viewDidUnload {
    [self setMapView:nil];
    [self setToolbar:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
}
@end
