//
//  MyDocument.m
//  SnipPeep
//
//  Created by roberto on 13/07/2009.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self)
	{
    
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	pathChromo=nil;
	[subjects removeObjects:[subjects arrangedObjects]];
	if([self fileURL])
	{
		[subjects addObjects:[NSArray arrayWithContentsOfURL:[self fileURL]]];
		[subjects setSelectionIndex:0];
		[subjects	addObserver:self
				   forKeyPath:@"selection.id"
					  options:NSKeyValueObservingOptionNew| NSKeyValueObservingOptionOld
					  context:NULL];
		[subjects	addObserver:self
				   forKeyPath:@"arrangedObjects"
					  options:NSKeyValueObservingOptionNew| NSKeyValueObservingOptionOld
					  context:NULL];
		
		
		[self configureData];
	}
	else
	{
		snp=0;
		sub=nil;
		allcn=nil;
	}
	cancelThread=NO;
	[browserUCSC setFrameLoadDelegate:self];
	[browserTCAG setFrameLoadDelegate:self];

	// drag and drop support
	[tableview registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];

	[[NSNotificationCenter defaultCenter]	addObserver:self
											selector:@selector(changeSubject:)
											name:@"MyChangeSubject"
											object:nil];
    [globalview setParent:self];
    [zoomview setParent:self];
    [allzoomview setParent:self];
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type
{
	[[subjects arrangedObjects] writeToFile:fileName atomically:YES];
	return YES;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type
{
    return YES;
}
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter]	removeObserver:self];
	[super dealloc];
}
// drag and drop support
-(BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    printf("writeRowsWithIndexes drop\n");
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil] owner:self];
    [pboard setData:data forType:NSFilenamesPboardType];
	
    return YES;
}
-(NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id )info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	printf("validate drop\n");
   if(row>=0)
		return NSDragOperationEvery;
	else
		return NSDragOperationNone;
}
-(BOOL)tableView:(NSTableView*)tv acceptDrop:(id )info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    printf("accept drop\n");
	NSPasteboard	*pboard=[info draggingPasteboard];
	NSArray			*files=[pboard propertyListForType:NSFilenamesPboardType];
	int				i,numFiles=[files count];
	NSString		*p,*x;
		
	// 1. Add subjects to table
	if([[subjects arrangedObjects] count])
	{
		[subjects removeObserver:self forKeyPath:@"selection.id"];
		[subjects removeObserver:self forKeyPath:@"arrangedObjects"];
	}
	for(i=0;i<numFiles;i++)
	{
		p=[files objectAtIndex:i];
		x=[p lastPathComponent];
		printf("%s %s\n",[p UTF8String],[x UTF8String]);
		[subjects addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							 x,@"id",
							 p,@"path",
							 [NSNumber numberWithInt:[[subjects arrangedObjects] count]],@"index",nil]];
	}
	[tv setNeedsDisplay:YES];
	[subjects	addObserver:self
			   forKeyPath:@"selection.id"
				  options:NSKeyValueObservingOptionNew| NSKeyValueObservingOptionOld
				  context:NULL];
	[subjects	addObserver:self
			   forKeyPath:@"arrangedObjects"
				  options:NSKeyValueObservingOptionNew| NSKeyValueObservingOptionOld
				  context:NULL];
	//[subjects setSelectionIndex:[[subjects arrangedObjects] count]-1];
	
	
	[self configureData];
	[self updateChangeCount:NSChangeDone];

    return YES;    
}
-(void)configureData
{
	// 2. Configure SNP data
	[self readSubjectPath:[[[subjects selectedObjects] objectAtIndex:0] valueForKey:@"path"]];
	
	// 3. Configure All CNV data (in a thread)
	[NSThread detachNewThreadSelector:@selector(readAllSubjectCN) toTarget:self withObject:nil];
	
	// 4. Configure chromosome name
	int		n,chr=-1;
	char	c;
	n=sscanf([[popChr titleOfSelectedItem] UTF8String],"chr%i",&chr);
	if(n==0)
	{
		n=sscanf([[popChr titleOfSelectedItem] UTF8String],"chr%c",&c);
		if(c=='X')
			chr=23;
		else
		if(c=='Y')
			chr=24;
		else
		if(c=='M')
			chr=25;
	}
	[globalview setChromosome:chr];
	[zoomview setChromosome:chr];
	[allzoomview setChromosome:chr];
}
// webview support
- (void)webView:(WebView *)webView didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	if(webView==browserUCSC)
		[browserUCSCLoading startAnimation:self];
	else
		if(webView==browserTCAG)
			[browserTCAGLoading startAnimation:self];
}
- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame
{
	if(webView==browserUCSC)
		[browserUCSCLoading stopAnimation:self];
	else
		if(webView==browserTCAG)
			[browserTCAGLoading stopAnimation:self];
}
#pragma mark -
-(void)readSubjectPath:(NSString*)path
{
	int		i;
	FILE	*fchr;
	char	str[256];
	
	fchr=fopen([[NSString stringWithFormat:@"%@/%@.float",path,[popChr titleOfSelectedItem]] UTF8String],"r");
	
	// 1. Read number of SNPs and subjects
	fgets(str,255,fchr);
	sscanf(str,"%i %i",&nsnp,&nsub);
	
	printf("reading nsnps:%i nsubs:%i path:%s\n",nsnp,nsub,[path UTF8String]);
	
	// 2. Read SNP names and positions
	if(snp)
		free(snp);
	snp=(SNP*)calloc(nsnp,sizeof(SNP));
	fread(snp,nsnp,sizeof(SNP),fchr);
	
	// 4. Allocate memory for subject data
	if(sub)
	{
		free(sub->r);
		free(sub->b);
		free(sub->cn);
		free(sub);
	}
	sub=(Subject*)calloc(1,sizeof(Subject));
	sub->r=(float*)calloc(nsnp,sizeof(float));
	sub->b=(float*)calloc(nsnp,sizeof(float));
	sub->cn=(float*)calloc(nsnp,sizeof(float));
	
	[globalview setSNP:snp nsnp:nsnp subject:sub nsub:nsub];
	[zoomview setSNP:snp nsnp:nsnp subject:sub nsub:nsub];
	
	// 5. Read subject data
	fseek(fchr,nsub*32,SEEK_CUR);
	fread(sub->name,32,sizeof(char),fchr);
	fread(sub->r ,nsnp,sizeof(float),fchr);
	fread(sub->b ,nsnp,sizeof(float),fchr);
	fread(sub->cn,nsnp,sizeof(float),fchr);
	fclose(fchr);
	
	// 6. Compute mean and standard deviation
	float	s,ss,ave,std;
	s=0;
	ss=0;
	for(i=0;i<nsnp;i++)
	{
		s+=sub->r[i];
		ss+=pow(sub->r[i],2);
	}
	ave=s/(float)nsnp;
	std=(ss-s*s/(float)nsnp)/(float)(nsnp-1);
	[meanR setStringValue:[NSString stringWithFormat:@"%.1f%C%.2f",ave,0x00B1,std]];
	
	[globalview drawBiallele:[globalview frame]];
	[globalview setNeedsDisplay:YES];
	[zoomview setNeedsDisplay:YES];

	[msg setStringValue:[NSString stringWithFormat:@"%@, %i markers",path,nsnp]];
}
-(void)readAllSubjectCN
{
	NSAutoreleasePool	*pool=[[NSAutoreleasePool alloc] init];
	int		i,index;
	int		NSUB=[[subjects arrangedObjects] count];
	float	*cn;
	float	max;
	NSDictionary	*dic;
	char	str[1024];
	FILE	*fchr;
	float	pos,pos0;
	float	cn0;
	SNP		*sn;
	int		ind,ind0;

	[allzoomview setLoadingStatus:1];
	[allzoomview display];
	printf("Starting to load CN data\n");

	if(allcn)
		[allcn release];
	allcn=[NSMutableArray new];

	for(index=0;index<NSUB;index++)
	{
		sprintf(str,"%s/%s.float",[[[[subjects arrangedObjects] objectAtIndex:index] valueForKey:@"path"] UTF8String],[[popChr titleOfSelectedItem] UTF8String]);
		fchr=fopen(str,"r");
		fgets(str,1023,fchr);
		sscanf(str," %i %i ",&nsnp,&nsub);
		
		sn=(SNP*)calloc(nsnp,sizeof(SNP));
		fread(sn,nsnp,sizeof(SNP),fchr);
		fseek(fchr,32,SEEK_CUR);					// skip marker name
			  
		if(cancelThread==YES)
			break;
		printf("%i/%i\n",index,NSUB);
		fseek(fchr,	32*sizeof(char) +				// skip subject name
			  nsnp*sizeof(float) +					// skip subject r
			  nsnp*sizeof(float),					// skip subject b
			  SEEK_CUR);
		
		cn=(float*)calloc(nsnp,sizeof(float));
		fread(cn,nsnp,sizeof(float),fchr);			// read subject cn
		fclose(fchr);

		max=sn[nsnp-1].pos;
		cn0=cn[0];
		ind0=0;
		pos0=sn[ind0].pos/max;
		for(i=1;i<nsnp;i++)
		{
			if(cn[i]!=cn0)
			{
				pos=sn[i].pos/max;
				dic=[NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithFloat:pos0],@"L",
																[NSNumber numberWithFloat:pos],@"R",
																[NSNumber numberWithFloat:i-ind],@"N",
																[NSNumber numberWithFloat:cn0],@"CN",
																[NSNumber numberWithInt:index],@"I",nil];
				[allcn addObject:dic];
				pos0=pos;
				ind0=i;
				cn0=cn[i];
			}
		}
		dic=[NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithFloat:pos0],@"L",
														[NSNumber numberWithFloat:pos],@"R",
														[NSNumber numberWithFloat:i-ind],@"N",
														[NSNumber numberWithFloat:cn0],@"CN",
														[NSNumber numberWithInt:index],@"I",nil];
		[allcn addObject:dic];
		free(sn);
		free(cn);
	}
	
	[allzoomview setLoadingStatus:2];
	printf("Finished loading CN data\n");
	[allzoomview setNeedsDisplay:YES];

	[allzoomview setCNs:allcn maxpos:max nsub:NSUB];
	[self updateLUT];
/*
	int	*LUT=[allzoomview LUT];
	for(i=0;i<NSUB;i++)
		LUT[i]=i;
*/
	[pool release];
}
-(void)updateLUT
{
	int	i,*LUT=[allzoomview LUT];
	NSArray	*arr=[subjects arrangedObjects];
	printf("arranged objects: %s\n",[[arr description] UTF8String]);
	for(i=0;i<[arr count];i++)
		LUT[[[[arr objectAtIndex:i] valueForKey:@"index"] intValue]]=i;
	[allzoomview setNeedsDisplay:YES];
}	
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSDictionary	*dic;
	NSString		*path;
	
	if([keyPath isEqualTo:@"selection.id"])
	{
		if([[subjects selectedObjects] count]==0)
			return;
		dic=[[subjects selectedObjects] objectAtIndex:0];
		path=[dic valueForKey:@"path"];
		[self readSubjectPath:path];
		[[NSNotificationCenter defaultCenter]	postNotificationName:@"MyChangeSubject"
												object:self
												userInfo:dic];
	}
	else
	if([keyPath isEqualTo:@"arrangedObjects"])
		[self updateLUT];
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
	[tableview selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[tableview scrollRowToVisible:index];
}
-(IBAction)choose:(id)sender
{
	NSString	*path=[[[subjects selectedObjects] objectAtIndex:0] valueForKey:@"path"];
	
	if(path==nil)
	{
		printf("ERROR: pathChromo is nil\n");
	}
	
	int		n,chr=-1;
	char	c;
	n=sscanf([[popChr titleOfSelectedItem] UTF8String],"chr%i",&chr);
	if(n==0)
	{
		n=sscanf([[popChr titleOfSelectedItem] UTF8String],"chr%c",&c);
		if(c=='X')
			chr=23;
		else
		if(c=='Y')
			chr=24;
		else
		if(c=='M')
			chr=25;
	}
	[self configureData];

	[globalview setChromosome:chr];
	[zoomview setChromosome:chr];
	[allzoomview setChromosome:chr];
	
	// set zoom interval the the first 10% of the chromosome
	NSDictionary	*dic=[NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInt:0],@"L",
						  [NSNumber numberWithInt:snp[nsnp-1].pos/10],@"R",nil];
	[[NSNotificationCenter defaultCenter]	postNotificationName:@"MyZoom"
														object:self
													  userInfo:dic];
}
-(IBAction)browseUCSC:(id)sender
{
	NSString	*urlText;
	urlText=[NSString stringWithFormat:@"http://genome.ucsc.edu/cgi-bin/hgTracks?hgsid=120035188&clade=mammal&org=Human&db=hg19&position=%@%%3A%i-%i&pix=800&Submit=submit&hgsid=120035188",
			 [popChr titleOfSelectedItem],[zoomview L],[zoomview R]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlText]];
}
-(IBAction)browseTCAG:(id)sender
{
	NSString	*urlText;
	urlText=[NSString stringWithFormat:@"http://projects.tcag.ca/cgi-bin/variation/gbrowse/hg19/?name=%@:%i..%i",
			 [popChr titleOfSelectedItem],[zoomview L],[zoomview R]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlText]];
}
-(IBAction)saveCNVPlot:(id)sender
{
	NSSavePanel	*sp=[NSSavePanel savePanel];
	int		result;
	
	[sp setExtensionHidden:NO];
	[sp setCanSelectHiddenExtension:YES];
	[sp setRequiredFileType:@"pdf"];
	result=[sp runModal];
	if(result==NSFileHandlingPanelOKButton)
	{
		NSString	*path=[sp filename];
		[[zoomview dataWithPDFInsideRect:[zoomview frame]] writeToFile:path atomically:YES];
	}
}

-(IBAction)saveCNVMap:(id)sender
{
	NSSavePanel	*sp=[NSSavePanel savePanel];
	int		result;
	
	[sp setExtensionHidden:NO];
	[sp setCanSelectHiddenExtension:YES];
	[sp setRequiredFileType:@"pdf"];
	result=[sp runModal];
	if(result==NSFileHandlingPanelOKButton)
	{
		NSString	*path=[sp filename];
		[[allzoomview dataWithPDFInsideRect:[allzoomview frame]] writeToFile:path atomically:YES];
	}
}
-(IBAction)filter:(id)sender
{
	int	n=[sender intValue];
	[allzoomview setFilter:n];
	[allzoomview setNeedsDisplay:YES];
}
-(NSDocument*)parent
{
	return self;
}
-(NSString*)pathChromo
{
	NSString	*path=[[[subjects selectedObjects] objectAtIndex:0] valueForKey:@"path"];
	return path;
}
-(IBAction)saveFrequencies:(id)sender
{
	/*
	int		index,i,j,ind0;
	float	cn0,pos,pos0;
	int		*h,bin;
	float	s,ss,ave,std,totalsnps;
	
	h=(int*)calloc(11,sizeof(bin));
	for(index=0;index<nsub;index++)
	{
		for(i=0;i<11;i++)
			h[i]=0;
		s=0;
		ss=0;
		totalsnps=0;
		for(j=1;j<=22;j++)
		{
			pathChromo=[[NSString stringWithFormat:@"%@/chr%i.float",[pathChromo stringByDeletingLastPathComponent],j] retain];

			[self readSNPData];
			[self readSubjectPath:[[[subjects arrangedObjects] objectAtIndex:index] valueForKey:@"path"]];

			cn0=sub->cn[0];
			ind0=0;
			pos0=snp[ind0].pos;
			for(i=1;i<nsnp;i++)
			{
				s+=sub->r[i];
				ss+=pow(sub->r[i],2);

				if(sub->cn[i]!=cn0)
				{
					pos=snp[i].pos;
					if(cn0!=2)
					{
						bin=(pos-pos0)/100000;
						h[MIN(bin,10)]++;
						// printf("%s\t%f\t%f\n",sub->name,pos-pos0,cn0);
					}
					pos0=pos;
					ind0=i;
					cn0=sub->cn[i];
				}
			}
			if(cn0!=2)
			{
				pos=snp[i-1].pos;
				bin=(pos-pos0)/100000;
				h[MIN(bin,10)]++;
				//printf("%s\t%f\t%f\n",sub->name,pos-pos0,cn0);
			}
			totalsnps+=nsnp;
		}
			
		ave=s/totalsnps;
		std=(ss-s*s/totalsnps)/(totalsnps-1);

		printf("%s\t",sub->name);
		for(i=0;i<11;i++)
			printf("%i\t",h[i]);
		printf("%f\n",std);
	}
	*/
}
@end
