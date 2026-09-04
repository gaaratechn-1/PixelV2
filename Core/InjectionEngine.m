//
//  InjectionEngine.m
//  PixelV2
//
//  Master injection engine with MobileHouseArrest sandbox escape and local HTTP payload streaming.
//  Gaara Quantum Studio
//

#import "InjectionEngine.h"
#import "MCMLease.h"
#import "mcm_bridge.h"

static NSString * const kFreeFire    = @"com.dts.freefireth";
static NSString * const kFreeFireMAX = @"com.dts.freefiremax";
static NSString * const kDefaultServer = @"http://192.168.1.15:8888";

@implementation InjectionEngine {
    dispatch_queue_t _workQueue;
    NSURLSession *_session;
    MCMLease *_retainedLease;
}

+ (instancetype)sharedEngine {
    static InjectionEngine *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[InjectionEngine alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _workQueue = dispatch_queue_create("com.pixelv2.injection", DISPATCH_QUEUE_SERIAL);
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 15.0;
        config.timeoutIntervalForResource = 45.0;
        _session = [NSURLSession sessionWithConfiguration:config];
        _serverBaseUrl = [kDefaultServer copy];
    }
    return self;
}

- (NSString *)activeContainerPath {
    return _retainedLease.rootPath;
}

- (BOOL)isContainerActive {
    return _retainedLease != nil && _retainedLease.activated;
}

- (MCMLease *)ensureActiveContainerWithError:(NSError **)outError {
    @synchronized (self) {
        if (_retainedLease && _retainedLease.activated && _retainedLease.rootPath.length > 0) {
            return _retainedLease;
        }

        NSError *err = nil;
        // 1. Probar Free Fire Estándar
        MCMLease *lease = [MCMLease leaseForBundleID:kFreeFire error:&err];
        if (!lease) {
            // 2. Probar Free Fire MAX
            lease = [MCMLease leaseForBundleID:kFreeFireMAX error:&err];
        }

        if (!lease) {
            if (outError) *outError = err ?: [NSError errorWithDomain:@"PixelV2.MCM" code:-1
                userInfo:@{NSLocalizedDescriptionKey: @"Free Fire no está instalado o nunca se ha abierto."}];
            return nil;
        }

        NSError *actErr = nil;
        if (![lease activate:&actErr]) {
            if (outError) *outError = actErr ?: [NSError errorWithDomain:@"PixelV2.MCM" code:-2
                userInfo:@{NSLocalizedDescriptionKey: @"Fallo al activar Sandbox Extension en el contenedor del juego."}];
            return nil;
        }

        _retainedLease = lease;
        return _retainedLease;
    }
}

- (void)testContainerAccessWithCompletion:(void(^)(BOOL connected, NSString * _Nullable containerPath, NSString *message))completion {
    dispatch_async(_workQueue, ^{
        NSError *err = nil;
        MCMLease *lease = [self ensureActiveContainerWithError:&err];
        if (!lease || !lease.rootPath.length) {
            NSString *msg = err.localizedDescription ?: @"Free Fire no está instalado o nunca se ha abierto";
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, msg);
            });
            return;
        }

        NSString *path = [lease.rootPath copy];
        // Se mantiene el lease activo para permitir navegación fluida en el contenedor
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES, path, [NSString stringWithFormat:@"Contenedor enlazado: %@", path]);
        });
    });
}

- (NSArray<NSDictionary *> *)listContainerDirectory:(NSString *)subpath error:(NSError * _Nullable * _Nullable)outError {
    NSError *err = nil;
    MCMLease *lease = [self ensureActiveContainerWithError:&err];
    if (!lease || !lease.rootPath.length) {
        if (outError) *outError = err;
        return @[];
    }

    NSString *targetDir = lease.rootPath;
    if (subpath.length > 0) {
        // Limpiar barras iniciales
        NSString *cleanSub = [subpath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        if (cleanSub.length > 0) {
            targetDir = [targetDir stringByAppendingPathComponent:cleanSub];
        }
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:targetDir isDirectory:&isDir] || !isDir) {
        return @[];
    }

    NSError *readErr = nil;
    NSArray<NSString *> *contents = [fm contentsOfDirectoryAtPath:targetDir error:&readErr];
    if (!contents) {
        if (outError) *outError = readErr;
        return @[];
    }

    NSMutableArray<NSDictionary *> *items = [NSMutableArray arrayWithCapacity:contents.count];
    for (NSString *name in contents) {
        NSString *itemPath = [targetDir stringByAppendingPathComponent:name];
        BOOL subIsDir = NO;
        BOOL exists = [fm fileExistsAtPath:itemPath isDirectory:&subIsDir];
        if (!exists) continue;

        NSDictionary *attrs = [fm attributesOfItemAtPath:itemPath error:nil];
        NSNumber *sizeNum = attrs[NSFileSize] ?: @0;

        [items addObject:@{
            @"name": name,
            @"isDirectory": @(subIsDir),
            @"size": sizeNum,
            @"path": itemPath
        }];
    }

    // Ordenar: primero carpetas, luego archivos alfabéticamente
    [items sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        BOOL dir1 = [obj1[@"isDirectory"] boolValue];
        BOOL dir2 = [obj2[@"isDirectory"] boolValue];
        if (dir1 != dir2) {
            return dir1 ? NSOrderedAscending : NSOrderedDescending;
        }
        return [obj1[@"name"] compare:obj2[@"name"] options:NSCaseInsensitiveSearch];
    }];

    return items;
}

- (void)injectModWithAlias:(NSString *)alias
                 targetDir:(NSString *)targetDir
                filePrefix:(NSString *)filePrefix
          fallbackFilename:(NSString *)fallbackFilename
                  progress:(nullable void(^)(float progress))progressBlock
                completion:(void(^)(BOOL success, NSString *message))completion {
    if (!alias.length || !targetDir.length) {
        if (completion) completion(NO, @"Parámetros de inyección inválidos.");
        return;
    }

    dispatch_async(_workQueue, ^{
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(0.1f); });
        }

        // 1. Asegurar contenedor y permisos de Sandbox activos
        NSError *leaseError = nil;
        MCMLease *lease = [self ensureActiveContainerWithError:&leaseError];
        if (!lease || !lease.rootPath.length) {
            NSString *msg = leaseError.localizedDescription ?: @"No se detectó el contenedor de Free Fire. Abre el juego primero.";
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, msg);
            });
            return;
        }

        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(0.3f); });
        }

        // 2. Descargar el payload desde el servidor local (192.168.1.15:8888)
        NSString *downloadUrlStr = [NSString stringWithFormat:@"%@/d/%@", self.serverBaseUrl, alias];
        NSURL *downloadUrl = [NSURL URLWithString:downloadUrlStr];
        if (!downloadUrl) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, @"URL del servidor local inválida.");
            });
            return;
        }

        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:downloadUrl];
        req.HTTPMethod = @"GET";

        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __block NSData *downloadedData = nil;
        __block NSError *netError = nil;

        NSURLSessionDataTask *task = [self->_session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
            downloadedData = data;
            netError = err;
            dispatch_semaphore_signal(sema);
        }];
        [task resume];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

        if (netError || !downloadedData || downloadedData.length == 0) {
            NSString *msg = [NSString stringWithFormat:@"Error al descargar payload (%@): %@", downloadUrlStr, netError.localizedDescription ?: @"Respuesta vacía"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, msg);
            });
            return;
        }

        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(0.6f); });
        }

        NSFileManager *fm = [NSFileManager defaultManager];

        // 3. Escribir archivo temporal en NSTemporaryDirectory() (patrón AutoMod)
        NSString *tempFileName = [NSString stringWithFormat:@"pixel_tmp_%@_%u", alias, arc4random_uniform(99999)];
        NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];

        NSError *writeTempErr = nil;
        BOOL tempWriteOk = [downloadedData writeToFile:tempFilePath options:NSDataWritingAtomic error:&writeTempErr];
        if (!tempWriteOk) {
            NSString *msg = [NSString stringWithFormat:@"No se pudo escribir archivo temporal: %@", writeTempErr.localizedDescription];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, msg);
            });
            return;
        }

        // 4. Asegurar existencia del directorio destino en el contenedor
        NSString *fullTargetDir = [lease.rootPath stringByAppendingPathComponent:targetDir];
        if (![fm fileExistsAtPath:fullTargetDir]) {
            NSError *dirErr = nil;
            if (![fm createDirectoryAtPath:fullTargetDir withIntermediateDirectories:YES attributes:nil error:&dirErr]) {
                [fm removeItemAtPath:tempFilePath error:nil];
                NSString *msg = [NSString stringWithFormat:@"Error creando directorio destino en el contenedor: %@", dirErr.localizedDescription];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(NO, msg);
                });
                return;
            }
        }

        // 5. Escaneo de coincidencia de prefijo (para reemplazar el hash exacto de Unity)
        NSString *targetFilename = (fallbackFilename.length > 0) ? fallbackFilename : [alias stringByAppendingString:@".unityfs"];
        NSArray<NSString *> *existingFiles = [fm contentsOfDirectoryAtPath:fullTargetDir error:nil];
        if (filePrefix.length > 0 && existingFiles) {
            for (NSString *file in existingFiles) {
                if ([file hasPrefix:filePrefix]) {
                    targetFilename = file;
                    break;
                }
            }
        }

        NSString *destinationFullPath = [fullTargetDir stringByAppendingPathComponent:targetFilename];

        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(0.85f); });
        }

        // 6. Eliminar archivo previo existente si aplica
        if ([fm fileExistsAtPath:destinationFullPath]) {
            NSError *remErr = nil;
            if (![fm removeItemAtPath:destinationFullPath error:&remErr]) {
                NSLog(@"[PixelV2] Advertencia eliminando archivo previo: %@", remErr.localizedDescription);
            }
        }

        // 7. Mover archivo temporal al destino en el contenedor
        NSError *moveErr = nil;
        BOOL moveOk = [fm moveItemAtPath:tempFilePath toPath:destinationFullPath error:&moveErr];
        if (!moveOk) {
            // Fallback de escritura directa si moveItem falla por límites de partición
            NSError *directWriteErr = nil;
            moveOk = [downloadedData writeToFile:destinationFullPath options:NSDataWritingAtomic error:&directWriteErr];
        }

        // Limpiar archivo temporal residual si quedó
        [fm removeItemAtPath:tempFilePath error:nil];

        // 8. Liberar sandbox lease inmediatamente (patrón AutoMod / Easy Cheats) para no dejar handles abiertos
        [lease invalidate];
        self->_retainedLease = nil;

        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(1.0f); });
        }

        if (!moveOk) {
            NSString *msg = [NSString stringWithFormat:@"Error al mover mod al contenedor (%@): %@", destinationFullPath.lastPathComponent, moveErr.localizedDescription ?: @"Fallo de escritura"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, msg);
            });
            return;
        }

        NSString *successMsg = [NSString stringWithFormat:@"Mod aplicado con éxito (%@ - %lu KB).", targetFilename, (unsigned long)(downloadedData.length / 1024)];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(YES, successMsg);
        });
    });
}

- (void)injectModWithAlias:(NSString *)alias
        targetRelativePath:(NSString *)targetRelativePath
                  progress:(nullable void(^)(float progress))progressBlock
                completion:(void(^)(BOOL success, NSString *message))completion {
    NSString *relDir = [targetRelativePath stringByDeletingLastPathComponent];
    NSString *fullFilename = [targetRelativePath lastPathComponent];
    NSString *prefix = fullFilename;

    if ([prefix containsString:@"."]) {
        NSRange dotRange = [prefix rangeOfString:@"."];
        prefix = [prefix substringToIndex:dotRange.location];
    }

    [self injectModWithAlias:alias
                   targetDir:relDir
                  filePrefix:prefix
            fallbackFilename:fullFilename
                    progress:progressBlock
                  completion:completion];
}

@end
