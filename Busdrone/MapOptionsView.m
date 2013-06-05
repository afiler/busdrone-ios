//
//  MapOptionsView.m
//  Busdrone
//
//  Created by andyf on 2013/06/04.
//  Copyright (c) 2013 Busdrone. All rights reserved.
//

#import "MapOptionsView.h"
#import <MapKit/MKMapView.h>

static CGFloat const kOffset = 10.0f;

@implementation MapOptionsView

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
		[self setBackgroundColor:[UIColor grayColor]];
		
		UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
												[NSArray arrayWithObjects:
												 NSLocalizedString(@"Standard", nil),
												 NSLocalizedString(@"Satelite", nil),
												 NSLocalizedString(@"Hybrid", nil),
												 nil]];
		[segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
		[segmentedControl setTintColor:self.backgroundColor];
		[segmentedControl setSelectedSegmentIndex:0];
		[segmentedControl addTarget:self
							 action:@selector(changeMapViewType)
				   forControlEvents:UIControlEventValueChanged];
		[self addSubview:segmentedControl];
		self.segmentedControl = segmentedControl;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGFloat height = self.paddingTop;
	
	
	NSString *text = NSLocalizedString(@"Use this space to show any information or other controls related to the curled view, on this example we use it to present a segmented control to select the mapView type.", nil);
	UIFont *textFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	UILineBreakMode textLineBreakMode = UILineBreakModeWordWrap;
	UITextAlignment textAlignment = UITextAlignmentCenter;
	CGRect textRect = CGRectMake(kOffset, height + kOffset, CGRectGetWidth(self.frame) - 2 * kOffset, MAXFLOAT);
	CGSize textSize = [text sizeWithFont:textFont
					   constrainedToSize:textRect.size
						   lineBreakMode:textLineBreakMode];
	textRect.size.height = textSize.height;
	[text drawInRect:textRect
			withFont:textFont
	   lineBreakMode:textLineBreakMode
		   alignment:textAlignment];
	
	height = CGRectGetMaxY(textRect);
	
	CGRect segmentedControlFrame = self.segmentedControl.frame;
	segmentedControlFrame.origin.y = height + kOffset;
	segmentedControlFrame.size.width = MAX(CGRectGetWidth(segmentedControlFrame), (CGRectGetWidth(self.frame) - 2 * kOffset)/1.5f);
	segmentedControlFrame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(segmentedControlFrame)) / 2.0f;
	self.segmentedControl.frame = CGRectIntegral(segmentedControlFrame);
}

- (void)changeMapViewType {
	[self.mapView setMapType:self.segmentedControl.selectedSegmentIndex];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	for (UITouch *touch in touches) {
		CGPoint point = [touch locationInView:self];
		if (point.y < self.paddingTop) {
			if ([self.delegate respondsToSelector:@selector(mapOptionsViewDidCaptureTouchOnPaddingRegion:)]) {
				[self.delegate mapOptionsViewDidCaptureTouchOnPaddingRegion:self];
			}
		}
	}
}

@end
