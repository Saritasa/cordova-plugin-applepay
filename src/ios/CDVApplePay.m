#import "CDVApplePay.h"

typedef void (^APAuthorizationBlock)(PKPaymentAuthorizationStatus);

typedef void (^APShippingContactBlock)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull);

typedef void (^APPaymentMethodBlock)(NSArray<PKPaymentSummaryItem *> * _Nonnull);

@interface CDVApplePay () <PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic) PKMerchantCapability merchantCapabilities;
@property (nonatomic, copy) NSArray<NSString *>* supportedPaymentNetworks;
@property (nonatomic, copy) NSString *paymentCallbackId;

@property (nonatomic, strong) APAuthorizationBlock paymentAuthorizationBlock;
@property (nonatomic, strong) APShippingContactBlock shippingContactBlock;
@property (nonatomic, strong) APPaymentMethodBlock paymentMethodBlock;

@end

@implementation CDVApplePay

- (void)pluginInitialize
{
    // Set these to the payment cards accepted.
    // They will nearly always be the same.
    self.supportedPaymentNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkAmex];

    // Set the capabilities that your merchant supports
    // Adyen for example, only supports the 3DS one.
    self.merchantCapabilities = PKMerchantCapability3DS;
}

- (void)canMakePayments:(CDVInvokedUrlCommand*)command
{
    if ([PKPaymentAuthorizationViewController canMakePayments]) {
        if ((floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_8_0)) {
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device cannot make payments."];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            return;
        } else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]) {
            if ([PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:self.supportedPaymentNetworks capabilities:(self.merchantCapabilities)]) {
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"This device can make payments and has a supported card"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                return;
            } else {
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device can make payments but has no supported cards"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                return;
            }
        } else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){8, 0, 0}]) {
            if ([PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:self.supportedPaymentNetworks]) {
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"This device can make payments and has a supported card"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                return;
            } else {
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device can make payments but has no supported cards"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                return;
            }
        } else {
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device cannot make payments."];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            return;
        }
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device cannot make payments."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
}

- (void)makePaymentRequest:(CDVInvokedUrlCommand*)command
{
    self.paymentCallbackId = command.callbackId;

    NSLog(@"ApplePay canMakePayments == %s", [PKPaymentAuthorizationViewController canMakePayments]? "true" : "false");
    if ([PKPaymentAuthorizationViewController canMakePayments] == NO) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device cannot make payments."];
        [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
        return;
    }

    // reset any lingering callbacks, incase the previous payment failed.
    self.paymentAuthorizationBlock = nil;
    self.shippingContactBlock = nil;
    self.paymentMethodBlock = nil;

    PKPaymentRequest *request = [PKPaymentRequest new];

    // Different version of iOS support different networks, (ie Discover card is iOS9+; not part of my project, so ignoring).
    request.supportedNetworks = self.supportedPaymentNetworks;

    request.merchantCapabilities = self.merchantCapabilities;

    // All this data is loaded from the Cordova object passed in. See documentation.
    [request setCurrencyCode:[self currencyCodeFromArguments:command.arguments]];
    [request setCountryCode:[self countryCodeFromArguments:command.arguments]];
    [request setMerchantIdentifier:[self merchantIdentifierFromArguments:command.arguments]];
    [request setRequiredBillingAddressFields:[self billingAddressRequirementFromArguments:command.arguments]];
    [request setRequiredShippingAddressFields:[self shippingAddressRequirementFromArguments:command.arguments]];
    [request setShippingType:[self shippingTypeFromArguments:command.arguments]];
    [request setShippingMethods:[self shippingMethodsFromArguments:command.arguments]];
    [request setPaymentSummaryItems:[self paymentSummaryItemsFromArguments:command.arguments]];

    NSLog(@"ApplePay request == %@", request);

    PKPaymentAuthorizationViewController *authVC = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];

    authVC.delegate = self;

    if (authVC == nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"PKPaymentAuthorizationViewController was nil."];
        [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
        return;
    }

    [self.viewController presentViewController:authVC animated:YES completion:nil];
}

- (void)completeLastTransaction:(CDVInvokedUrlCommand*)command
{
    if (self.paymentAuthorizationBlock) {

        NSString *paymentAuthorizationStatusString = [command.arguments objectAtIndex:0];
        NSLog(@"ApplePay completeLastTransaction == %@", paymentAuthorizationStatusString);

        PKPaymentAuthorizationStatus paymentAuthorizationStatus = [self paymentAuthorizationStatusFromArgument:paymentAuthorizationStatusString];
        self.paymentAuthorizationBlock(paymentAuthorizationStatus);

        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"Payment status applied."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        
    }
}

#pragma mark - Private

- (NSString *)countryCodeFromArguments:(NSArray *)arguments
{
    NSString *countryCode = [[arguments objectAtIndex:0] objectForKey:@"countryCode"];
    return countryCode;
}

- (NSString *)merchantIdentifierFromArguments:(NSArray *)arguments
{
    NSString *merchantIdentifier = [[arguments objectAtIndex:0] objectForKey:@"merchantIdentifier"];
    return merchantIdentifier;
}

- (NSString *)currencyCodeFromArguments:(NSArray *)arguments
{
    NSString *currencyCode = [[arguments objectAtIndex:0] objectForKey:@"currencyCode"];
    return currencyCode;
}

- (PKShippingType)shippingTypeFromArguments:(NSArray *)arguments
{
    NSString *shippingType = [[arguments objectAtIndex:0] objectForKey:@"shippingType"];

    if ([shippingType isEqualToString:@"shipping"]) {
        return PKShippingTypeShipping;
    } else if ([shippingType isEqualToString:@"delivery"]) {
        return PKShippingTypeDelivery;
    } else if ([shippingType isEqualToString:@"store"]) {
        return PKShippingTypeStorePickup;
    } else if ([shippingType isEqualToString:@"service"]) {
        return PKShippingTypeServicePickup;
    }

    return PKShippingTypeShipping;
}

- (PKAddressField)billingAddressRequirementFromArguments:(NSArray *)arguments
{
    NSString *billingAddressRequirement = [[arguments objectAtIndex:0] objectForKey:@"billingAddressRequirement"];

    if ([billingAddressRequirement isEqualToString:@"none"]) {
        return PKAddressFieldNone;
    } else if ([billingAddressRequirement isEqualToString:@"all"]) {
        return PKAddressFieldAll;
    } else if ([billingAddressRequirement isEqualToString:@"postcode"]) {
        return PKAddressFieldPostalAddress;
    } else if ([billingAddressRequirement isEqualToString:@"name"]) {
        return PKAddressFieldName;
    } else if ([billingAddressRequirement isEqualToString:@"email"]) {
        return PKAddressFieldEmail;
    } else if ([billingAddressRequirement isEqualToString:@"phone"]) {
        return PKAddressFieldPhone;
    }


    return PKAddressFieldNone;
}

- (PKAddressField)shippingAddressRequirementFromArguments:(NSArray *)arguments
{
    NSString *shippingAddressRequirement = [[arguments objectAtIndex:0] objectForKey:@"shippingAddressRequirement"];

    if ([shippingAddressRequirement isEqualToString:@"none"]) {
        return PKAddressFieldNone;
    } else if ([shippingAddressRequirement isEqualToString:@"all"]) {
        return PKAddressFieldAll;
    } else if ([shippingAddressRequirement isEqualToString:@"postcode"]) {
        return PKAddressFieldPostalAddress;
    } else if ([shippingAddressRequirement isEqualToString:@"name"]) {
        return PKAddressFieldName;
    } else if ([shippingAddressRequirement isEqualToString:@"email"]) {
        return PKAddressFieldEmail;
    } else if ([shippingAddressRequirement isEqualToString:@"phone"]) {
        return PKAddressFieldPhone;
    }


    return PKAddressFieldNone;
}

- (NSArray *)paymentSummaryItemsFromArguments:(NSArray *)arguments
{
    NSArray *itemDescriptions = [[arguments objectAtIndex:0] objectForKey:@"items"];

    NSMutableArray *items = [[NSMutableArray alloc] init];

    for (NSDictionary *item in itemDescriptions) {

        NSString *label = [item objectForKey:@"label"];

        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:[[item objectForKey:@"amount"] decimalValue]];

        PKPaymentSummaryItem *newItem = [PKPaymentSummaryItem summaryItemWithLabel:label amount:amount];

        [items addObject:newItem];
    }
    
    return items;
}

- (NSArray *)shippingMethodsFromArguments:(NSArray *)arguments
{
    NSArray *shippingDescriptions = [[arguments objectAtIndex:0] objectForKey:@"shippingMethods"];

    NSMutableArray *shippingMethods = [[NSMutableArray alloc] init];
    for (NSDictionary *desc in shippingDescriptions) {
        PKShippingMethod *shippingMethod = [PKShippingMethod new];
        shippingMethod.identifier = [desc objectForKey:@"identifier"];
        shippingMethod.detail = [desc objectForKey:@"detail"];
        shippingMethod.amount = [NSDecimalNumber decimalNumberWithDecimal:[[desc objectForKey:@"amount"] decimalValue]];
        shippingMethod.label = [desc objectForKey:@"label"];

        [shippingMethods addObject:shippingMethod];
    }

    return shippingMethods;
}

- (PKPaymentAuthorizationStatus)paymentAuthorizationStatusFromArgument:(NSString *)paymentAuthorizationStatus
{
    if ([paymentAuthorizationStatus isEqualToString:@"success"]) {
        return PKPaymentAuthorizationStatusSuccess;
    } else if ([paymentAuthorizationStatus isEqualToString:@"failure"]) {
        return PKPaymentAuthorizationStatusFailure;
    } else if ([paymentAuthorizationStatus isEqualToString:@"invalid-billing-address"]) {
        return PKPaymentAuthorizationStatusInvalidBillingPostalAddress;
    } else if ([paymentAuthorizationStatus isEqualToString:@"invalid-shipping-address"]) {
        return PKPaymentAuthorizationStatusInvalidShippingPostalAddress;
    } else if ([paymentAuthorizationStatus isEqualToString:@"invalid-shipping-contact"]) {
        return PKPaymentAuthorizationStatusInvalidShippingContact;
    } else if ([paymentAuthorizationStatus isEqualToString:@"require-pin"]) {
        return PKPaymentAuthorizationStatusPINRequired;
    } else if ([paymentAuthorizationStatus isEqualToString:@"incorrect-pin"]) {
        return PKPaymentAuthorizationStatusPINIncorrect;
    } else if ([paymentAuthorizationStatus isEqualToString:@"locked-pin"]) {
        return PKPaymentAuthorizationStatusPINLockout;
    }

    return PKPaymentAuthorizationStatusFailure;
}

/**
 Serializes the payment into a dictionary.
 */
- (NSDictionary *)serializePayment:(PKPayment *)payment
{
    NSString *paymentData = [payment.token.paymentData base64EncodedStringWithOptions:0];

    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];

    [response setObject:paymentData  forKey:@"paymentData"];
    [response setObject:payment.token.transactionIdentifier  forKey:@"transactionIdentifier"];

    NSDictionary *billingContact = [self serializeContact:payment.billingContact];
    if (billingContact) {
        [response setObject:billingContact forKey:@"billingContact"];
    }

    NSDictionary *shippingContact = [self serializeContact:payment.shippingContact];
    if (shippingContact) {
        [response setObject:shippingContact forKey:@"shippingContact"];
    }

    return response;
}

/**
 Serializes the contact into a dictionary. Returns nil if the contact is empty.
 */
- (NSDictionary *)serializeContact:(PKContact *)contact
{
    NSMutableDictionary *response = [NSMutableDictionary new];

    if (contact) {
        if (contact.emailAddress) {
            [response setObject:contact.emailAddress forKey:@"emailAddress"];
        }

        if (contact.name) {

            if (contact.name.givenName) {
                [response setObject:contact.name.givenName forKey:@"nameFirst"];
            }

            if (contact.name.middleName) {
                [response setObject:contact.name.middleName forKey:@"nameMiddle"];
            }

            if (contact.name.familyName) {
                [response setObject:contact.name.familyName forKey:@"nameLast"];
            }

        }
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 2, 0}]) {
            if (contact.supplementarySubLocality) {
                [response setObject:contact.supplementarySubLocality forKey:@"supplementarySubLocality"];
            }
        }

        if (contact.postalAddress) {

            if (contact.postalAddress.street) {
                [response setObject:contact.postalAddress.street forKey:@"addressStreet"];
            }

            if (contact.postalAddress.city) {
                [response setObject:contact.postalAddress.city forKey:@"addressCity"];
            }

            if (contact.postalAddress.state) {
                [response setObject:contact.postalAddress.state forKey:@"addressState"];
            }

            if (contact.postalAddress.postalCode) {
                [response setObject:contact.postalAddress.postalCode forKey:@"postalCode"];
            }

            if (contact.postalAddress.country) {
                [response setObject:contact.postalAddress.country forKey:@"country"];
            }

            if (contact.postalAddress.ISOCountryCode) {
                [response setObject:contact.postalAddress.ISOCountryCode forKey:@"ISOCountryCode"];
            }
            
        }
    }

    if ([response allKeys].count == 0) {
        return nil;
    } else {
        return [response copy];
    }
}

- (NSString *)serializePaymentMethodType:(PKPaymentMethodType)paymentMethodType
{
    if (paymentMethodType == PKPaymentMethodTypeDebit) {
        return @"debit";
    } else if (paymentMethodType == PKPaymentMethodTypeCredit) {
        return @"credit";
    } else if (paymentMethodType == PKPaymentMethodTypePrepaid) {
        return @"prepaid";
    } else if (paymentMethodType == PKPaymentMethodTypeStore) {
        return @"store";
    }
    return @"unknown";
}

- (NSDictionary *)serializePaymentMethod:(PKPaymentMethod *)paymentMethod
{
    NSMutableDictionary *response = [NSMutableDictionary new];

    if (paymentMethod.displayName) {
        response[@"displayName"] = paymentMethod.displayName;
    }
    if (paymentMethod.network) {
        response[@"network"] = paymentMethod.network;
    }
    response[@"type"] = [self serializePaymentMethodType:paymentMethod.type];

    // TODO: serialize paymentPass.

    return [response copy];
}


#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion
{
    NSLog(@"CDVApplePay: didAuthorizePayment");

    self.paymentAuthorizationBlock = completion;

    NSDictionary *response = @{
        @"action": @"didAuthorizePayment",
        @"payment": [self serializePayment:payment],
    };

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
    [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Payment not completed."];
    [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingContact:(PKContact *)contact
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion
{
    NSLog(@"CDVApplePay: didSelectShippingContact");

    self.shippingContactBlock = completion;

    NSDictionary *response = @{
        @"action": @"didSelectShippingContact",
        @"shippingContact": [self serializeContact:contact]
    };

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
    [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                    didSelectPaymentMethod:(PKPaymentMethod *)paymentMethod
                                completion:(void (^)(NSArray<PKPaymentSummaryItem *> * _Nonnull))completion
{
    NSLog(@"CDVApplePay: didSelectPaymentMethod");

    self.paymentMethodBlock = completion;

    NSDictionary *response = @{
        @"action": @"didSelectPaymentMethod",
        @"paymentMethod": [self serializePaymentMethod:paymentMethod]
    };

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
    [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
}

@end
