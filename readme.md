# IAPHelper

A simple helper for in app purchases.

## InAppPurchases.plist

By default it will load product information from the plist _InAppPurchases.plist_.

Example Plist:

````
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<dict>
		<key>Name</key>
		<string>MoreCoins</string>
		<key>Title</key>
		<string>More Coins</string>
		<key>ProductId</key>
		<string>com.myapp.MoreCoins</string>
		<key>Type</key>
		<string>Consumable</string>
	</dict>
	<dict>
		<key>Name</key>
		<string>RemoveAds</string>
		<key>Title</key>
		<string>Remove Ads</string>
		<key>ProductId</key>
		<string>com.myapp.RemoveAds</string>
		<key>Type</key>
		<string>Non-Consumable</string>
	</dict>
</array>
</plist>

````

You can override product information with:

````
[[IAPHelper defaultHelper] setProductInfo:myProducts];
````

## Getting Product Information from the Plist

Use these methods:

````
- (NSArray *) productIdsByNames:(NSArray *) productNames;
- (NSString *) productIdByName:(NSString *) productName;
- (NSString *) productTypeForProductId:(NSString *) productId;
- (NSString *) productNameByProductId:(NSString *) productId;
- (NSString *) productTitleForProductId:(NSString *) productId;
- (NSString *) productDescriptionForProductId:(NSString *) productId;
````

## Loading SKProducts from iTunes

Loaded products from itunes are stored internally for you.

````
- (void) loadItunesProductId:(NSString *) productId withCompletion:(IAPHelperLoadProductsCompletion) completion;
- (void) loadItunesProductNamed:(NSString *) productName withCompletion:(IAPHelperLoadProductsCompletion) completion;
- (void) loadItunesProductsWithNames:(NSArray *) productNames withCompletion:(IAPHelperLoadProductsCompletion) completion;
- (void) loadItunesProducts:(NSArray *) productIds withCompletion:(IAPHelperLoadProductsCompletion) completion;
````

## Restoring Purchases

````
- (void) restorePurchasesWithCompletion:(IAPHelperRestorePurchasesCompletion) completion;
````

## Making Purchases

````
- (void) purchaseItunesProductNamed:(NSString *) name completion:(IAPHelperPurchaseProductCompletion) completion;
- (void) purchaseItunesProductId:(NSString *) productId completion:(IAPHelperPurchaseProductCompletion) completion;
- (void) purchaseItunesProductId:(NSString *) productId quantity:(NSInteger) quantity completion:(IAPHelperPurchaseProductCompletion) completion;
````

## Getting SKProducts

SKProducts are available after you load then from itunes

````
- (SKProduct *) productForItunesProductId:(NSString *) productId;
- (SKProduct *) productForName:(NSString *) name;
````

## Checking if already purchased

This will only work for Non-Consumable products.

````
- (BOOL) hasPurchasedNonConsumableNamed:(NSString *) productNameInPlist;
````

## Utilities

````
- (NSString *) currencyCode;
- (NSNumber *) priceForItunesProductId:(NSString *) productId;
- (NSString *) priceStringForItunesProductId:(NSString *) productId;
- (NSString *) priceStringForItunesProductNamed:(NSString *) name;
````

## Completion Blocks

````
//when product load from itunes completes.
typedef void(^IAPHelperLoadProductsCompletion)(NSError * error);

//when a purchase completes.
typedef void(^IAPHelperPurchaseProductCompletion)(NSError * error, SKPaymentTransaction * transaction);

//called for each product that is restored.
//When all restores are completed the 'completed' flag is TRUE.
typedef void(^IAPHelperRestorePurchasesCompletion)(NSError * error, SKPaymentTransaction * transaction, BOOL completed);
````