#import "Header.h"

%hook CKContainer
- (id)_setupWithContainerID:(id)a options:(id)b { return nil; }
- (id)_initWithContainerIdentifier:(id)a { return nil; }
%end

%hook CKEntitlements
- (id)initWithEntitlementsDict:(NSDictionary *)entitlements {
	NSMutableDictionary *mutEntitlements = [entitlements mutableCopy];
	[mutEntitlements removeObjectForKey:@"com.apple.developer.icloud-container-environment"];
	[mutEntitlements removeObjectForKey:@"com.apple.developer.icloud-services"];
	return %orig([mutEntitlements copy]);
}
%end

%hook NSFileManager
- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
	if (NSURL *ourAppGroupURL = getAppGroupPathIfExists()) {
		NSURL *fakeAppGroupURL = [ourAppGroupURL URLByAppendingPathComponent:groupIdentifier];
		createDirectoryIfNotExists(fakeAppGroupURL.path);
		return fakeAppGroupURL;
	}

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *fakePath = [[paths lastObject] stringByAppendingPathComponent:groupIdentifier];
	createDirectoryIfNotExists(fakePath);
	return [NSURL fileURLWithPath:fakePath];
}
%end

%hook NSUserDefaults
- (id)_initWithSuiteName:(NSString *)suiteName container:(NSURL *)container {
	NSURL *appGroupURL = getAppGroupPathIfExists();
	if (!appGroupURL) {
		return %orig(suiteName, container);
	}

	if (![suiteName hasPrefix:@"group"]) {
		return %orig(suiteName, container);
	}

	if (NSURL *customContainerURL = [appGroupURL URLByAppendingPathComponent:suiteName]) {
		return %orig(suiteName, customContainerURL);
	}

	return %orig(suiteName, container);
}
%end
