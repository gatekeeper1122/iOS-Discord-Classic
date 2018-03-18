//
//  DCChannel.h
//  Discord Classic
//
//  Created by Julian Triveri on 3/12/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCGuild.h"

@interface DCChannel : NSObject
@property NSString* snowflake;
@property NSString* name;
@property NSString* lastMessageId;
@property bool read;
@property int type;
@property DCGuild* parentGuild;

-(void)checkIfRead;
@end
