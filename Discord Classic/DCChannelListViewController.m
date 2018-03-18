//
//  DCChannelViewController.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/5/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCChannelListViewController.h"
#import "DCChatViewController.h"
#import "DCServerCommunicator.h"
#import "DCGuild.h"
#import "DCChannel.h"

@interface DCChannelListViewController ()
@property (nonatomic)  DCGuild* selectedGuild;
@property int selectedChannelIndex;
@property DCChannel* selectedChannel;
@end

@implementation DCChannelListViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleMessageAck:) name:@"MESSAGE ACK" object:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	//static NSString *guildCellIdentifier = @"Channel Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Channel Cell"];
	
	if(cell.textLabel.text.length < 1){
		DCChannel* channelAtRowIndex = [self.selectedGuild.channels objectAtIndex:indexPath.row];
		[cell.textLabel setText:channelAtRowIndex.name];
		
		if(!channelAtRowIndex.read)
			[cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
		
		[self.cells addObject:cell];
	}
	
	return cell;
}

-(void)setSelectedGuild:(DCGuild*)selectedGuild{
	_selectedGuild = selectedGuild;
	[self.tableView reloadData];
}

- (void)handleMessageAck:(NSNotification*)notification {
	[self.tableView reloadData];
}

- (void)viewDidUnload{
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return self.selectedGuild.channels.count;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self setSelectedChannel:[self.selectedGuild.channels objectAtIndex:indexPath.row]];

	[DCServerCommunicator.sharedInstance.readStates setValue:self.selectedChannel.lastMessageId forKey:self.selectedChannel.snowflake];
	
	[DCServerCommunicator.sharedInstance ackMessage:self.selectedChannel.lastMessageId inChannel:self.selectedChannel];
	
	[self.selectedChannel checkIfRead];
	
	[[self.cells objectAtIndex:indexPath.row] setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	NSLog(@"Selected channel: %@", self.selectedChannel);
	[self performSegueWithIdentifier:@"Channels to Chat" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"Channels to Chat"]){
		
		DCChatViewController *chatViewController = [segue destinationViewController];
		
		if ([chatViewController isKindOfClass:DCChatViewController.class]){
			[chatViewController setSelectedChannel:self.selectedChannel];
			[DCServerCommunicator.sharedInstance setSelectedChannel:self.selectedChannel];
			dispatch_async(dispatch_get_main_queue(), ^{
				[chatViewController getMessages];
			});
		}
	}
}

@end
