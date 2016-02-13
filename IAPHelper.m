
#import "IAPHelper.h"

#define IAPHelperNonConsumableDefaultsKey @"IAPHelperPurchasedNonConsumables"

NSString * const IAPHelperDomain = @"com.apptitude.IAPHelper";
const NSInteger IAPHelperErrorCodeProductNotFound = 1;
const NSInteger IAPHelperErrorCodeNoProducts = 2;

static IAPHelper * _defaultHelper;
static NSArray * _productInfo;
static NSMutableDictionary * _loadedProducts;

@interface IAPHelper ()
@property BOOL isRestoring;
@property (strong) IAPHelperRestorePurchasesCompletion restorePurchasesCompletion;
@property (strong) IAPHelperLoadProductsCompletion loadProductsCompletion;
@property (strong) IAPHelperPurchaseProductCompletion purchaseProductCompletion;
@end

@implementation IAPHelper

+ (void) setProductInfo:(NSArray *) productInfo {
	_productInfo = productInfo;
}

+ (IAPHelper *) defaultHelper {
	if(!_defaultHelper) {
		if(!_productInfo) {
			NSString * plistFile = [[NSBundle mainBundle] pathForResource:@"InAppPurchases" ofType:@"plist"];
			NSArray * inAppPurchases = [NSArray arrayWithContentsOfFile:plistFile];
			_productInfo = inAppPurchases;
		}
		_defaultHelper = [[IAPHelper alloc] init];
	}
	return _defaultHelper;
}

- (id) init; {
	self = [super init];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	return self;
}

- (void) dealloc {
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	self.restorePurchasesCompletion = nil;
	self.loadProductsCompletion = nil;
	self.purchaseProductCompletion = nil;
}

- (NSDictionary *) productInfoDictForProductId:(NSString *) productId {
	for(NSDictionary * item in _productInfo) {
		if([item[@"ProductId"] isEqualToString:productId]) {
			return item;
		}
	}
	return nil;
}

- (NSDictionary *) productInfoDictForName:(NSString *) productName {
	for(NSDictionary * item in _productInfo) {
		if([item[@"Name"] isEqualToString:productName]) {
			return item;
		}
	}
	return nil;
}

- (BOOL) hasPurchasedNonConsumableNamed:(NSString *) productNameInPlist; {
	NSDictionary * defaults = @{IAPHelperNonConsumableDefaultsKey:@{}};
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	NSString * productId = [self productIdByName:productNameInPlist];
	if(!productId) {
		return FALSE;
	}
	NSDictionary * purchased = [[NSUserDefaults standardUserDefaults] objectForKey:IAPHelperNonConsumableDefaultsKey];
	if(purchased[productId]) {
		return [purchased[productId] boolValue];
	}
	return FALSE;
}

- (NSArray *) productIdsByNames:(NSArray *) productNames; {
	NSMutableArray * products = [NSMutableArray array];
	for(NSString * productName in productNames) {
		NSDictionary * info = [self productInfoDictForName:productName];
		[products addObject:info[@"ProductId"]];
	}
	return products;
}

- (NSString *) productNameByProductId:(NSString *) productId; {
	NSDictionary * info = [self productInfoDictForProductId:productId];
	return info[@"Name"];
}

- (NSString *) productTitleForProductId:(NSString *) productId; {
	SKProduct * product = _loadedProducts[productId];
	if(product.localizedTitle.length > 0) {
		return product.localizedTitle;
	}
	NSDictionary * info = [self productInfoDictForProductId:productId];
	if(info) {
		return info[@"Title"];
	}
	return nil;
}

- (NSString *) productDescriptionForProductId:(NSString *) productId; {
	SKProduct * product = _loadedProducts[productId];
	if(product.localizedDescription.length > 0) {
		return product.localizedDescription;
	}
	NSDictionary * info = [self productInfoDictForProductId:productId];
	if(info) {
		return info[@"Description"];
	}
	return nil;
}

- (NSString *) productTypeForProductId:(NSString *) productId {
	NSDictionary * info = [self productInfoDictForProductId:productId];
	return info[@"Type"];
}

- (NSString *) productIdByName:(NSString *) productName; {
	NSDictionary * info = [self productInfoDictForName:productName];
	return info[@"ProductId"];
}

- (NSString *) currencyCode {
	return [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
}

- (NSNumber *) priceForItunesProductId:(NSString *) productId {
	SKProduct * product = _loadedProducts[productId];
	if(!product) {
		return @(0);
	}
	return product.price;
}

- (SKProduct *) productForItunesProductId:(NSString *) productId {
	return _loadedProducts[productId];
}

- (SKProduct *) productForName:(NSString *) name {
	NSString * productId = [self productIdByName:name];
	return [self productForItunesProductId:productId];
}

- (NSString *) priceStringForItunesProductId:(NSString *) productId {
	SKProduct * product = _loadedProducts[productId];
	if(!product) {
		return @"";
	}
	NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:product.priceLocale];
	NSString * formattedPrice = [numberFormatter stringFromNumber:product.price];
	return formattedPrice;
}

- (NSString *) priceStringForItunesProductNamed:(NSString *) name {
	NSString * productId = [self productIdByName:name];
	return [self priceStringForItunesProductId:productId];
}

- (void) loadItunesProducts:(NSArray *) productIds withCompletion:(IAPHelperLoadProductsCompletion) completion {
	self.loadProductsCompletion = completion;
	NSLog(@"loading products: %@",productIds);
	SKProductsRequest * productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIds]];
	productsRequest.delegate = self;
	[productsRequest start];
}

- (void) loadItunesProductId:(NSString *) productId withCompletion:(IAPHelperLoadProductsCompletion) completion {
	[self loadItunesProducts:@[productId] withCompletion:completion];
}

- (void) loadItunesProductNamed:(NSString *) productName withCompletion:(IAPHelperLoadProductsCompletion) completion {
	NSString * productId = [self productIdByName:productName];
	[self loadItunesProducts:@[productId] withCompletion:completion];
}

- (void) loadItunesProductsWithNames:(NSArray *) productNames withCompletion:(IAPHelperLoadProductsCompletion) completion {
	NSArray * productIds = [self productIdsByNames:productNames];
	[self loadItunesProducts:productIds withCompletion:completion];
}

- (void) productsRequest:(SKProductsRequest *) request didReceiveResponse:(SKProductsResponse *)response {
	if(!_loadedProducts) {
		_loadedProducts = [NSMutableDictionary dictionary];
	}
	for(SKProduct * product in response.products) {
		_loadedProducts[product.productIdentifier] = product;
	}
	self.loadProductsCompletion(nil);
}

- (void) request:(SKRequest *) request didFailWithError:(NSError *)error {
	self.loadProductsCompletion(error);
}

- (void) purchaseItunesProductId:(NSString *) productId completion:(IAPHelperPurchaseProductCompletion)completion {
	return [self purchaseItunesProductId:productId quantity:1 completion:completion];
}

- (void) purchaseItunesProductNamed:(NSString *) name completion:(IAPHelperPurchaseProductCompletion) completion; {
	NSString * product = [self productIdByName:name];
	[self purchaseItunesProductId:product completion:completion];
}

- (void) purchaseItunesProductId:(NSString *) productId quantity:(NSInteger) quantity completion:(IAPHelperPurchaseProductCompletion)completion {
	SKProduct * purchaseProduct = _loadedProducts[productId];
	if(!purchaseProduct) {
		return completion([NSError errorWithDomain:IAPHelperDomain code:IAPHelperErrorCodeProductNotFound userInfo:@{NSLocalizedDescriptionKey:@"Product not loaded from iTunes Connect."}],nil);
	}
	self.purchaseProductCompletion = completion;
	SKMutablePayment * payment = [SKMutablePayment paymentWithProduct:purchaseProduct];
	payment.quantity = quantity;
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) paymentQueue:(SKPaymentQueue *) queue updatedTransactions:(NSArray *) transactions {
	for(SKPaymentTransaction * transaction in transactions) {
		if(transaction.transactionState == SKPaymentTransactionStatePurchased) {
			[self persistTransaction:transaction];
			[self completeTransaction:transaction];
		}
		
		if(transaction.transactionState == SKPaymentTransactionStateRestored) {
			[self persistTransaction:transaction];
			[self restoreTransaction:transaction];
		}
		
		if(transaction.transactionState == SKPaymentTransactionStateFailed) {
			[self failedTransaction:transaction];
		}
	}
}

- (void) persistTransaction:(SKPaymentTransaction *) transaction {
	NSString * type = [self productTypeForProductId:transaction.payment.productIdentifier];
	
	//only non-consumables are stored in defaults.
	if(type && [type isEqualToString:@"Non-Consumable"]) {
		NSDictionary * defaults = @{IAPHelperNonConsumableDefaultsKey:@{}};
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		
		NSDictionary * purchases = [[NSUserDefaults standardUserDefaults] objectForKey:IAPHelperNonConsumableDefaultsKey];
		NSMutableDictionary * updates = [NSMutableDictionary dictionaryWithDictionary:purchases];
		updates[transaction.payment.productIdentifier] = @(TRUE);
		
		[[NSUserDefaults standardUserDefaults] setObject:updates forKey:IAPHelperNonConsumableDefaultsKey];
	}
}

- (void) completeTransaction:(SKPaymentTransaction *) transaction {
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	if(self.purchaseProductCompletion) {
		self.purchaseProductCompletion(nil,transaction);
		self.purchaseProductCompletion = nil;
	}
}

- (void) restoreTransaction:(SKPaymentTransaction *) transaction {
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	if(self.restorePurchasesCompletion) {
		self.restorePurchasesCompletion(nil,transaction,FALSE);
	}
}

- (void) failedTransaction:(SKPaymentTransaction *) transaction {
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	if(self.purchaseProductCompletion) {
		self.purchaseProductCompletion(transaction.error,nil);
		self.purchaseProductCompletion = nil;
	}
}

- (void) restorePurchasesWithCompletion:(IAPHelperRestorePurchasesCompletion) completion {
	self.isRestoring = TRUE;
	self.restorePurchasesCompletion = completion;
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) paymentQueue:(SKPaymentQueue *) queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	self.isRestoring = FALSE;
	if(self.restorePurchasesCompletion) {
		self.restorePurchasesCompletion(error,nil,TRUE);
		self.restorePurchasesCompletion = nil;
	}
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	self.isRestoring = FALSE;
	if(self.restorePurchasesCompletion) {
		self.restorePurchasesCompletion(nil,nil,TRUE);
		self.restorePurchasesCompletion = nil;
	}
}

@end
