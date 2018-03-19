//
//  DCGuild.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/12/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCGuild.h"
#import "DCChannel.h"

@implementation DCGuild


-(NSString *)description{
	return [NSString stringWithFormat:@"[Guild] Snowflake: %@, Read: %d, Name: %@, Channels: %@", self.snowflake, self.read, self.name, self.channels];
}

-(void)checkIfRead{
	for(int i = 0; i < self.channels.count; i++){
		DCChannel* channelAtIndex = [self.channels objectAtIndex:i];
		if(!channelAtIndex.read){
			self.read = false;
			return;
		}
	}
	
	[self setRead:true];
}

@end
