//
//  DCSettingsViewController.m
//  Discord Classic
//
//  Created by Trevir on 3/18/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCSettingsViewController.h"
#import "DCServerCommunicator.h"

@interface DCSettingsViewController ()

@end

@implementation DCSettingsViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	NSString* token = [NSUserDefaults.standardUserDefaults stringForKey:@"token"];
	
	if(token!=nil){
		[self.tokenInputField setText:token];
	}
}

-(void) viewWillDisappear:(BOOL)animated{
	[NSUserDefaults.standardUserDefaults setObject:self.tokenInputField.text forKey:@"token"];
	
	[DCServerCommunicator.sharedInstance startCommunicator];
}

- (void)viewDidUnload {
	[self setTokenInputField:nil];
	[super viewDidUnload];
}
@end
