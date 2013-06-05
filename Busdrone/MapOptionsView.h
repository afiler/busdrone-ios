//
//  MapOptionsView.h
//  Busdrone
//
//  Created by andyf on 2013/06/04.
//  Copyright (c) 2013 Busdrone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKMapView;
@protocol MapOptionsViewDelegate;

@interface MapOptionsView : UIView

@property (nonatomic, retain) UISegmentedControl *segmentedControl;
@property (nonatomic, assign) CGFloat paddingTop;
@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, assign) id <MapOptionsViewDelegate> delegate;

@end

@protocol MapOptionsViewDelegate <NSObject>

- (void)mapOptionsViewDidCaptureTouchOnPaddingRegion:(MapOptionsView *)mapOptionsView;

@end