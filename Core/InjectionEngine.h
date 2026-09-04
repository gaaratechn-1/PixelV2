//
//  InjectionEngine.h
//  PixelV2
//
//  Master injection engine with MobileHouseArrest sandbox escape and local HTTP payload streaming.
//  Gaara Quantum Studio
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface InjectionEngine : NSObject

@property (nonatomic, copy) NSString *serverBaseUrl;

+ (instancetype)sharedEngine NS_SWIFT_NAME(shared());

- (void)injectModWithAlias:(NSString *)alias
        targetRelativePath:(NSString *)targetRelativePath
                  progress:(nullable void(^)(float progress))progressBlock
                completion:(void(^)(BOOL success, NSString *message))completion;

- (void)testContainerAccessWithCompletion:(void(^)(BOOL connected, NSString * _Nullable containerPath, NSString *message))completion;

@end

NS_ASSUME_NONNULL_END
