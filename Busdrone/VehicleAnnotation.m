//
//  Vehicle.m
//  Busdrone
//
//  Created by andyf on 2013/06/03.
//  Copyright (c) 2013 Busdrone. All rights reserved.
//

#import "VehicleAnnotation.h"

@implementation VehicleAnnotation

- (id)initWithDict:(NSDictionary *)dict {
    if ((self = [super init])) {
        [self updateWithDict:dict];
    }
    return self;
}

- (void)updateWithDict:(NSDictionary *)dict {
    _uid = [dict objectForKey:@"uid"];
    _route = [dict objectForKey:@"route"];
    _destination = [dict objectForKey:@"destination"];
    _color = [dict objectForKey:@"color"];
    
    CLLocationCoordinate2D newCoordinate;
    newCoordinate.latitude =  [[dict objectForKey:@"lat"] doubleValue];
    newCoordinate.longitude = [[dict objectForKey:@"lon"] doubleValue];
    [self setCoordinate:newCoordinate];
}

- (NSString *)title {
    return _route;
    //return [NSString stringWithFormat:@"[%@] %@", _route, _uid];
}

- (NSString *)subtitle {
    return _destination;
}

- (CLLocationCoordinate2D)coordinate {
    return _coordinate;
}

- (NSString *)getAnnotationIdentifier {
    return [NSString stringWithFormat:@"%@/%@", _route, _color];
}

@end
