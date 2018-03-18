//
//  DCViewController.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/4/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCViewController.h"
#import "DCServerCommunicator.h"
#import "DCGuildListViewController.h"

@implementation DCViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	//Start server communicator
	[self setServerCommunicator:DCServerCommunicator.new];
}

- (void)viewDidUnload{
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
