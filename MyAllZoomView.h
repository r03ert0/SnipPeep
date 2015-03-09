//
//  MyAllZoomView.h
//  SnipPeep
//
//  Created by roberto on 06/02/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "common.h"

#define kLeft	1
#define kRight	2
#define kMove	3

@interface MyAllZoomView : NSView
{
	NSDocument	*parent;
	int			chromosome;
	
	NSMutableArray		*allcn;
	int			maxpos;
	int			nsnp;
	int			nsub;
	int			*LUT;		// this vector keeps a table relating subject index and position in the subjects table
	int			*hhist,*vhist,hmax,vmax;
	int			loadingStatus;
	int			L,R,mode;
	float		old;
	int			selectedSubjectIndex;
	int			filter;

	IBOutlet NSMatrix		*displaySettings;
	int			chromosomeHeight;
}
-(IBAction)updateDisplay:(id)sender;
-(void)setCNs:(NSMutableArray*)theCNs maxpos:(int)maxpos nsub:(int)theNsub;
-(void)setLoadingStatus:(BOOL)theStatus;
-(int)loadingStatus;
-(void)zoom:(NSNotification*)n;
-(void)changeSubject:(NSNotification*)n;
-(int*)LUT;
-(int)filter;
-(void)setFilter:(int)theFilterValue;
-(NSDocument*)parent;
-(void)setParent:(NSDocument*)theParent;
-(void)setChromosome:(int)aChromosome;
@end
