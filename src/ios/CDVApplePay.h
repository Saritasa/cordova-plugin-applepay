#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

#import <PassKit/PassKit.h>

@interface CDVApplePay : CDVPlugin

- (void)makePaymentRequest:(CDVInvokedUrlCommand*)command;
- (void)canMakePayments:(CDVInvokedUrlCommand*)command;
- (void)completeLastTransaction:(CDVInvokedUrlCommand*)command;

@end
