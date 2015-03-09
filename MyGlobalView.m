#import "MyGlobalView.h"
@implementation MyGlobalView

#include "drawChromosomes.h"

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil)
	{
		sub=nil;
		subIndex=0;

		[[NSNotificationCenter defaultCenter]	addObserver:self
												selector:@selector(zoom:)
												name:@"MyZoom"
												object:nil];
		L=R=0;

		bmp=nil;
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
#define kBINS 100
-(void)drawBiallele:(NSRect)re
{
	unsigned char*		b;
	int					bpr,i,ind,x,y;
	float				min,max;
	
	if(sub==nil)
		return;
	
	if(bmp)
		[bmp release];

	bmp=[[NSBitmapImageRep alloc]	initWithBitmapDataPlanes:NULL pixelsWide:re.size.width pixelsHigh:re.size.height
									bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO
									colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
	b=(unsigned char*)[bmp bitmapData];
	bpr=[bmp bytesPerRow];
	
	min=0;//snp[0].pos;
	max=snp[nsnp-1].pos;
	
	for(x=0;x<re.size.width;x++)
	for(y=0;y<re.size.height;y++)
	{
		ind=bpr*(re.size.height-1-y)+x*3;
		b[ind]=255;
		b[ind+1]=255;
		b[ind+2]=255;
	}
	
	for(i=0;i<nsnp;i++)
	{
		x=re.size.width*(snp[i].pos-min)/(max-min);
		
		if([[displaySettings cellAtRow:0 column:0] intValue])
		{
			y=sub->r[i]/6.0*re.size.height;
			if(y<0) y=0;
			if(y>re.size.height-1) y=re.size.height-1;
			ind=bpr*(re.size.height-1-y)+x*3;
			b[ind]=255;		// red: r
			b[ind+1]=0;
			b[ind+2]=0;
		}
		
		if([[displaySettings cellAtRow:1 column:0] intValue])
		{
			y=sub->b[i]*re.size.height;
			ind=bpr*(re.size.height-1-MIN(y,re.size.height-1))+x*3;
			b[ind]=0;
			b[ind+1]=255;	// green: b
			b[ind+2]=0;
		}
		
		if([[displaySettings cellAtRow:2 column:0] intValue])
		{
			y=sub->cn[i]/6.0*re.size.height;
			if(y<0) y=0;
			ind=bpr*(re.size.height-1-MIN(y,re.size.height-1))+x*3;
			b[ind]=0;
			b[ind+1]=0;		// blue: cn
			b[ind+2]=255;
		}
	}
}
- (void)drawRect:(NSRect)rect
{
	NSEraseRect(rect);
	
	if(sub)
	{
		int				ind;
		int				i,bar;
		NSBezierPath	*bz;
		float			min,max;
		NSDictionary	*attr=[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:9.0] forKey:NSFontAttributeName];
		char			*ex[]={"","0","00","K","0K","00K","M","0M","00M","G","0G","00G","T","0T","00T"};
		NSRect			r1,r2;
		
		min=0;//snp[0].pos;
		max=snp[nsnp-1].pos;
		
		bar=log10((max-min)/rect.size.width)+2.5;
		
		r1=(NSRect){0,0,rect.size.width,rect.size.height-chromosomeHeight};
		r2=(NSRect){0,rect.size.height-chromosomeHeight,rect.size.width,chromosomeHeight};
		
		// draw R, B, CN
		if(bmp==nil)
			[self drawBiallele:r1];
		[bmp drawInRect:r1];
		
		// draw chromosome
		if(chromosome>0)
			[self drawChr:chromosome inRect:(NSRect){r2.origin.x,r2.origin.y+2,r2.size.width,10}];

		// draw selection
		[[NSColor colorWithDeviceRed:0.6 green:0.6 blue:0.6 alpha:0.8] set];
		NSRectFillUsingOperation((NSRect){(L-min)*rect.size.width/(float)(max-min),0,(R-L)*rect.size.width/(float)(max-min),rect.size.height},NSCompositeDestinationAtop);
		
		// draw grid
		bz=[NSBezierPath bezierPath];
		for(i=(int)(min/pow(10,bar));i<=(int)(max/pow(10,bar));i++)
		{
			ind=(i*pow(10,bar)-min)*rect.size.width/(float)(max-min);
			[bz moveToPoint:(NSPoint){ind-0.5,0}];
			[bz lineToPoint:(NSPoint){ind-0.5,rect.size.height}];
			[[NSString stringWithFormat:@"%i%s",i,ex[bar]] drawAtPoint:(NSPoint){ind+1,rect.size.height-12} withAttributes:attr];
		}
		[[NSColor lightGrayColor] set];
		[bz stroke];
				
		/*
			if([[displaySettings cellAtRow:0 column:0] intValue])
			if([[displaySettings cellAtRow:0 column:2] intValue])
		*/
		
	}
}
- (void)viewDidEndLiveResize
{
	NSRect	rect=[self frame];
	[self drawBiallele:rect];
	[self setNeedsDisplay:YES];
}
-(void)mouseDown:(NSEvent*)e
{
	if(sub==nil)
		return;
		
	NSPoint	m=[self convertPoint:[e locationInWindow] fromView:nil];
	float	l,r,delta=5;
	NSRect	rect=[self frame];
	int		min,max;
	
	min=0;//snp[0].pos;
	max=snp[nsnp-1].pos;
	
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
	if(sub==nil)
		return;
	
	NSPoint	m=[self convertPoint:[e locationInWindow] fromView:nil];
	NSRect	rect=[self frame];
	int		min,max;
	int		zmin=1e+5;
	
	min=0;//snp[0].pos;
	max=snp[nsnp-1].pos;
	
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
-(void)setSNP:(SNP*)theSnp nsnp:(int)theNsnp subject:(Subject*)theSub nsub:(int)theNsub
{
	snp=theSnp;
	sub=theSub;
	nsnp=theNsnp;
	nsub=theNsub;

	int		min,max;
	min=0;//snp[0].pos;
	max=snp[nsnp-1].pos;
	L=MAX(min,L);
	R=MIN(max,R);
	if(L==R)
		R=max/10;
	[self setNeedsDisplay:YES];
	NSDictionary	*dic=[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:L],@"L",
			[NSNumber numberWithInt:R],@"R",nil];
	[[NSNotificationCenter defaultCenter]	postNotificationName:@"MyZoom"
											object:self
											userInfo:dic];
}
-(void)zoom:(NSNotification*)n
{
	if([[n object] parent]!=[self parent])
		return;

	NSDictionary	*dic=[n userInfo];	
	L=[[dic objectForKey:@"L"] intValue];
	R=[[dic objectForKey:@"R"] intValue];
	[self setNeedsDisplay:YES];

	[selection setStringValue:[NSString stringWithFormat:@"%i,%i",L,R]];
}

-(IBAction)updateDisplay:(id)sender
{
	int	tag=[sender tag];
	if(tag==2)
	{
		sscanf([[selection stringValue] UTF8String],"%i,%i",&L,&R);
	}

	NSRect	rect=[self frame];
	[self drawBiallele:rect];
	[self setNeedsDisplay:YES];
}
-(IBAction)setTheSelection:(id)sender
{
	sscanf((char*)[[sender stringValue] UTF8String]," %i , %i ",&L, &R);
	[self setNeedsDisplay:YES];
	NSDictionary	*dic=[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:L],@"L",
			[NSNumber numberWithInt:R],@"R",nil];
	[[NSNotificationCenter defaultCenter]	postNotificationName:@"MyZoom"
											object:self
											userInfo:dic];
}
-(id)parent
{
	return parent;
}
-(void)setParent:(id)theParent
{
	parent=theParent;
}
-(void)setChromosome:(int)aChromosome
{
	chromosome=aChromosome;
	[self setNeedsDisplay:YES];
}

@end
