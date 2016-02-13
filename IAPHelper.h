
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

extern NSString * const IAPHelperDomain;
extern const NSInteger IAPHelperErrorCodeProductNotFound;
extern const NSInteger IAPHelperErrorCodeNoProducts;

//when initial product load from itunes completes.
typedef void(^IAPHelperLoadProductsCompletion)(NSError * error);

//when a purchase completes.
typedef void(^IAPHelperPurchaseProductCompletion)(NSError * error, SKPaymentTransaction * transaction);

//called for each product that is restored.
//When all restores are completed the 'completed' flag is TRUE.
typedef void(^IAPHelperRestorePurchasesCompletion)(NSError * error, SKPaymentTransaction * transaction, BOOL completed);

@interface IAPHelper : NSObject <SKProductsRequestDelegate,SKPaymentTransactionObserver>

//Singletone instance. By default product info comes from InAppPurchases.plist.
//Use +setProductInfo: if you have custom product info.
+ (IAPHelper *) defaultHelper;

//Set this if you have custom product info.
//Example Product Info:
//<?xml version="1.0" encoding="UTF-8"?>
//<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
//<plist version="1.0">
//<array>
// <dict>
//  <key>Name</key>
//  <string>NewBoard</string>
//  <key>Title</key>
//  <string>New Board</string>
//  <key>Description</key>
//  <string>Purchase a new board</string>
//  <key>ProductId</key>
//  <string>com.apptitude.SmilesAndFrowns.NewBoard</string>
//  <key>Type</key>
//  <string>Consumable</string>
// </dict>
// <dict>
//  <key>Name</key>
//  <string>RemoveAds</string>
//  <key>Title</key>
//  <string>Remove Ads</string>
//  <key>Description</key>
//  <string>Remove ads from application</string>
//  <key>ProductId</key>
//  <string>com.apptitude.SmilesAndFrowns.RemoveAds</string>
//  <key>Type</key>
//  <string>Non-Consumable</string>
// </dict>
//</array>
//</plist>
+ (void) setProductInfo:(NSArray *) productInfo;

//utilities for getting info from product info
- (NSArray *) productIdsByNames:(NSArray *) productNames;
- (NSString *) productIdByName:(NSString *) productName;
- (NSString *) productTypeForProductId:(NSString *) productId;
- (NSString *) productNameByProductId:(NSString *) productId;
- (NSString *) productTitleForProductId:(NSString *) productId;
- (NSString *) productDescriptionForProductId:(NSString *) productId;
- (BOOL) hasPurchasedNonConsumableNamed:(NSString *) productNameInPlist;

//load product information from itunes.
- (void) loadItunesProductId:(NSString *) productId withCompletion:(IAPHelperLoadProductsCompletion) completion;
- (void) loadItunesProductNamed:(NSString *) productName withCompletion:(IAPHelperLoadProductsCompletion) completion;
- (void) loadItunesProductsWithNames:(NSArray *) productNames withCompletion:(IAPHelperLoadProductsCompletion) completion;
- (void) loadItunesProducts:(NSArray *) productIds withCompletion:(IAPHelperLoadProductsCompletion) completion;

//restore all purchases
- (void) restorePurchasesWithCompletion:(IAPHelperRestorePurchasesCompletion) completion;

//purchase a product id.
- (void) purchaseItunesProductNamed:(NSString *) name completion:(IAPHelperPurchaseProductCompletion) completion;
- (void) purchaseItunesProductId:(NSString *) productId completion:(IAPHelperPurchaseProductCompletion) completion;
- (void) purchaseItunesProductId:(NSString *) productId quantity:(NSInteger) quantity completion:(IAPHelperPurchaseProductCompletion) completion;

//get SKProduct after it's been loaded from itunes.
- (SKProduct *) productForItunesProductId:(NSString *) productId;
- (SKProduct *) productForName:(NSString *) name;

//some utilities for display prices.
- (NSString *) currencyCode;
- (NSNumber *) priceForItunesProductId:(NSString *) productId;
- (NSString *) priceStringForItunesProductId:(NSString *) productId;
- (NSString *) priceStringForItunesProductNamed:(NSString *) name;

@end
