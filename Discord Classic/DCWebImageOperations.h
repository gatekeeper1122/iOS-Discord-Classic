//
//  DCWebImageOperations.h
//  Discord Classic
//
//  Created by Julian Triveri on 3/17/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCWebImageOperations : NSObject
// This takes in a string and imagedata object and returns imagedata processed on a background thread
+ (void)processImageDataWithURLString:(NSString *)urlString
														 andBlock:(void (^)(NSData *imageData))processImage;
@end
