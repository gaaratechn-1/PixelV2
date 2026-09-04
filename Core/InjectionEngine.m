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
        config.timeoutIntervalForResource = 30.0;
        _session = [NSURLSession sessionWithConfiguration:config];
        _serverBaseUrl = [kDefaultServer copy];
    }
    return self;
}

- (MCMLease *)resolveContainerWithError:(NSError **)outError {
    NSError *err = nil;
    // 1. Probar Free Fire Estándar
    MCMLease *lease = [MCMLease leaseForBundleID:kFreeFire error:&err];
    if (lease) return lease;

    // 2. Probar Free Fire MAX
    lease = [MCMLease leaseForBundleID:kFreeFireMAX error:&err];
    if (lease) return lease;

    if (outError) *outError = err;
    return nil;
}

- (void)testContainerAccessWithCompletion:(void(^)(BOOL connected, NSString * _Nullable containerPath, NSString *message))completion {
    dispatch_async(_workQueue, ^{
        NSError *err = nil;
        MCMLease *lease = [self resolveContainerWithError:&err];
        if (!lease) {
            NSString *msg = err.localizedDescription ?: @"Free Fire no está instalado o nunca se ha abierto";
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, msg);
            });
            return;
        }

        NSError *actErr = nil;
        if (![lease activate:&actErr]) {
            NSString *msg = actErr.localizedDescription ?: @"Error al activar sandbox token";
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, lease.rootPath, msg);
            });
            return;
        }

        NSString *path = [lease.rootPath copy];
        [lease invalidate];

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES, path, [NSString stringWithFormat:@"Contenedor enlazado: %@", path]);
        });
    });
}

- (void)injectModWithAlias:(NSString *)alias
        targetRelativePath:(NSString *)targetRelativePath
                  progress:(nullable void(^)(float progress))progressBlock
                completion:(void(^)(BOOL success, NSString *message))completion {
    if (!alias.length || !targetRelativePath.length) {
        if (completion) completion(NO, @"Parámetros de inyección inválidos.");
        return;
    }

    dispatch_async(_workQueue, ^{
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(0.1f); });
        }

        // 1. Resolver contenedor de Free Fire
        NSError *leaseError = nil;
        MCMLease *lease = [self resolveContainerWithError:&leaseError];
        if (!lease) {
            NSString *msg = leaseError.localizedDescription ?: @"No se detectó el contenedor de Free Fire. Abre el juego primero.";
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, msg);
            });
            return;
        }

        // 2. Activar permisos de Sandbox (Token MCM)
        NSError *actError = nil;
        if (![lease activate:&actError]) {
            NSString *msg = actError.localizedDescription ?: @"Fallo al obtener acceso al sandbox del juego.";
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, msg);
            });
            return;
        }

        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(0.3f); });
        }

        // 3. Descargar el payload desde el servidor local (192.168.1.15:8888)
        NSString *downloadUrlStr = [NSString stringWithFormat:@"%@/d/%@", self.serverBaseUrl, alias];
        NSURL *downloadUrl = [NSURL URLWithString:downloadUrlStr];
        if (!downloadUrl) {
            [lease invalidate];
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
            [lease invalidate];
            NSString *msg = [NSString stringWithFormat:@"Error conectando al servidor local (%@): %@", downloadUrlStr, netError.localizedDescription ?: @"Respuesta vacía"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, msg);
            });
            return;
        }

        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(0.7f); });
        }

        // 4. Construir ruta absoluta en el contenedor del juego
        NSString *containerRoot = lease.rootPath;
        NSString *targetFullPath = [containerRoot stringByAppendingPathComponent:targetRelativePath];
        NSString *targetDir = [targetFullPath stringByDeletingLastPathComponent];

        NSFileManager *fm = [NSFileManager defaultManager];

        // Crear directorios si no existen
        if (![fm fileExistsAtPath:targetDir]) {
            NSError *dirErr = nil;
            if (![fm createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:&dirErr]) {
                [lease invalidate];
                NSString *msg = [NSString stringWithFormat:@"Error creando directorio en contenedor: %@", dirErr.localizedDescription];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(NO, msg);
                });
                return;
            }
        }

        // 5. Escritura atómica directa del payload
        BOOL writeOk = [downloadedData writeToFile:targetFullPath atomically:YES];
        if (!writeOk) {
            // Reintento con removeItem previo si existía
            [fm removeItemAtPath:targetFullPath error:nil];
            writeOk = [downloadedData writeToFile:targetFullPath atomically:YES];
        }

        // Liberar el lease de sandbox
        [lease invalidate];

        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(1.0f); });
        }

        if (!writeOk) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, @"Error al escribir archivo en el contenedor de Free Fire.");
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(YES, [NSString stringWithFormat:@"Inyección completada (%lu bytes aplicados).", (unsigned long)downloadedData.length]);
        });
    });
}

@end
