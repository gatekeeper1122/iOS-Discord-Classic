//
//  DCChatViewController.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/6/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCChatViewController.h"
#import "DCServerCommunicator.h"
#import "TRMalleableFrameView.h"

@implementation DCChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad{
	[super viewDidLoad];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleMessageCreate:) name:@"MESSAGE CREATE" object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self
																				 selector:@selector(keyboardWillShow:)
																						 name:UIKeyboardWillShowNotification
																					 object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self
																				 selector:@selector(keyboardWillHide:)
																						 name:UIKeyboardWillHideNotification
																					 object:nil];
}


-(void) viewWillDisappear:(BOOL)animated{
	[DCServerCommunicator.sharedInstance setSelectedChannel:nil];
}


- (void)getMessages{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		NSURL* getChannelURL = [NSURL URLWithString:
														[NSString stringWithFormat:@"%@%@%@",
														 @"https://discordapp.com/api/channels/",
														 self.selectedChannel.snowflake,
														 @"/messages"]];
		
		NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:getChannelURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
		
		[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
		[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		
		NSError *error;
		NSHTTPURLResponse *responseCode;
		
		NSData *response = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error];
		
		id parsedResponse = [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];
		
		NSString* chatTextViewContent = @"";
		
		if([parsedResponse isKindOfClass:NSArray.class]){
			[self setMessages:parsedResponse];
			
			for(int i = self.messages.count - 1; i >= 0; i--){
				
				NSDictionary* messageAtCurrentIndex = [self.messages objectAtIndex:i];
				NSString* username = [messageAtCurrentIndex valueForKeyPath:@"author.username"];
				NSString* content = [messageAtCurrentIndex valueForKey:@"content"];
				NSString* message = [NSString stringWithFormat:@"\n%@\n%@\n", username, content];
				chatTextViewContent = [chatTextViewContent stringByAppendingString:message];
			}
		}else{
			chatTextViewContent = @"error loading messages";
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.chatTextView setText:chatTextViewContent];
			[self.chatTextView scrollRangeToVisible:NSMakeRange(self.chatTextView.text.length, 0)];
		});
	});
}


- (void)handleMessageCreate:(NSNotification*)notification {
	//Refresh tableView data on READY notification
  NSString* newMessage = [notification.userInfo valueForKey:@"message"];
	[self.chatTextView setText:[self.chatTextView.text stringByAppendingString:newMessage]];
	[self.chatTextView scrollRangeToVisible:NSMakeRange(self.chatTextView.text.length, 0)];
}


- (void)keyboardWillShow:(NSNotification *)notification {
	
	//thx to Pierre Legrain
	//http://pyl.io/2015/08/17/animating-in-sync-with-ios-keyboard/
	
	int keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
	float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:keyboardAnimationDuration];
	[UIView setAnimationCurve:keyboardAnimationCurve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.chatTextView setHeight:self.view.height - keyboardHeight - self.toolbar.height];
	[self.toolbar setY:self.view.height - keyboardHeight - self.toolbar.height];
	[self.inputField setWidth:self.toolbar.width - 110];
	[UIView commitAnimations];
	
	[self.chatTextView scrollRangeToVisible:NSMakeRange(self.chatTextView.text.length, 0)];
}


- (void)keyboardWillHide:(NSNotification *)notification {
	
	float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:keyboardAnimationDuration];
	[UIView setAnimationCurve:keyboardAnimationCurve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.chatTextView setHeight:self.view.height - self.toolbar.height];
	[self.toolbar setY:self.view.height - self.toolbar.height];
	[self.inputField setWidth:self.toolbar.width - 12];
	[UIView commitAnimations];
}


- (IBAction)hideKeyboard:(id)sender {
	[self.inputField resignFirstResponder];
}


- (IBAction)sendMessage:(id)sender {
	[DCServerCommunicator.sharedInstance sendMessage:self.inputField.text inChannel:self.selectedChannel];
	
	[self.inputField setText:@""];
	
	[self.chatTextView scrollRangeToVisible:NSMakeRange(self.chatTextView.text.length, 0)];
}


- (void)viewDidUnload{
	[self setToolbar:nil];
	[self setChatTextView:nil];
	[self setInputField:nil];
	[super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
