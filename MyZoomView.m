#import "MyZoomView.h"

@implementation MyZoomView

-(void)initGenes
{
	NSString	*rsrc=[[NSBundle mainBundle] resourcePath];
	char		path[1024],str[256];
	FILE		*f;
	int			i;
	
	sprintf(path,"%s/%s",[rsrc UTF8String],"Genes.txt");
	f=fopen(path,"r");
	for(i=0;i<24;i++)
	{
		fgets(str,255,f);
		sscanf(str," %i ",&(genesLUT[i]));
	}
	genes=(Gene*)calloc(45000,sizeof(Gene));
	i=0;
	do
	{
		fscanf(f," %i %i %s ",&(genes[i].start),&(genes[i].end),genes[i].name);
		i++;
	}
	while(!feof(f));
	genesLUT[24]=i;
}
- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil)
	{
		[[NSNotificationCenter defaultCenter]	addObserver:self
												selector:@selector(zoom:)
												name:@"MyZoom"
												object:nil];
		L=R=-1;
		point=(NSPoint){-1,-1};
		chromosome=-1;
		
		[self initGenes];
	}
	return self;
}
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
- (void)drawRect:(NSRect)rect
{
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	NSBezierPath	*bz;

    if(sub==nil)
        return;

	int				i,j,bar,snpIndex=-1;
	float			ind,dist,mindist=-1;
	NSDictionary	*attr=[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:9.0] forKey:NSFontAttributeName];
	char			*ex[]={"","0","00","K","0K","00K","M","0M","00M","G","0G","00G","T","0T","00T"};
	NSPoint			x,snpPoint;
	NSRect			r1=rect;
	
	// draw Grid
	bz=[NSBezierPath bezierPath];
	bar=log10((R-L)/rect.size.width)+2.5;
	for(j=(int)(L/pow(10,bar));j<=(int)(R/pow(10,bar));j++)
	{
		ind=(j*pow(10,bar)-L)*rect.size.width/(float)(R-L);
		[bz moveToPoint:(NSPoint){(int)ind+0.5,0}];
		[bz lineToPoint:(NSPoint){(int)ind+0.5,rect.size.height}];
	}
	[[NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:1.0] set];
	[bz stroke];

	r1.size.height-=105;
	r1.origin.y=105;
	
	// draw Data
	if(sub)
	{
	for(j=0;j<nsnp;j++)
		if(snp[j].pos>=L && snp[j].pos<=R)
		{
			ind=(snp[j].pos-L)*r1.size.width/(float)(R-L);
			for(i=0;i<3;i++)
			{
				if([[displaySettings cellAtRow:0 column:i] intValue]==0)
					continue;
				switch(i)
				{
					case 0: [[NSColor redColor] set];
							x=(NSPoint){ind,sub->r[j]*(r1.size.height-1)/6.0};
							break;
					case 1:	[[NSColor greenColor] set];
							x=(NSPoint){ind,sub->b[j]*(r1.size.height-1)};
							break;
					case 2: [[NSColor blueColor] set];
							x=(NSPoint){ind,sub->cn[j]*(r1.size.height-1)/4.0};
							break;
				}
				NSRectFill((NSRect){x.x-1,r1.origin.y+x.y-1,2,2});
				if(point.x>-1&&point.y>-1)
				{
					dist=pow(point.x-x.x,2)+pow((point.y-r1.origin.y)-x.y,2);
					if(dist<mindist || mindist==-1)
					{
						mindist=dist;
						snpIndex=j;
						snpPoint=x;
					}
				}
			}
		}
	}

	// draw Position
	bar=log10((R-L)/rect.size.width)+2.5;
	for(j=(int)(L/pow(10,bar));j<=(int)(R/pow(10,bar));j++)
	{
		ind=(j*pow(10,bar)-L)*rect.size.width/(float)(R-L);
		[[NSString stringWithFormat:@"%i%s",j,ex[bar]] drawAtPoint:(NSPoint){(int)ind+0.5,rect.size.height-12} withAttributes:attr];
	}

	// draw Genes
	if([[displaySettings cellAtRow:0 column:3] intValue])
	if(chromosome>0)
	{
		bz=[NSBezierPath bezierPath];
		for(i=genesLUT[chromosome-1];i<genesLUT[chromosome];i++)
		if((genes[i].start>=L && genes[i].start<=R) || (genes[i].end>=L && genes[i].end<=R))
		{
			[[NSString stringWithFormat:@"%s",genes[i].name] drawAtPoint:
							(NSPoint){(genes[i].start-L)*r1.size.width/(float)(R-L),100-10-10*(i%9)} withAttributes:attr];
			[bz moveToPoint:(NSPoint){(genes[i].start-L)*r1.size.width/(float)(R-L),100-8.5-10*(i%9)}];
			[bz lineToPoint:(NSPoint){(genes[i].end-L  )*r1.size.width/(float)(R-L),100-8.5-10*(i%9)}];
		}
		[bz stroke];
	}
	
	// draw Information
	if(snpIndex==-1)
		return;
	NSString		*msg=[NSString stringWithFormat:@"%s\npos:%.0f\nR=%.2f, B=%.2f,CN=%.2f",
						snp[snpIndex].rs,snp[snpIndex].pos,sub->r[snpIndex],sub->b[snpIndex],sub->cn[snpIndex]];
	NSSize			sz=[msg sizeWithAttributes:nil];
	NSPoint			p;
	
	[[NSColor blackColor] set];
	NSRectFill((NSRect){snpPoint.x-3,r1.origin.y+snpPoint.y-3,6,6});
	p=(NSPoint){(r1.size.width-sz.width)/2,(r1.size.height-sz.height)/2};
	[[NSColor colorWithDeviceRed:0.8 green:0.8 blue:0.8 alpha:0.8] set];
	bz=[NSBezierPath bezierPathWithRect:(NSRect){p,sz}];
	[bz fill];
	[msg drawAtPoint:p withAttributes:nil];

}
-(void)mouseDown:(NSEvent*)e
{
	point=[self convertPoint:[e locationInWindow] fromView:nil];
	[self setNeedsDisplay:YES];
}
-(void)mouseUp:(NSEvent*)e
{
	point=(NSPoint){-1,-1};
	[self setNeedsDisplay:YES];
}

-(void)setSNP:(SNP*)theSnp nsnp:(int)theNsnp subject:(Subject*)theSub nsub:(int)theNsub
{
	snp=theSnp;
	sub=theSub;
	nsnp=theNsnp;
	nsub=theNsub;
	[self setNeedsDisplay:YES];
}
-(IBAction)updateDisplay:(id)sender
{
	[self setNeedsDisplay:YES];
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
-(int)L
{
	return L;
}
-(int)R
{
	return R;
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
}
@end
