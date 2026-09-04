//
//  MCMLease.m
//  Pixelcheat
//
//  Sandbox Extension Lease using 3105 bad_query + MCM bridge
//  Based on YangJiii/3105 and 0xjohnnydev/MobileHouseArrest-PoC
//

#import "MCMLease.h"
#import "mcm_bridge.h"
#import "bad_query.h"
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

@implementation MCMLease {
    int64_t _badQueryHandle;
    NSString *_bundleID;
}

+ (nullable instancetype)leaseForBundleID:(NSString *)bundleID
                                    error:(NSError * _Nullable * _Nullable)error {
    MCMLease *lease = [[MCMLease alloc] init];
    lease->_badQueryHandle = -1;
    lease->_bundleID = [bundleID copy];
    lease.activated = NO;

    // === Strategy 1: MCM Container Path Lookup (works with any bundle ID) ===
    if (MCMBridgeAvailable()) {
        NSString *lookupErr = nil;
        NSString *path = MCMContainerPathForIdentifier(2, bundleID, NO, &lookupErr);
        if (path.length > 0) {
            lease.rootPath = path;
            return lease;
        }
    }

    // === Strategy 2: Enumerate containers via bad_query_list + metadata scan ===
    {
        char *appRoot = "/var/mobile/Containers/Data/Application";
        char *listing = bad_query_list(appRoot, 2000000);
        if (listing) {
            NSString *listStr = [NSString stringWithUTF8String:listing];
            free(listing);
            for (NSString *dir in [listStr componentsSeparatedByString:@"\n"]) {
                if (dir.length == 0) continue;
                NSString *metaPath = [dir stringByAppendingPathComponent:
                    @".com.apple.mobile_container_manager.metadata.plist"];

                // Grant temporary read access to check metadata
                char pathBuf[1024];
                strlcpy(pathBuf, dir.UTF8String, sizeof(pathBuf));
                int64_t h = bad_query(pathBuf, false, NULL, false);
                if (h >= 0) {
                    NSDictionary *meta = [NSDictionary dictionaryWithContentsOfFile:metaPath];
                    bad_query_release(h);
                    if ([meta[@"MCMMetadataIdentifier"] isEqualToString:bundleID]) {
                        NSString *resolved = dir;
                        if ([resolved hasPrefix:@"/var/"])
                            resolved = [@"/private" stringByAppendingString:resolved];
                        lease.rootPath = resolved;
                        return lease;
                    }
                }
            }
        }
    }

    // === Strategy 3: Direct filesystem scan (if sandbox escape is already active) ===
    {
        NSString *baseDir = @"/private/var/mobile/Containers/Data/Application";
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *subdirs = [fm contentsOfDirectoryAtPath:baseDir error:nil];
        for (NSString *sub in subdirs) {
            NSString *containerPath = [baseDir stringByAppendingPathComponent:sub];
            NSString *metaPath = [containerPath stringByAppendingPathComponent:
                @".com.apple.mobile_container_manager.metadata.plist"];
            NSDictionary *meta = [NSDictionary dictionaryWithContentsOfFile:metaPath];
            if ([meta[@"MCMMetadataIdentifier"] isEqualToString:bundleID]) {
                lease.rootPath = containerPath;
                return lease;
            }
        }
    }

    if (error) {
        *error = [NSError errorWithDomain:@"Pixelcheat.MCM" code:-1
            userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"No se encontro el contenedor de %@. Abra el juego primero.", bundleID]}];
    }
    return nil;
}

- (BOOL)activate:(NSError * _Nullable * _Nullable)error {
    if (self.activated) return YES;

    if (!self.rootPath.length) {
        if (error) *error = [NSError errorWithDomain:@"Pixelcheat.MCM" code:-2
            userInfo:@{NSLocalizedDescriptionKey: @"Ruta del contenedor vacia"}];
        return NO;
    }

    // === Try bad_query to get sandbox extension for the container root ===
    char pathBuf[1024];
    strlcpy(pathBuf, self.rootPath.UTF8String, sizeof(pathBuf));
    int64_t handle = bad_query(pathBuf, true, NULL, false);
    if (handle >= 0) {
        _badQueryHandle = handle;
        self.activated = YES;
        return YES;
    }

    // === Try MCMActivateContainerPath (requires MobileHouseArrest bundle ID) ===
    if (MCMBridgeAvailable()) {
        NSString *actErr = nil;
        NSString *actPath = MCMActivateContainerPath(2, _bundleID, NO, &actErr);
        if (actPath.length > 0) {
            self.activated = YES;
            return YES;
        }
    }

    // === Test if path is already writable (sandbox escape may be globally active) ===
    int fd = open(self.rootPath.UTF8String, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (fd >= 0) {
        close(fd);
        self.activated = YES;
        return YES;
    }

    if (error) {
        *error = [NSError errorWithDomain:@"Pixelcheat.MCM" code:-3
            userInfo:@{NSLocalizedDescriptionKey:
                @"No se pudo activar la extension de sandbox. Asegurese de que la app este firmada correctamente."}];
    }
    return NO;
}

- (void)invalidate {
    if (_badQueryHandle >= 0) {
        bad_query_release(_badQueryHandle);
        _badQueryHandle = -1;
    }
    self.activated = NO;
}

- (void)dealloc {
    [self invalidate];
}

@end
