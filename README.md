# Cordova Apple Pay Plugin
> A dependency free Cordova plugin to provide Apple Pay functionality.

Updated to provide additional data access to the plugin, test calls, and compatibility
with newer versions of Cordova. Uses a Promise based interface in JavaScript.

This plugin is compatible with any payment processor (eg Stripe, Adyen etc) because
the payment token is handled back your JavaScript application to pass to which ever payment
processor you use.

## Installation
```
$ cordova plugin add cordova-plugin-applepay
```

Install the plugin using Cordova 6 and above, which is based on [npm](https://www.npmjs.com/package/cordova-plugin-applepay). The plugin
exposes the `window.ApplePay` global in the browser.


## Compatibility

- iOS 9 (using newer iOS9 only APIs)
- Requires Cordova 6 running at least iOS Platform 4.1.1

## Methods
The methods available all return promises, or accept success and error callbacks.
- ApplePay.canMakePayments
- ApplePay.makePaymentRequest
- ApplePay.completeAuthorizationTransaction
- ApplePay.completeShippingContactTransaction
- ApplePay.completePaymentMethodTransaction

## ApplePay.canMakePayments
Detects if the current device supports Apple Pay and has any *capable* cards registered.

```
ApplePay.canMakePayments()
    .then((message) => {
        // Apple Pay is enabled and a supported card is setup. Expect:
        // 'This device can make payments and has a supported card'
    })
    .catch((message) => {
        // There is an issue, examine the message to see the details, will be:
        // 'This device cannot make payments.''
        // 'This device can make payments but has no supported cards'
    });
```

If in your `catch` you get the message `This device can make payments but has no supported cards` - you can decide if you want to handle this by showing the 'Setup Apple Pay' buttons instead of the
normal 'Pay with Apple Bay' buttons as per the Apple Guidelines.

## ApplePay.makePaymentRequest
Request a payment with Apple Pay, returns a Promise that once resolved, has the payment token.
In your `order`, you will set parameters like the merchant ID, country, address requirements,
order information etc. See a full example of an order at the end of this document.

```
ApplePay.makePaymentRequest(order)
    .then((paymentResponse) => {
        // User approved payment, token generated.
    })
    .catch((message) => {
        // Error or user cancelled.
    });
```

### Responses

`ApplePay.makePaymentRequest` can receive three kinds of responses:
- When an user has authorized payment. You should call `ApplePay.completeAuthorizationTransaction` in order to finish.
```json
{
    "action": "didAuthorizePayment",
    "payment": ...
}
```
- When an user has selected shipping contact. You should call `ApplePay.completeShippingContactTransaction` in order to update the info.
```json
{
    "action": "didSelectShippingContact",
    "shippingContact": ...
}
```
- When an user has selected payment method. You should call `ApplePay.completePaymentMethodTransaction` in order to update the info.
```json
{
    "action": "didSelectPaymentMethod",
    "paymentMethod": ...
}
```

The `payment` is an object with the keys that contain the token itself,
this is what you'll need to pass along to your payment processor. Also, if you requested
billing or shipping addresses, this information is also included.

```json
{
    "paymentData": "<BASE64 ENCODED TOKEN WILL APPEAR HERE>",
    "transactionIdentifier": "Simulated Identifier",
    "billingContact": {
        "addressCity": "London",
        "ISOCountryCode": "gb",
        "addressState": "London",
        "addressStreet": "Street 1\n",
        "nameFirst": "First",
        "postalCode": "POST CODE",
        "nameLast": "NAME",
        "country": "United Kingdom",
        "supplementarySubLocality": ""
    },
    "shippingContact": {
        "addressState": "London",
        "country": "United Kingdom",
        "ISOCountryCode": "gb",
        "nameLast": "Name",
        "nameFirst": "First",
        "postalCode": "POST CODE",
        "addressStreet": "Street Line 1\nStreet Line 2",
        "addressCity": "London",
        "supplementarySubLocality": ""
    }
}
```

The `shippingContanct` is an object that contains the same fields as the `payment.shippingContact` object.

The `paymentMethod` is an object that contains payment method information.

```json
{
    "displayName": "Visa…1233",
    "network": "Visa",
    "type": "credit"
}
```

Valid values for `type` field are: `debit`, `credit`, `prepaid`, `store`, `unknown`.

## ApplePay.completeAuthorizationTransaction
Once the makePaymentRequest has been resolved successfully, the device will be waiting for a completion event.
This means, that the application must proceed with the token authorisation and return a success, failure, or other validation error. Once this has been passed back, the Apple Pay sheet will be dismissed via an animation. You should call this method if you receive `"action": "didAuthorizePayment"` in the success callback of `ApplePay.makePaymentRequest` method.

```js
ApplePay.completeAuthorizationTransaction('success');
```

You can dismiss or invalidate the Apple Pay sheet by calling `completeAuthorizationTransaction` with a status string which can be `success`, `failure`, `invalid-billing-address`, `invalid-shipping-address`, `invalid-shipping-contact`, `require-pin`, `incorrect-pin`, `locked-pin`.

## ApplePay.completeShippingContactTransaction
You should call this method if you receive `"action": "didSelectShippingContact"` in the success callback of `ApplePay.makePaymentRequest` method. The method accepts an object that should contain payment authorization status (valid values are the same as in `ApplePay.completeAuthorizationTransaction`), new payment shipping methods (format the same as in `ApplePay.makePaymentRequest`) and payment summary items (format the same as in `ApplePay.makePaymentRequest`).

```js
ApplePay.completeShippingContactTransaction({'status': status, 'shippingMethods': methods, 'items': items});
```

## ApplePay.completePaymentMethodTransaction
You should call this method if you receive `"action": "didSelectPaymentMethod"` in the success callback of `ApplePay.makePaymentRequest` method. The method accepts an object that should contain payment summary items (format the same as in `ApplePay.makePaymentRequest`).

```js
ApplePay.completePaymentMethodTransaction({'items': items});
```

### Payment Flow Example

The order request object closely follows the format of the `PKPaymentRequest` class and thus its [documentation](https://developer.apple.com/library/ios/documentation/PassKit/Reference/PKPaymentRequest_Ref/index.html#//apple_ref/occ/cl/PKPaymentRequest) will make excellent reading.

```js
ApplePay.makePaymentRequest(
    {
          items: [
              {
                  label: '3 x Basket Items',
                  amount: 49.99
              },
              {
                  label: 'Next Day Delivery',
                  amount: 3.99
              },
                      {
                  label: 'My Fashion Company',
                  amount: 53.98
              }
          ],
          shippingMethods: [
              {
                  identifier: 'NextDay',
                  label: 'NextDay',
                  detail: 'Arrives tomorrow by 5pm.',
                  amount: 3.99
              },
              {
                  identifier: 'Standard',
                  label: 'Standard',
                  detail: 'Arrive by Friday.',
                  amount: 4.99
              },
              {
                  identifier: 'SaturdayDelivery',
                  label: 'Saturday',
                  detail: 'Arrive by 5pm this Saturday.',
                  amount: 6.99
              }
          ],
          merchantIdentifier: 'merchant.apple.test',
          currencyCode: 'GBP',
          countryCode: 'GB'
          billingAddressRequirement: 'none',
          shippingAddressRequirement: 'none',
          shippingType: 'shipping'
    })
    .then((response) => {
        // You should check the `response.action` and act appropriately.

        // When the user has authorized the payment:
        // Handle the token, asynchronously, i.e. pass to your merchant bank to
        // action the payment, then once finished, depending on the outcome:

        // Here is an example implementation:

        // MyPaymentProvider.authorizeApplePayToken(token.paymentData)
        //    .then((captureStatus) => {
        //        // Displays the 'done' green tick and closes the sheet.
        //        ApplePay.completeAuthorizationTransaction('success');
        //    })
        //    .catch((err) => {
        //        // Displays the 'failed' red cross.
        //        ApplePay.completeAuthorizationTransaction('failure');
        //    });


    })
    .catch((e) => {
        // Failed to open the Apple Pay sheet, or the user cancelled the payment.
    })
```

Valid values for the `shippingType` are:

 * `shipping` (default)
 * `delivery`
 * `store`
 * `service`

Valid values for the `billingAddressRequirement` and `shippingAddressRequirement`
properties are:

 * `none` (default)
 * `all`
 * `postcode`
 * `name`
 * `email`
 * `phone`

## Limitations and TODOs
* *Supported Payment Networks hard coded* (Visa, Mastercard, American Express) - This should be updated to be passed along in the order, but is rarely changed and trivial to alter in code.
* *Merchant Capabilities hard coded (3DS)* - This should be updated to be passed along in the order, but is rarely changed and trivial to alter in code.

## License

This project is licensed under *GNU General Public License v3.0*.

It is the work of [Sam Kelleher](https://samkelleher.com/). It is an alteration of an older project originally started by [@jbeuckm](https://github.com/jbeuckm)
