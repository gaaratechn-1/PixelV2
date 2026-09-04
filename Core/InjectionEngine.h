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
@property (nonatomic, copy, readonly, nullable) NSString *activeContainerPath;
@property (nonatomic, readonly) BOOL isContainerActive;

+ (instancetype)sharedEngine NS_SWIFT_NAME(shared());

- (void)testContainerAccessWithCompletion:(void(^)(BOOL connected, NSString * _Nullable containerPath, NSString *message))completion;

- (void)injectModWithAlias:(NSString *)alias
                 targetDir:(NSString *)targetDir
                filePrefix:(NSString *)filePrefix
          fallbackFilename:(NSString *)fallbackFilename
                  progress:(nullable void(^)(float progress))progressBlock
                completion:(void(^)(BOOL success, NSString *message))completion;

- (void)injectModWithAlias:(NSString *)alias
        targetRelativePath:(NSString *)targetRelativePath
                  progress:(nullable void(^)(float progress))progressBlock
                completion:(void(^)(BOOL success, NSString *message))completion;

- (NSArray<NSDictionary *> *)listContainerDirectory:(NSString *)subpath error:(NSError * _Nullable * _Nullable)outError;

@end

NS_ASSUME_NONNULL_END
