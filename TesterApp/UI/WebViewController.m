//
//  WebViewController.m
//  UI
//
//  Created by Leo Natan (Wix) on 6/30/20.
//  Copyright © 2020 Leo Natan. All rights reserved.
//

#import "WebViewController.h"
@import WebKit;

@implementation WebViewController
{
	IBOutlet WKWebView* _webView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.nytimes.com"]]];
}

@end
