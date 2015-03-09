/* MyGlobalView */

#import <Cocoa/Cocoa.h>
#include "common.h"

#define kLeft	1
#define kRight	2
#define kMove	3

@interface MyGlobalView : NSView
{
	id		parent;
	int		chromosome;
	
	SNP		*snp;
	Subject	*sub;
	int		nsnp;
	int		nsub;
	int		subIndex;
	
	NSBitmapImageRep	*bmp;
	int					L,R,mode;
	float				old;

	IBOutlet NSMatrix		*displaySettings;
	IBOutlet NSTextField	*selection;
	
	int chromosomeHeight;
}
-(IBAction)updateDisplay:(id)sender;
-(IBAction)setTheSelection:(id)sender;
-(void)setSNP:(SNP*)theSnp nsnp:(int)theNsnp subject:(Subject*)theSub nsub:(int)theNsub;
-(void)drawBiallele:(NSRect)re;
-(id)parent;
-(void)setParent:(id)theParent;
-(void)setChromosome:(int)aChromosome;
@end
