var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var executeCallback = function(callback, message) {
    if (typeof callback === 'function') {
        callback(message);
    }
};

var ApplePay = {

    /**
     * Determines if the current device supports Apple Pay and has a supported card installed.
     * @param {Function} [successCallback] - Optional success callback, recieves message object.
     * @param {Function} [errorCallback] - Optional error callback, recieves message object.
     * @returns {Promise}
     */
    canMakePayments: function(successCallback, errorCallback) {
        return new Promise(function(resolve, reject) {
            exec(function(message) {
                executeCallback(successCallback, message);
                resolve(message);
            }, function(message) {
                executeCallback(errorCallback, message);
                reject(message);
            }, 'ApplePay', 'canMakePayments', []);
        });

    },

    /**
     * Opens the Apple Pay sheet and shows the order information.
     * @param {Function} [successCallback] - Optional success callback, recieves message object.
     * @param {Function} [errorCallback] - Optional error callback, recieves message object.
     * @returns {Promise}
     */
    makePaymentRequest: function(order, successCallback, errorCallback) {

        return new Promise(function(resolve, reject) {
            exec(function(message) {
                executeCallback(successCallback, message);
                resolve(message);
            }, function(message) {
                executeCallback(errorCallback, message);
                reject(message);
            }, 'ApplePay', 'makePaymentRequest', [order]);
        });

    },

    /**
     * While the Apple Pay sheet is still open, and the callback from the `makePaymentRequest` has completed,
     * this call will pass the status to the sheet and close it if successfull.
     * @param {Function} [successCallback] - Optional success callback, recieves message object.
     * @param {Function} [errorCallback] - Optional error callback, recieves message object.
     * @returns {Promise}
     */
    completeAuthorizationTransaction: function(status, successCallback, errorCallback) {

        return new Promise(function(resolve, reject) {
            exec(function(message) {
                executeCallback(successCallback, message);
                resolve(message);
            }, function(message) {
                executeCallback(errorCallback, message);
                reject(message);
            }, 'ApplePay', 'completeAuthorizationTransaction', [status]);
        });

    }

    /**
     * Updates payment shipping methods and summary items.
     * @param {Object} [object] - an object that should contain a payment authorization status ('status'),
     * new shipping methods ('shippingMethods') and new summary items ('items').
     * @param {Function} [successCallback] - Optional success callback, recieves message object.
     * @param {Function} [errorCallback] - Optional error callback, recieves message object.
     * @returns {Promise}
     */
    completeShippingContactTransaction: function(object, successCallback, errorCallback) {

        return new Promise(function(resolve, reject) {
            exec(function(message) {
                executeCallback(successCallback, message);
                resolve(message);
            }, function(message) {
                executeCallback(errorCallback, message);
                reject(message);
            }, 'ApplePay', 'completeShippingContactTransaction', [object]);
        });

    }

    /**
     * Updates payment summary items.
     * @param {Object} [object] - an object that should contain new summary items ('items').
     * @param {Function} [successCallback] - Optional success callback, recieves message object.
     * @param {Function} [errorCallback] - Optional error callback, recieves message object.
     * @returns {Promise}
     */
    completePaymentMethodTransaction: function(object, successCallback, errorCallback) {

        return new Promise(function(resolve, reject) {
            exec(function(message) {
                executeCallback(successCallback, message);
                resolve(message);
            }, function(message) {
                executeCallback(errorCallback, message);
                reject(message);
            }, 'ApplePay', 'completePaymentMethodTransaction', [object]);
        });

    }

};

module.exports = ApplePay;
