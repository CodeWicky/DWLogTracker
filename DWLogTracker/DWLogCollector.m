//
//  DWLogCollector.m
//  DWLogTracker
//
//  Created by Wicky on 2018/4/22.
//  Copyright © 2018年 Wicky. All rights reserved.
//

#import "DWLogCollector.h"
#import "DWManualOperation.h"

static NSOperationQueue * defaultQueue = nil;
static NSMutableArray * logContainer = nil;

@implementation DWLogCollector
#pragma mark --- interface method ---
+(void)collectLog:(NSString *)log fileName:(NSString *)fileName subDirectory:(nullable NSString *)subDirectory onQueue:(NSOperationQueue *)queue {
    if (!fileName && !saveLogInMemory()) {///非本地非内存return掉
        return;
    }
    
    if (!queue) {
        queue = defaultQueue;
    }
    
    NSBlockOperation * op = [NSBlockOperation blockOperationWithBlock:^{
        if (saveLogInMemory()) {///根据模式选择是否保存至内存
            [logContainer addObject:log];
        }
        if (fileName) {///根据是否有文件名选择是否保存至文件系统
            createFile(fileName,subDirectory, NO);
            writeLog2File(log, fileName,subDirectory);
            NSLog(@"%@-写入成功",log);
        }
    }];
    
    [queue addOperation:op];
}

+(NSMutableArray *)logs {
    return [logContainer mutableCopy];
}

+(void)removeAllLogsOnQueue:(NSOperationQueue *)queue {
    if (!queue) {
        queue = defaultQueue;
    }
    
    NSBlockOperation * op = [NSBlockOperation blockOperationWithBlock:^{
        [logContainer removeAllObjects];
    }];
    
    [queue addOperation:op];
}

+(void)removeLocalLogFileWithFileName:(NSString *)fileName subDirectory:(NSString *)subDirectory onQueue:(nullable NSOperationQueue *)queue{
    if (!queue) {
        queue = defaultQueue;
    }
    
    NSBlockOperation * op = [NSBlockOperation blockOperationWithBlock:^{
        [[NSFileManager defaultManager] removeItemAtPath:[[logMainPath() stringByAppendingPathComponent:subDirectory] stringByAppendingPathComponent:fileName] error:nil];
    }];
    
    [queue addOperation:op];
}

+(void)removeAllLocalLogAtSubDirectory:(NSString *)subDirectory onQueue:(nullable NSOperationQueue *)queue {
    [self removeLocalLogFileWithFileName:@"" subDirectory:subDirectory onQueue:queue];
}

+(void)removeAllLocalLogFilesOnQueue:(NSOperationQueue *)queue {
    [self removeLocalLogFileWithFileName:@"" subDirectory:@"" onQueue:queue];
}

+(NSString *)collectorMainPath {
    return logMainPath();
}

+(NSArray *)localLogFiles {
    ///先获取全部子目录，在遍历添加子目录下所有文件
    NSArray * subDirs = [self localLogDirectorys];
    NSMutableArray * temp = [NSMutableArray arrayWithCapacity:0];
    [subDirs enumerateObjectsUsingBlock:^(NSString * dirName, NSUInteger idx, BOOL * _Nonnull stop) {
        [temp addObject:[self localLogFilesAtSubDirectory:dirName]];
    }];
    return temp;
}

+(NSArray *)localLogFilesAtSubDirectory:(NSString *)subDirectory {
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:subDirectoryPath(subDirectory) error:nil];
}

+(NSArray *)localLogDirectorys {
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logMainPath() error:nil];
}


#pragma mark --- inline func ---
NS_INLINE BOOL saveLogInMemory (void) {
#if DEBUG
    return YES;
#else
    return NO;
#endif
}

NS_INLINE BOOL isFileExist(NSString * fileName,NSString * subDirectory) {
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath(fileName,subDirectory)];
}

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

static BOOL createFile(NSString * fileName,NSString * subDirectory,BOOL overwrite) {
    if (isFileExist(fileName,subDirectory) && !overwrite) {///如果文件存在且非覆盖模式则无需创建
        return NO;
    }
    if (![[NSFileManager defaultManager] createDirectoryAtPath:subDirectoryPath(subDirectory) withIntermediateDirectories:YES attributes:nil error:nil]) {///先创建文件夹在创建文件
        return NO;
    }
    return [[NSFileManager defaultManager] createFileAtPath:filePath(fileName,subDirectory) contents:nil attributes:nil];
}

NS_INLINE void writeLog2File(NSString * log,NSString * fileName,NSString * subDirectory) {
    log = [log stringByAppendingString:@"\n"];
    ///添加至问价末尾
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:filePath(fileName,subDirectory)];
    [file seekToEndOfFile];
    [file writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}

#pragma mark --- override ---
+(void)initialize {
    ///当前状态量较少不采用单例模式，采用类方法及类常量实现
    [super initialize];
    defaultQueue = [NSOperationQueue new];
    defaultQueue.maxConcurrentOperationCount = 1;
    logContainer = [NSMutableArray arrayWithCapacity:0];
}
@end


