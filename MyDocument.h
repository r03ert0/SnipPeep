//
//  MyDocument.h
//  SnipPeep
//
//  Created by roberto on 13/07/2009.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyGlobalView.h"
#import "MyZoomView.h"
#import "MyAllZoomView.h"
#import "MyChromoView.h"
#import <WebKit/WebKit.h>
#include "common.h"

@interface MyDocument : NSDocument
{
    IBOutlet MyGlobalView			*globalview;
    IBOutlet MyZoomView				*zoomview;
    IBOutlet MyAllZoomView			*allzoomview;
	IBOutlet NSWindow				*parentWindow;
    IBOutlet NSTextField			*msg;
    IBOutlet NSTextField			*meanR;
    IBOutlet NSArrayController		*subjects;
    IBOutlet NSTableView			*tableview;
    IBOutlet NSTabView				*tabview;
	
    IBOutlet WebView				*browserUCSC;
	IBOutlet NSProgressIndicator	*browserUCSCLoading;
    IBOutlet NSTextField			*browserUCSCURL;
    IBOutlet WebView				*browserTCAG;
	IBOutlet NSProgressIndicator	*browserTCAGLoading;
    IBOutlet NSTextField			*browserTCAGURL;
    IBOutlet NSPopUpButton			*popChr;
	
	int		cancelThread;
	
	NSString	*pathChromo;
	
	int				nsnp;
	int				nsub;
	SNP				*snp;
	Subject			*sub;
	NSMutableArray	*allcn;
}
-(IBAction)choose:(id)sender;
-(IBAction)browseUCSC:(id)sender;
-(IBAction)browseTCAG:(id)sender;
-(IBAction)saveCNVPlot:(id)sender;
-(IBAction)saveCNVMap:(id)sender;
-(IBAction)filter:(id)sender;
-(IBAction)saveFrequencies:(id)sender;
-(void)changeSubject:(NSNotification*)n;
-(NSDocument*)parent;
-(NSString*)pathChromo;
-(void)readSubjectPath:(NSString*)path;
-(void)configureData;
-(void)updateLUT;
@end
