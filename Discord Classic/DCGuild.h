//
//  DCGuild.h
//  Discord Classic
//
//  Created by Julian Triveri on 3/12/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCGuild : NSObject
@property NSString* snowflake;
@property NSString* name;
@property NSMutableArray* channels;
@property NSString* iconHash;
@property bool read;

-(void)checkIfRead;
@end
