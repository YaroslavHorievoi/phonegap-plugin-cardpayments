/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVPaypalCardPayments.h"
#import "NSDictionary+SCAdditions.h"
#import "NSURL+SCAdditions.h"
#import "JSONKit.h"

#import <Cordova/CDVAvailability.h>

#ifndef __CORDOVA_3_2_0
#warning "The keyboard plugin is only supported in Cordova 3.2 or greater, it may not work properly in an older version. If you do use this plugin in an older version, make sure the HideKeyboardFormAccessoryBar and KeyboardShrinksView preference values are false."
#endif

// urls
NSString *const CDVPaypalPaymentUrl = @"paypalhere://takePayment";
NSString *const CDVPaypalPaymentCallbackUrl = @"auto-shop://paypal-complete?Type={Type}&InvoiceId={InvoiceId}&Tip={Tip}&Email={Email}&TxId={TxId}";

// request fields
NSString *const CDVPaypalPaymentRequestInvoiceKey = @"invoice";

// response fields
NSString *const CDVPaypalPaymentResponseUrlDataKey = @"data";
NSString *const CDVPaypalPaymentResponseDataKey = @"paymentId";
NSString *const CDVPaypalPaymentResponseOfflinePaymentIdKey = @"offlinePaymentId";
NSString *const CDVPaypalPaymentResponseStatusKey = @"status";
NSString *const CDVPaypalPaymentResponseUserInfoStringKey = @"userInfo";

// error fields
NSString *const CDVPaypalPaymentErrorCodeKey = @"code";
NSString *const CDVPaypalPaymentErrorDomainKey = @"domain";
NSString *const CDVPaypalPaymentErrorDomain = @"com.intertad.phonegap.plugins.cardpayments.paypal";

@implementation CDVPaypalCardPayments

 - (void)createPayment:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSError *error = nil;
    
    NSDictionary* params = [command.arguments objectAtIndex:0];

    NSDictionary *invoice = [params objectForKey: CDVPaypalPaymentRequestInvoiceKey];

    [self doPaypalPaymentWithInvoice: invoice
                               error: &error];

    if (error != nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                     messageAsDictionary:[error userInfo]];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)doPaypalPaymentWithInvoice: (NSDictionary *) invoice
                error: (NSError *__autoreleasing *) error {

    NSString *jsonInvoice = [invoice JSONString];
    
    NSString *encodedInvoice = [jsonInvoice SC_URLEncode];
    
    NSString *encodedPaymentTypes = [@"cash,card,paypal" SC_URLEncode];
    
    NSString *returnUrl = [NSString stringWithString:CDVPaypalPaymentCallbackUrl];
    
    NSString *encodedReturnUrl = [returnUrl SC_URLEncode];
    
    NSString *pphUrlString = [NSString stringWithFormat:@"%@?returnUrl=%@&accepted=%@&step=choosePayment&invoice=%@",
                              CDVPaypalPaymentUrl, encodedReturnUrl, encodedPaymentTypes, encodedInvoice];
    
    NSURL *pphUrl = [NSURL URLWithString:pphUrlString];
        
    UIApplication *application = [UIApplication sharedApplication];
    if ([application canOpenURL:pphUrl]){
        [application openURL:pphUrl];
    } else {
        *error = [NSError errorWithDomain: CDVPaypalPaymentErrorDomain
                                     code: 1
                                 userInfo: [NSDictionary dictionaryWithObject: @"PayPal Here app is not installed"
                                                                       forKey: @"message"]];
    }
}

- (void) handleCallback:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSURL *url = [NSURL URLWithString:[command.arguments objectAtIndex:0]];
    NSDictionary *urlParameters = [url SC_parameters];
    
    NSLog(@"Url: %@", url);
    
    if (urlParameters != nil) {
        
        NSString *type = [urlParameters SC_stringForKey:@"Type"];
        
        if (![type isEqualToString:@"UNKNOWN"]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: urlParameters];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsDictionary: urlParameters];
        }
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
