//
//  DCServerCommunicator.h
//  Discord Classic
//
//  Created by Julian Triveri on 3/4/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WSWebSocket.h"
#import "DCGuildListViewController.h"
#import "DCChannelListViewController.h"
#import "DCChatViewController.h"

@interface DCServerCommunicator : NSObject
@property WSWebSocket* websocket;
@property NSString* token;
@property NSString* gatewayURL;
@property NSMutableDictionary* readStates;
@property NSMutableArray* channels;
@property NSMutableArray* guilds;
@property DCChannel* selectedChannel;

+ (DCServerCommunicator *)sharedInstance;
- (void)startCommunicator;
- (void)sendJSON:(NSDictionary*)dictionary;
- (NSDictionary*)parseJSON:(NSString*)json;
- (NSDictionary*)sendMessage:(NSString*)message inChannel:(DCChannel*)channel;
- (NSDictionary*)ackMessage:(NSString*)messageId inChannel:(DCChannel*)channel;
@end
