//
//  DCServerCommunicator.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/4/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCServerCommunicator.h"
#import "DCChatViewController.h"
#import "DCGuild.h"
#import "DCChannel.h"

@implementation DCServerCommunicator

+ (DCServerCommunicator *)sharedInstance {
	
	static DCServerCommunicator *sharedInstance = nil;
	
	if (sharedInstance == nil) {
		sharedInstance = DCServerCommunicator.new;
		[sharedInstance startCommunicator];
	}
	
	return sharedInstance;
}

- (void)startCommunicator{
	
	NSString* token = [NSUserDefaults.standardUserDefaults stringForKey:@"token"];
	
	if(token!=nil){
		
		[self setToken:token];
		
		[self setGatewayURL:@"wss://gateway.discord.gg/?encoding=json&v=6"];
		
		//Establish websocket connection with discord
		NSURL *websocketUrl = [NSURL URLWithString:@"wss://gateway.discord.gg/?encoding=json&v=6"];
		self.websocket = [WSWebSocket.alloc initWithURL:websocketUrl protocols:nil];
		
		//Recieved message
		[self.websocket setTextCallback:^(NSString *responseString) {
			
			//Parse JSON
			NSDictionary *parsedResponse = [self parseJSON:responseString];
			
			//Dictionary we will send to Discord to log in
			NSDictionary *objectToSend;
			
			//Data values for easy access
			int op = [[parsedResponse valueForKey:@"op"] integerValue];
			NSString* t = [parsedResponse valueForKey:@"t"];
			NSDictionary* d = [parsedResponse valueForKey:@"d"];
			
			//Log gateway events
			NSLog(@"Op code %i: Event %@\n%@", op, t, d);
			
			//OP 10
			if(op == 10){
				//Get heartbeat interval
				int heartbeat = [[d valueForKey:@"heartbeat_interval"] intValue];
				
				//Send a heartbeat at interval heartbeatinterval
				dispatch_async(dispatch_get_main_queue(), ^{
					[NSTimer scheduledTimerWithTimeInterval:heartbeat/1000
																					 target:self
																				 selector:@selector(sendHeartbeat:)
																				 userInfo:nil
																					repeats:YES];
				});
				
				//Send Identify
				objectToSend = @{
				@"op":@2,
				@"d":@{
				@"token":self.token,
				@"properties":@{ @"$browser" : @"peble" },
				@"large_threshold":@"50",
				}
				};
				
				[self sendJSON:objectToSend];
			}
			
			
			//On recieve ready event after auth
			if(op == 0 && [t isEqualToString:@"READY"]){
				
				self.readStates = NSMutableDictionary.new;
				
				NSArray* readStatesArray = [d valueForKey:@"read_state"];
				
				for(int i = 0; i < readStatesArray.count; i++){
					NSDictionary* readStateAtIndex = [readStatesArray objectAtIndex:i];
					
					NSString* readStateChannelId = [readStateAtIndex valueForKey:@"id"];
					NSString* readStateMessageId = [readStateAtIndex valueForKey:@"last_message_id"];
					
					[self.readStates setObject:readStateMessageId forKey:readStateChannelId];
				}
				
				self.guilds = NSMutableArray.new;
				self.channels = NSMutableArray.new;
				
				//Get the JSON data for our guilds
				NSArray* rawGuildDataArray = [d valueForKey:@"guilds"];
				
				//Check that we got an array of guilds
				if(rawGuildDataArray){
					
					//Loop through all channels
					for(int guildIndex = 0; guildIndex < rawGuildDataArray.count; guildIndex++){
						
						//Get the guild at guildIndex and check that it isn't nil (no one likes nil)
						NSDictionary* rawGuildData = [rawGuildDataArray objectAtIndex:guildIndex];
						if(rawGuildData){
							
							//Place the JSON channel objects from the guild at guildIndex in an array
							NSArray* rawChannelDataArray = [rawGuildData valueForKey:@"channels"];
							if(rawChannelDataArray){
								
								//Create the new guild object, using the newChannels array we will create
								DCGuild* newGuild = DCGuild.new;
								
								//We will pass this array into our new guild object later. This is an array of that guild's channels
								NSMutableArray* newChannels = NSMutableArray.new;
								
								//Loop through all the channels of the guild at guildIndex
								for(int channelIndex = 0; channelIndex < rawChannelDataArray.count; channelIndex++){
									
									//Get the JSON object of the channel at channelIndex
									NSDictionary* rawChannelData = [rawChannelDataArray objectAtIndex:channelIndex];
									
									//If its a text channel...
									if([rawChannelData valueForKey:@"type"] == @0){
										
										//Create the new channel object
										DCChannel* newChannel = DCChannel.new;
										
										//Set the channel info
										newChannel.snowflake = [rawChannelData valueForKey:@"id"];
										newChannel.name = [rawChannelData valueForKey:@"name"];
										newChannel.lastMessageId = [rawChannelData valueForKey:@"last_message_id"];
										newChannel.parentGuild = newGuild;
										
										//Check if the channel is read or not
										/*if([[self.readStates valueForKey:newChannel.snowflake] isEqualToString:newChannel.lastMessageId])
										 [newChannel setRead:true];
										 else
										 [newChannel setRead:false];*/
										
										[newChannel checkIfRead];
										
										//Add that object to our channel array for the new guild
										[newChannels addObject:newChannel];
										[self.channels addObject:newChannel];
										
										NSLog(@"Created new channel object: %@", newChannel);
									}
								}
								
								//Set the guild details
								newGuild.snowflake = [rawGuildData valueForKey:@"id"];
								newGuild.name = [rawGuildData valueForKey:@"name"];
								newGuild.iconHash = [rawGuildData valueForKey:@"icon"];
								newGuild.channels = newChannels;
								
								[newGuild checkIfRead];
								
								NSLog(@"Created new guild object: %@", newGuild);
								
								//Add it to our communicator guild array
								[self.guilds addObject:newGuild];
							}
						}
					}
				}
				
				//Now that that's all done,
				//send a notification that we successfully created our guild objects
				dispatch_async(dispatch_get_main_queue(), ^{
					[NSNotificationCenter.defaultCenter postNotificationName:@"READY" object:self];
				});
			}
			
			//On reading a message
			if(op == 0 && [t isEqualToString:@"MESSAGE_ACK"]){
				/*dispatch_async(dispatch_get_main_queue(), ^{
				 for(int i = 0; i < self.readStates.count; i++){
				 
				 NSString* readStateChannelIdForCurrentIndex = [[self.readStates objectAtIndex:i] valueForKey:@"id"];
				 NSString* recievedChannelId = [d valueForKey:@"channel_id"];
				 
				 if([readStateChannelIdForCurrentIndex isEqualToString: recievedChannelId]){
				 NSString* recievedMessageId = [d valueForKey:@"message_id"];
				 
				 NSDictionary* updatedReadState = @{
				 @"id":recievedChannelId,
				 @"last_message_id":recievedMessageId
				 };
				 
				 [self.readStates replaceObjectAtIndex:i withObject:updatedReadState];
				 }
				 }
				 });*/
			}
			
			//On recieving a message
			if(op == 0 && [t isEqualToString:@"MESSAGE_CREATE"]){
				NSString* messageChannelId = [parsedResponse valueForKeyPath:@"d.channel_id"];
				
				NSString* lastMessageId = [d valueForKeyPath:@"id"];
				
				if(self.selectedChannel != nil){
					if([messageChannelId isEqualToString:self.selectedChannel.snowflake]){
						
						NSString* username = [d valueForKeyPath:@"author.username"];
						NSString* content = [d objectForKey:@"content"];
						NSString* message = [NSString stringWithFormat:@"\n%@\n%@\n", username, content];
						
						NSDictionary* userInfo = @{@"message": message};
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[NSNotificationCenter.defaultCenter postNotificationName:@"MESSAGE CREATE" object:self userInfo:userInfo];
						});
						
						[self.selectedChannel setLastMessageId:lastMessageId];
						
						[self.readStates setValue:lastMessageId forKey:self.selectedChannel.snowflake];
						
						NSLog(@"The last message was sent in the current channel");
						
						//Ack message since we are reading this channel currently
						[self ackMessage:lastMessageId inChannel:self.selectedChannel];
					}
				}else{
					
					for(int i = 0; i < self.channels.count; i++){
						
						DCChannel* channelAtIndex = [self.channels objectAtIndex:i];
						if([channelAtIndex.snowflake isEqualToString:messageChannelId]){
							channelAtIndex.lastMessageId = lastMessageId;
							
							[channelAtIndex checkIfRead];
						}
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[NSNotificationCenter.defaultCenter postNotificationName:@"MESSAGE ACK" object:self];
						});
					}
					
					NSLog(@"The last message was not sent in the current channel");
				}
				
			}
		}];
		
		[self.websocket open];
	}
}

- (void)sendJSON:(NSDictionary*)dictionary{
	NSError *writeError = nil;
	
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
																										 options:NSJSONWritingPrettyPrinted
																											 error:&writeError];
	
	NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	[self.websocket sendText:jsonString];
}

- (NSDictionary*)parseJSON:(NSString*)json{
	NSError *error = nil;
	NSData *encodedResponseString = [json dataUsingEncoding:NSUTF8StringEncoding];
	id parsedResponse = [NSJSONSerialization JSONObjectWithData:encodedResponseString options:0 error:&error];
	if([parsedResponse isKindOfClass:NSDictionary.class]){
		return parsedResponse;
	}
	return nil;
}

- (NSDictionary*)sendMessage:(NSString*)message inChannel:(DCChannel*)channel{
	
	NSURL* channelURL = [NSURL URLWithString:
											 [NSString stringWithFormat:@"%@%@%@",
												@"https://discordapp.com/api/channels/",
												channel.snowflake,
												@"/messages"]];
	
	NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:channelURL
																													cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
																											timeoutInterval:5];
	
	NSString* messageString = [NSString stringWithFormat:@"{\"content\":\"%@\"}", message];
	
	[urlRequest setHTTPBody:[NSData dataWithBytes:[messageString UTF8String] length:[messageString length]]];
	[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
	[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[urlRequest setHTTPMethod:@"POST"];
	
	
	NSError *error = nil;
	NSHTTPURLResponse *responseCode = nil;
	
	NSData *response = [NSURLConnection sendSynchronousRequest:urlRequest
																					 returningResponse:&responseCode
																											 error:&error];
	
	return [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];
}

- (NSDictionary*)ackMessage:(NSString*)messageId inChannel:(DCChannel*)channel{
	NSURL* channelURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@",
																						@"https://discordapp.com/api/channels/",
																						channel.snowflake, @"/messages/",
																						messageId,
																						@"/ack"]];
	
	NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:channelURL
																													cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
																											timeoutInterval:5];
	
	[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
	[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[urlRequest setHTTPMethod:@"POST"];
	
	
	NSError *error = nil;
	NSHTTPURLResponse *responseCode = nil;
	
	NSData *response = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error];
	
	return [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];
}

- (void) sendHeartbeat:(NSTimer *)timer{
	[self sendJSON:@{ @"op": @1, @"d": NSNull.null}];
	NSLog(@"Sent heartbeat");
}

@end
