/* MyZoomView */

#import <Cocoa/Cocoa.h>
#include "common.h"

typedef struct
{
	int		start;
	int		end;
	char	name[32];
}Gene;

@interface MyZoomView : NSView
{
	NSDocument	*parent;

	SNP		*snp;
	Subject	*sub;
	int		nsnp;
	int		nsub;
	int		L,R;
	
	NSPoint	point;

	IBOutlet NSMatrix	*displaySettings;
	
	int		genesLUT[25];
	Gene	*genes;
	int		chromosome;
}
-(int)L;
-(int)R;
-(IBAction)updateDisplay:(id)sender;
-(void)setSNP:(SNP*)theSnp nsnp:(int)theNsnp subject:(Subject*)theSub nsub:(int)theNsub;
-(NSDocument*)parent;
-(void)setParent:(NSDocument*)theParent;
-(void)setChromosome:(int)aChromosome;

@end
