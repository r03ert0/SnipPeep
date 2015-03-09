//
//  MyChromoView.m
//  SnipPeep
//
//  Created by roberto on 18/02/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MyChromoView.h"


@implementation MyChromoView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
    }
    return self;
}

- (void)drawChromosomeInRect:(NSRect)rect
{
	NSEraseRect(rect);
}

@end
