//
//  MCMLease.h
//  Pixelcheat
//
//  Sandbox Extension Lease (3105 bad_query + MCM bridge)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCMLease : NSObject

@property (nonatomic, copy, nullable) NSString *rootPath;
@property (nonatomic, assign) BOOL activated;

+ (nullable instancetype)leaseForBundleID:(NSString *)bundleID
                                    error:(NSError * _Nullable * _Nullable)error;

- (BOOL)activate:(NSError * _Nullable * _Nullable)error;
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
