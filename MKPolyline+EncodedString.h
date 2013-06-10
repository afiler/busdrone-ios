//
//  MKPolyline+EncodedString.h
//  Busdrone
//
//  Created by andyf on 2013/06/05.
//  Copyright (c) 2013 Busdrone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKPolyline.h>

@interface MKPolyline(EncodedString)
+ (MKPolyline *)polylineWithEncodedString:(NSString *)encodedString;
@end
