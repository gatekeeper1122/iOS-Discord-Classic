//
//  DCGuildViewController.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/4/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCGuildListViewController.h"
#import "DCChannelListViewController.h"
#import "DCServerCommunicator.h"
#import "DCGuild.h"
#import "DCWebImageOperations.h"

@interface DCGuildListViewController ()
@property DCGuild* selectedGuild;
@property NSMutableArray* cells;
@property bool didLoadImages;
@end

@implementation DCGuildListViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	//Create cell object
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Guild Cell"];
	
	//Define cell if it isn't already
	if(cell.textLabel.text.length < 1){
		//Set the name of the cell to the guild it represents
		DCGuild* guildAtRowIndex = [DCServerCommunicator.sharedInstance.guilds objectAtIndex:indexPath.row];
		[cell.textLabel setText:guildAtRowIndex.name];
		
		if(!guildAtRowIndex.read)
			[cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
		
		[self.cells addObject:cell];
		
		NSString* iconURL = [NSString stringWithFormat:@"https://cdn.discordapp.com/icons/%@/%@",
												 guildAtRowIndex.snowflake, guildAtRowIndex.iconHash];
		
		[DCWebImageOperations processImageDataWithURLString:iconURL andBlock:^(NSData *imageData) {
			[cell.imageView setImage:[UIImage imageWithData:imageData]];
			[self.tableView reloadData];
		}];
	}
	
	return cell;
}

-(void)viewWillAppear:(BOOL)animated{
	for(int i = 0; i < DCServerCommunicator.sharedInstance.guilds.count; i++){
		
		DCGuild* guildAtIndex = [DCServerCommunicator.sharedInstance.guilds objectAtIndex:i];
		UITableViewCell* cell = [self.cells objectAtIndex:i];
		
		NSString* iconURL = [NSString stringWithFormat:@"https://cdn.discordapp.com/icons/%@/%@",
												 guildAtIndex.snowflake, guildAtIndex.iconHash];
		
		[DCWebImageOperations processImageDataWithURLString:iconURL andBlock:^(NSData *imageData) {
			[cell.imageView setImage:[UIImage imageWithData:imageData]];
			[self.tableView reloadData];
		}];
	}
}


- (void)viewDidLoad{
	[super viewDidLoad];
	[self setCells:NSMutableArray.new];
	[self setDidLoadImages:false];
	//Run handleReady when recieving READY message from DCServerCommunicator
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleReady:) name:@"READY" object:nil];
}

- (void)handleReady:(NSNotification*)notification {
	//Refresh tableView data on READY notification
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
	//We only have as many items as we are members of guilds
	return DCServerCommunicator.sharedInstance.guilds.count;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self setSelectedGuild:[DCServerCommunicator.sharedInstance.guilds objectAtIndex:indexPath.row]];
	[self performSegueWithIdentifier:@"Guilds to Channels" sender:self];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"Guilds to Channels"]){
		
		DCChannelListViewController *channelListViewController = [segue destinationViewController];
		
		if ([channelListViewController isKindOfClass:DCChannelListViewController.class]){
			[channelListViewController setSelectedGuild:self.selectedGuild];
			[channelListViewController setCells:NSMutableArray.new];
		}
	}
}

@end
