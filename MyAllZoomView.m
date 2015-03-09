//
//  MyAllZoomView.m
//  SnipPeep
//
//  Created by roberto on 06/02/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MyAllZoomView.h"


@implementation MyAllZoomView

#include "drawChromosomes.h"

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		allcn=nil;
		hhist=nil;
		vhist=nil;
		loadingStatus=0;
		LUT=nil;
		filter=0;
		[[NSNotificationCenter defaultCenter]	addObserver:self
												selector:@selector(changeSubject:)
												name:@"MyChangeSubject"
												object:nil];
		selectedSubjectIndex=0;
		[[NSNotificationCenter defaultCenter]	addObserver:self
												selector:@selector(zoom:)
												name:@"MyZoom"
												object:nil];
		L=R=-1;
		chromosome=-1;
		chromosomeHeight=23;
    }
    return self;
}
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
- (BOOL)isFlipped
{
	return YES;
}
-(void)drawCNVWithValue:(int)cn inRect:(NSRect)r
{
	NSColor	*c=nil;
	if(cn>=0&&cn<1	&& [[displaySettings cellAtRow:0 column:0] intValue])
		c=[NSColor orangeColor];
	else
	if(cn>=1&&cn<2	&& [[displaySettings cellAtRow:1 column:0] intValue])
		c=[NSColor redColor];
	else
	if(cn>=3&&cn<4	&& [[displaySettings cellAtRow:2 column:0] intValue])
		c=[NSColor greenColor];
	else
	if(cn>=4		&& [[displaySettings cellAtRow:3 column:0] intValue])
		c=[NSColor blueColor];
	if(c)
	{
		[c set];
		NSRectFill(r);
	}
}
- (void)drawRect:(NSRect)rect
{
	printf("drawRect\n");
	NSEraseRect(rect);
	
	if(loadingStatus==0)
	{
		NSString	*loading=[NSString stringWithString:@"Select a chromosome file"];
		[loading drawAtPoint:(NSPoint){rect.size.width/2.0-[loading sizeWithAttributes:nil].width/2.0,rect.size.height/2.0} withAttributes:nil];
		return;
	}
	else
	if(loadingStatus==1)
	{
		NSString	*loading=[NSString stringWithString:@"Loading..."];
		[loading drawAtPoint:(NSPoint){rect.size.width/2.0-[loading sizeWithAttributes:nil].width/2.0,rect.size.height/2.0} withAttributes:nil];
		return;
	}

	int				i,index;
	float			pos;
	float			y,delta;
	float			min,max;
	NSRect			r,r1,r2;
	float			W=1,RR=8;
	NSBezierPath	*bz=[NSBezierPath bezierPath];

	r1=(NSRect){0,chromosomeHeight,rect.size.width,rect.size.height-chromosomeHeight};
	r2=(NSRect){0,0,rect.size.width,chromosomeHeight};

	y=r1.size.height/(float)nsub;
	delta=MIN(y,RR);

	min=0;
	max=maxpos;

	int		bar;
	NSDictionary	*attr=[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:9.0] forKey:NSFontAttributeName];
	char			*ex[]={"","0","00","K","0K","00K","M","0M","00M","G","0G","00G","T","0T","00T"};

	bar=log10((max-min)/r1.size.width)+2.5;

	// draw chromosome
	if(chromosome>0)
		[self drawChr:chromosome inRect:(NSRect){r2.origin.x,chromosomeHeight-10-2,r2.size.width,10}];

	// draw selection
	[[NSColor colorWithDeviceRed:0.6 green:0.6 blue:0.6 alpha:0.8] set];
	NSRectFillUsingOperation((NSRect){(L-min)*rect.size.width/(float)(max-min),0,(R-L)*rect.size.width/(float)(max-min),rect.size.height},NSCompositeDestinationAtop);
	NSRectFillUsingOperation((NSRect){0,r1.origin.y+LUT[selectedSubjectIndex]*delta,r1.size.width,RR},NSCompositeDestinationAtop);

	// draw grid
	bz=[NSBezierPath bezierPath];
	for(i=(int)(min/pow(10,bar));i<=(int)(max/pow(10,bar));i++)
	{
		pos=(i*pow(10,bar)-min)*rect.size.width/(float)(max-min);
		[bz moveToPoint:(NSPoint){pos-0.5,0}];
		[bz lineToPoint:(NSPoint){pos-0.5,rect.size.height}];
		[[NSString stringWithFormat:@"%i%s",i,ex[bar]] drawAtPoint:(NSPoint){pos+1,0} withAttributes:attr];
	}
	for(index=0;index<nsub;index++)
	{
		if(index%50==0)
		{
			[bz moveToPoint:(NSPoint){0,r1.origin.y+(int)(index*delta)+0.5}];
			[bz lineToPoint:(NSPoint){r1.size.width,r1.origin.y+(int)(index*delta)+0.5}];
		}
	}
	[[NSColor lightGrayColor] set];
	[bz stroke];

	// draw CNVs
	NSDictionary	*dic;
	float			left,right,cn;
	int				n;
	for(i=0;i<[allcn count];i++)
	{
		dic=[allcn objectAtIndex:i];
		n=[[dic valueForKey:@"N"] intValue];
		if(n>filter)
		{
			left=[[dic valueForKey:@"L"] floatValue]*r1.size.width;
			right=[[dic valueForKey:@"R"] floatValue]*r1.size.width;
			cn=[[dic valueForKey:@"CN"] floatValue];
			index=[[dic valueForKey:@"I"] intValue];
			r=(NSRect){left,r1.origin.y+LUT[index]*delta,MAX(W,right-left),RR};
			[self drawCNVWithValue:cn inRect:r];
		}
	}

}
-(IBAction)updateDisplay:(id)sender
{
	[self setNeedsDisplay:YES];
}
-(void)setCNs:(NSMutableArray*)theCNs maxpos:(int)theMaxpos nsub:(int)theNsub;
{
	allcn=theCNs;
	maxpos=theMaxpos;
	nsub=theNsub;
	if(LUT)
		free(LUT);
	LUT=(int*)calloc(nsub,sizeof(int));
}
-(void)setLoadingStatus:(BOOL)theStatus
{
	loadingStatus=theStatus;
}
-(int)loadingStatus
{
	return loadingStatus;
}
-(void)zoom:(NSNotification*)n
{
	if((NSDocument*)[[n object] parent] != [self parent])
		return;

	NSDictionary	*dic=[n userInfo];
	L=[[dic objectForKey:@"L"] intValue];
	R=[[dic objectForKey:@"R"] intValue];
	[self setNeedsDisplay:YES];
}
-(void)changeSubject:(NSNotification*)n
{
	switch(1)
	{
		case 1: if((NSDocument*)[[n object] parent]!=[self parent]) return;
		case 2: if([n object]==self) return;
	}

	NSDictionary	*dic=[n userInfo];
	int				index=[[dic objectForKey:@"index"] intValue];
	selectedSubjectIndex=index;
	[self setNeedsDisplay:YES];
}

-(void)mouseDown:(NSEvent*)e
{
	if(allcn==nil)
		return;
	
	NSPoint	m=[self convertPoint:[e locationInWindow] fromView:nil];
	float	l,r,delta=5;
	NSRect	rect=[self frame];
	int		min,max;
	
	if([e clickCount]==2)
	{
		int		RR=8;
		float	D=MIN(RR,(rect.size.height-chromosomeHeight)/(float)nsub);
		int		i=(m.y-chromosomeHeight)/D;
		if(i>=0&&i<nsub)
		{
			NSDictionary	*dic=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i],@"index",nil];
			[[NSNotificationCenter defaultCenter]	postNotificationName:@"MyChangeSubject"
													object:self
													userInfo:dic];
		}
	}
	
	min=0;
	max=maxpos;
	
	old=m.x;
	l=(L-min)*rect.size.width/(float)(max-min);
	r=(R-min)*rect.size.width/(float)(max-min);

	if(m.x>=l-delta && m.x<=l)
		mode=kLeft;
	else
	if(m.x>l && m.x<r)
		mode=kMove;
	else
	if(m.x>=r && m.x<=r+delta)
		mode=kRight;
}
-(void)mouseDragged:(NSEvent*)e
{
	if(allcn==nil)
		return;
	
	NSPoint	m=[self convertPoint:[e locationInWindow] fromView:nil];
	NSRect	rect=[self frame];
	int		min,max;
	int		zmin=1e+5;
	
	min=0;
	max=maxpos;
	
	switch(mode)
	{
		case kLeft:
			L+=(m.x-old)*(max-min)/rect.size.width;
			if(L+zmin>R)
				L=R-zmin;
			break;
		case kRight:
			R+=(m.x-old)*(max-min)/rect.size.width;
			if(R-zmin<L)
				R=L+zmin;
			break;
		case kMove:
			L+=(m.x-old)*(max-min)/rect.size.width;
			R+=(m.x-old)*(max-min)/rect.size.width;
			break;
	}
	if(L<min)	{	R=R-(L-min); L=min;}
	if(R>max)	{	L=L-(R-max); R=max;}
	
	old=m.x;
	[self setNeedsDisplay:YES];

	NSDictionary	*dic=[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:L],@"L",
			[NSNumber numberWithInt:R],@"R",nil];
	[[NSNotificationCenter defaultCenter]	postNotificationName:@"MyZoom"
											object:self
											userInfo:dic];
}
-(int*)LUT
{
	return LUT;
}
-(int)filter
{
	return filter;
}
-(void)setFilter:(int)theFilterValue
{
	filter=theFilterValue;
}
-(NSDocument*)parent
{
	return parent;
}
-(void)setParent:(NSDocument*)theParent
{
	parent=theParent;
}
-(void)setChromosome:(int)aChromosome
{
	chromosome=aChromosome;
	[self setNeedsDisplay:YES];
}
@end
