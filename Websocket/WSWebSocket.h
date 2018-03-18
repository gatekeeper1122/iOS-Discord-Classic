//
//  WSWebSocket.h
//  WSWebSocket
//
//  Created by Andras Koczka on 2/7/12.
//  Copyright (c) 2012 Andras Koczka
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

/**
 The class is responsible for establishing a websocket connection to the specified URL, sending/receiving messages and closing the connection.
 */
@interface WSWebSocket : NSObject <NSStreamDelegate>

/**
 Specifies the maximum fragment size to use. Minimum fragment size is 131 bytes.
 */
@property (assign, nonatomic) NSUInteger fragmentSize;

/**
 The host url.
 */
@property (strong, nonatomic, readonly) NSURL *hostURL;

/**
 The protocol selected by the server.
 */
@property (strong, nonatomic, readonly) NSString *selectedProtocol;

/**
 Designated initializer.
 @param url The url of the server to connect
 @param protocols An optional array of protocol strings
 */
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;

/**
 Opens the connection.
 */
- (void)open;

/**
 Closes the connection.
 */
- (void)close;

/**
 Sends the given data.
 @param data The data to be sent
 */
- (void)sendData:(NSData *)data;

/**
 Sends the given text. Text should be UTF8 encoded.
 @param text The text to be sent.
 */
- (void)sendText:(NSString *)text;

/**
 Sends a ping message with the specified data.
 @param data Additional data to be sent as part of the ping message. Maximum data size is 125 bytes.
 */
- (void)sendPingWithData:(NSData *)data;

/**
 Sets a data callback block that will be called whenever a message with data is received.
 @param dataCallback The callback block
 */
- (void)setDataCallback:(void (^)(NSData *data))dataCallback;

/**
 Sets a text callback block that will be called whenever a text message is received.
 @param textCallback The callback block
 */
- (void)setTextCallback:(void (^)(NSString *text))textCallback;

/**
 Sets a pong callback block that will be called whenever a pong is received.
 @param pongCallback The callback block
 */
- (void)setPongCallback:(void (^)(void))pongCallback;

/**
 Sets a callback block that will be called after the connection is closed.
 @param closeCallback The callback block
 */
- (void)setCloseCallback:(void (^)(NSUInteger statusCode, NSString *message))closeCallback;

/**
 Sends the given request.
 Use this method to send a preconfigured request to handle authentication.
 Websocket related header fields are added automatically. Should be used after getting a response callback.
 @param request The request to be sent
 */
- (void)sendRequest:(NSURLRequest *)request;

/**
 Sets a callback block that will be called whenever a response is received.
 Use this callback to handle authentication and to set any cookies received.
 @param responseCallback The callback block
 */
- (void)setResponseCallback:(void (^)(NSHTTPURLResponse *response, NSData *data))responseCallback;

@end
