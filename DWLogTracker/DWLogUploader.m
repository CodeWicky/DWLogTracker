//
//  DWLogUploader.m
//  DWLogTracker
//
//  Created by MOMO on 2018/4/23.
//  Copyright © 2018年 Wicky. All rights reserved.
//

#import "DWLogUploader.h"
#import "DWManualOperation.h"


#define kRetryCount (5)

@interface DWLogUploader ()

@property (nonatomic ,strong) NSMutableArray * logPool;

@property (nonatomic ,strong) dispatch_semaphore_t sema;

@end

static DWLogUploader * uL = nil;
@implementation DWLogUploader

#pragma mark --- interface method ---

+(void)uploadLog:(NSString *)log onQueue:(NSOperationQueue *)queue {
    if (!log) {///无内容返回
        return;
    }
    __kindof DWLogUploader * uploader = [self uploader];
    if (!queue) {///如果传入队列为nil，则使用uploadQueue
        queue = uploader.uploadQueue;
    }
    if (uploader.poolSize == 0) {///缓冲池大小为0时直接上传
        [uploader uploadLogString:log onQueue:queue completion:nil];
    } else {///否则先添加至缓冲池，等缓冲池内日志条数达到上限再上传
        [uploader.logPool addObject:log];
        if (uploader.logPool.count >= uploader.poolSize) {
            
            ///数组操作时保证线程安全
            dispatch_semaphore_wait(uploader.sema, DISPATCH_TIME_FOREVER);
            NSArray * pool = [uploader.logPool copy];
            [uploader.logPool removeAllObjects];
            dispatch_semaphore_signal(uploader.sema);
            
            NSString * logString = [pool componentsJoinedByString:@"\n"];
            [uploader uploadLogString:logString onQueue:queue completion:nil];
        }
    }
}

+(void)uploadLog:(NSString *)log {
    [self uploadLog:log onQueue:nil];
}

+(void)uploadLogFile:(NSString *)fileName subDirectory:(NSString *)subDirectory onQueue:(NSOperationQueue *)queue completion:(void (^)(BOOL))completion {
    
    ///读取本地文件
    NSString * logStr = [NSString stringWithContentsOfFile:filePath(fileName,subDirectory) encoding:NSUTF8StringEncoding error:nil];
    if (!logStr) {///日志为空返回
        return;
    }
    __kindof DWLogUploader * uploader = [self uploader];
    if (!queue) {///如果传入队列为nil，则使用uploadQueue
        queue = uploader.uploadQueue;
    }
    [uploader uploadLogString:logStr onQueue:queue completion:completion];
}

+(void)uploadLogFile:(NSString *)fileName subDirectory:(NSString *)subDirectory completion:(void (^)(BOOL))completion {
    [self uploadLogFile:fileName subDirectory:subDirectory onQueue:nil completion:completion];
}

#pragma mark --- tool method ---
-(void)uploadLogString:(NSString *)logString onQueue:(NSOperationQueue *)queue completion:(void(^)(BOOL))completion {
    ///将请求封装为Operation后放入Queue中串行上传
    DWManualOperation * op = [DWManualOperation manualOperationWithHandler:^(DWManualOperation *op) {
        NSLog(@"uploading ...:%@",logString);
        
#warning 此处自行修改上传参数
        NSDictionary * paraDic = @{};
        ///发送日志
        [self uploadWithParameter:paraDic operation:op completion:completion retryCount:kRetryCount];
    }];
    [self.uploadQueue addOperation:op];
}

-(void)uploadWithParameter:(NSMutableDictionary *)paraDic operation:(DWManualOperation *)op completion:(void(^)(BOOL))completion retryCount:(NSUInteger)retryCount {
    
    ///每次进入重试次数-1
    retryCount--;
#warning 此处处理上传逻辑（自行接入请求框架，请求完成应调用 [op finishOperation]）
}

#pragma mark --- inline method ---
NS_INLINE NSString * logMainPath(void) {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"DWLogTracker/DWLogCollector"];
}

NS_INLINE NSString * subDirectoryPath(NSString * subDirectory) {
    if (!subDirectory.length) {
        return logMainPath();
    }
    return [logMainPath() stringByAppendingPathComponent:subDirectory];
}

NS_INLINE NSString * filePath(NSString * fileName,NSString * subDirectory) {
    return [subDirectoryPath(subDirectory) stringByAppendingPathComponent:fileName];
}

#pragma mark --- singleton ---
+(instancetype)uploader {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uL = [[self alloc] init];
    });
    return uL;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uL = [super allocWithZone:zone];
    });
    return uL;
}

-(id)copyWithZone:(struct _NSZone *)zone {
    return self;
}

-(id)mutableCopyWithZone:(struct _NSZone *)zone {
    return self;
}

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        _poolSize = 50;
        _sema = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark --- setter/getter ---
-(NSOperationQueue *)uploadQueue {
    if (!_uploadQueue) {///未指定上传队列则使用默认并发数为1的队列
        static NSOperationQueue * defaultQueue = nil;
        if (!defaultQueue) {
            defaultQueue = [NSOperationQueue new];
            defaultQueue.maxConcurrentOperationCount = 1;
        }
        return defaultQueue;
    }
    return _uploadQueue;
}

-(NSMutableArray *)logPool {
    if (!_logPool) {
        _logPool = [NSMutableArray arrayWithCapacity:0];
    }
    return _logPool;
}
@end
