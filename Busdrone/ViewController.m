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


@interface ViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation ViewController {
    SRWebSocket *_webSocket;
    NSMutableDictionary *vehicles;
}

- (void)viewWillAppear:(BOOL)animated {
    vehicles = [NSMutableDictionary dictionaryWithCapacity:1024];
    
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 47.606395;
    zoomLocation.longitude= -122.333136;
    
    // 2
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 1000, 1000);
    
    // 3
    [_mapView setRegion:viewRegion animated:YES];
    [_mapView setDelegate:self];
    
    [self _reconnect];
}

- (void)_reconnect;
{
    _webSocket.delegate = nil;
    [_webSocket close];
    
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"ws://busdrone.com:28737/"]]];
    _webSocket.delegate = self;
    
    [_webSocket open];
    
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    
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
        [self removeMarker:[data objectForKey:@"uid"]];
    }
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    _webSocket = nil;
}

- (void)addOrUpdateVehicle:(NSDictionary *)vehicleUpdateDict;
{
    /*GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake([[vehicle objectForKey:@"lat"] doubleValue],
                                                 [[vehicle objectForKey:@"lon"] doubleValue]);
    marker.title = [vehicle objectForKey:@"route"];
    marker.snippet = [vehicle objectForKey:@"destination"];
    marker.map = mapView_;*/
    
    
    NSString *uid = [vehicleUpdateDict objectForKey:@"uid"];
    
    //NSLog(@"Got UID %@", uid);
    
    VehicleAnnotation *v = [vehicles objectForKey:uid];
    
    if (v) {
        //NSLog(@"Moving %@", uid);
        [v updateWithDict:vehicleUpdateDict];
    } else {
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
    
    static NSString *VehicleAnnotationIdentifier = @"vehicleAnnotationIdentifier";
    
    VehicleAnnotationView *annotationView =
        (VehicleAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:VehicleAnnotationIdentifier];
    if (annotationView == nil)
    {
        annotationView = [[VehicleAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:VehicleAnnotationIdentifier];
    }
    return annotationView;
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

@end
