#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

#import <PassKit/PassKit.h>

@interface CDVApplePay : CDVPlugin

- (void)canMakePayments:(CDVInvokedUrlCommand *)command;
- (void)makePaymentRequest:(CDVInvokedUrlCommand *)command;

- (void)completeAuthorizationTransaction:(CDVInvokedUrlCommand *)command;

- (void)completeShippingContactTransaction:(CDVInvokedUrlCommand *)command;

- (void)completePaymentMethodTransaction:(CDVInvokedUrlCommand *)command;

@end
