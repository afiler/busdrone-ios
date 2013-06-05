//
//  Vehicle.h
//  Busdrone
//
//  Created by andyf on 2013/06/03.
//  Copyright (c) 2013 Busdrone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface VehicleAnnotation : NSObject <MKAnnotation>

@property (nonatomic, copy) NSString *route;
@property (nonatomic, copy) NSString *destination;
@property (nonatomic, copy) NSString *color;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

- (id)initWithDict:(NSDictionary*)dict;
- (void)updateWithDict:(NSDictionary *)dict;
- (NSString *)getAnnotationIdentifier;

@end