//
//  DWLogTracker.m
//  DWLogTracker
//
//  Created by Wicky on 2018/4/22.
//  Copyright © 2018年 Wicky. All rights reserved.
//

#import "DWLogTracker.h"
#import "DWLogUploader.h"
#import "DWLogCollector.h"

static NSDateFormatter * timeFormatter = nil;
static NSOperationQueue * trackQueue = nil;
static LogLevel lv = 0;
static BOOL needTrack = NO;
static BOOL needEncrypt = YES;


NSString * const logLevelKey = @"LogLevelKey";
NSString * const logNeedEncryptKey = @"LogNeedEncryptKey";
NSString * const logSwitchKey = @"LogSwitchKey";
@implementation DWLogTracker

#pragma mark --- interface Method ---
+(void)trackEvent:(NSString *)event label:(NSString *)label parameter:(NSDictionary *)parameter fileName:(NSString *)fileName subDirectory:(NSString *)subDirectory logLevel:(LogLevel)logLevel {
    if (!needTrack || !(logLevel & lv)) {///如果关闭捕捉或当前与捕捉等级不同则返回
        return;
    }
    NSString * logString = logStringFactory(event, label, parameter);
    if ([self needEncryptLog]) {
        logString = encryptedString(logString);
    }
    NSLog(@"Track Log:%@",logString);
    if (!fileName.length || !subDirectory.length) {///非本地模式直接上传
        [DWLogUploader uploadLog:logString];
    } else {///本地模式写入本地
        [DWLogCollector collectLog:logString fileName:fileName subDirectory:subDirectory onQueue:trackQueue];
    }
}

+(void)trackNormalEvent:(NSString *)event label:(NSString *)label parameter:(NSDictionary *)parameter fileName:(NSString *)fileName subDirectory:(NSString *)subDirectory {
    [self trackEvent:event label:label parameter:parameter fileName:fileName subDirectory:subDirectory logLevel:LogLevelNormal];
}

+(void)trackInfoEvent:(NSString *)event label:(NSString *)label parameter:(NSDictionary *)parameter fileName:(NSString *)fileName subDirectory:(NSString *)subDirectory {
    [self trackEvent:event label:label parameter:parameter fileName:fileName subDirectory:subDirectory logLevel:LogLevelInfo];
}

+(void)trackWarningEvent:(NSString *)event label:(NSString *)label parameter:(NSDictionary *)parameter fileName:(NSString *)fileName subDirectory:(nullable NSString *)subDirectory {
    [self trackEvent:event label:label parameter:parameter fileName:fileName subDirectory:subDirectory logLevel:LogLevelError];
}

+(void)trackErrorEvent:(NSString *)event label:(NSString *)label parameter:(NSDictionary *)parameter fileName:(NSString *)fileName subDirectory:(nullable NSString *)subDirectory {
    [self trackEvent:event label:label parameter:parameter fileName:fileName subDirectory:subDirectory logLevel:LogLevelError];
}

+(void)trackNormal:(NSString *)event label:(NSString *)label {
    [self trackEvent:event label:label parameter:nil fileName:nil subDirectory:nil logLevel:LogLevelNormal];
}

+(void)trackInfo:(NSString *)event label:(NSString *)label {
    [self trackEvent:event label:label parameter:nil fileName:nil subDirectory:nil logLevel:LogLevelInfo];
}

+(void)trackWarning:(NSString *)event label:(NSString *)label {
    [self trackEvent:event label:label parameter:nil fileName:nil subDirectory:nil logLevel:LogLevelWarning];
}

+(void)trackError:(NSString *)event label:(NSString *)label {
    [self trackEvent:event label:label parameter:nil fileName:nil subDirectory:nil logLevel:LogLevelError];
}

+(void)uploadLogFile:(NSString *)fileName subDirectory:(nonnull NSString *)subDirectory {
    [DWLogUploader uploadLogFile:fileName subDirectory:subDirectory onQueue:trackQueue completion:^(BOOL success){
        if (success) {///上传成功后删除
            [DWLogCollector removeLocalLogFileWithFileName:fileName subDirectory:subDirectory onQueue:trackQueue];
        }
    }];
}

+(void)uploadAllLogFilesAtSubDirectory:(NSString *)subDirectory {
    NSOperationQueue * q = [NSOperationQueue new];
    NSArray * files = [DWLogCollector localLogFilesAtSubDirectory:subDirectory];
    [files enumerateObjectsUsingBlock:^(NSString * fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        ///程序启动上传，并行上传
        [DWLogUploader uploadLogFile:fileName subDirectory:subDirectory onQueue:q completion:^(BOOL success){
            if (success) {
                [DWLogCollector removeLocalLogFileWithFileName:fileName subDirectory:subDirectory onQueue:q];
            }
        }];
    }];
}

+(void)uploadLeftLogFile {
    NSArray * dirs = [DWLogCollector localLogDirectorys];
    NSOperationQueue * q = [NSOperationQueue new];
    [dirs enumerateObjectsUsingBlock:^(NSString * dirName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray * files = [DWLogCollector localLogFilesAtSubDirectory:dirName];
        if (files.count == 0) {///空文件夹，删除
            [DWLogCollector removeAllLocalLogAtSubDirectory:dirName onQueue:q];
        } else {
            [files enumerateObjectsUsingBlock:^(NSString * fileName, NSUInteger idx, BOOL * _Nonnull stop) {
                ///程序启动上传，并行上传
                [DWLogUploader uploadLogFile:fileName subDirectory:dirName onQueue:q completion:^(BOOL success){
                    if (success) {
                        [DWLogCollector removeLocalLogFileWithFileName:fileName subDirectory:dirName onQueue:q];
                    }
                }];
            }];
        }
    }];
}

+(void)setTrackSwitchOn:(BOOL)on {
    if ([self trackSwitchOn] != on) {
        changeConfig(logSwitchKey, @(on));
        needTrack = on;
    }
}

+(BOOL)trackSwitchOn {
    return needTrack;
}

+(void)setNeedEncryptLog:(BOOL)encrypt {
    if ([self needEncryptLog] != encrypt) {
        changeConfig(logNeedEncryptKey, @(encrypt));
        needEncrypt = encrypt;
    }
}

+(BOOL)needEncryptLog {
    return needEncrypt;
}

+(void)setTrackLogLevel:(LogLevel)logLevel {
    if ([self logLevel] != logLevel) {
        changeConfig(logLevelKey, @(logLevel));
        lv = logLevel;
    }
}

+(LogLevel)logLevel {
    return lv;
}

+(void)fetchWhetherTrackLogWithParameter:(id)parameter completion:(void (^)(BOOL))completion {
    if (completion) {
        completion(YES);
    }
}

+(void)fetchNeedEncryptLogWithParameter:(id)parameter completion:(void (^)(BOOL))completion {
    if (completion) {
        completion(NO);
    }
}

+(void)fetchTrackLogLevelWithParameter:(id)parameter completion:(void (^)(LogLevel,BOOL))completion {
    if (completion) {
        completion(lv,NO);
    }
}

#pragma mark --- inline func ---
NS_INLINE NSString * logMainPath(void) {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"DWLogTracker"];
}

NS_INLINE void changeConfig(NSString * key,id value) {
    if (!key || !value) {
        return;
    }
    NSString * sP = [logMainPath() stringByAppendingPathComponent:@"DWLogTrackerConfig.plist"];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithContentsOfFile:sP];
    if (!dic) {
        dic = @{}.mutableCopy;
    }
    [dic setValue:value forKey:key];
    [dic writeToFile:sP atomically:YES];
}

NS_INLINE id configValue(NSString * key) {
    if (!key) {
        return nil;
    }
    NSString * sP = [logMainPath() stringByAppendingPathComponent:@"DWLogTrackerConfig.plist"];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithContentsOfFile:sP];
    if (!dic) {///如果字典为空添加默认配置
        dic = @{logSwitchKey:@(YES),logNeedEncryptKey:@(NO),logLevelKey:@(LogLevelAll)}.mutableCopy;
        [dic writeToFile:sP atomically:YES];
    }
    return dic[key];
}

NS_INLINE NSString * jsonString(NSDictionary * dic) {
    if (!dic) {
        return nil;
    }
    NSError * error = nil;
    NSData * data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    if (error || !data) {
        return nil;
    }
    NSString * jsonString = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@" " withString:@""];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return jsonString;
}

NS_INLINE NSString * logStringFactory(NSString * event,NSString * label,NSDictionary * parameter) {
    NSString * temp = @"";
    if (label.length) {
        temp = [temp stringByAppendingString:[NSString stringWithFormat:@"%@-",label]];
    }
    if (event.length) {
        temp = [temp stringByAppendingString:[NSString stringWithFormat:@"%@-",event]];
    }
    NSString * jsonStr = jsonString(parameter);
    if (jsonStr.length) {
        temp = [temp stringByAppendingString:[NSString stringWithFormat:@"%@-",jsonStr]];
    }
    if (!temp.length) {
        return nil;
    }
    temp = [temp substringToIndex:temp.length - 1];
    
    temp = [[timeFormatter stringFromDate:[NSDate date]] stringByAppendingString:[NSString stringWithFormat:@" %@",temp]];
    return temp;
}

NS_INLINE NSString * encryptedString(NSString * oriStr) {
#warning 再此处理加密
    return oriStr;
}

#pragma mark --- override ---

+(void)initialize {
    ///当前状态量较少不采用单例模式，采用类方法及类常量实现
    [super initialize];
    lv = [configValue(logLevelKey) unsignedIntegerValue];
    needEncrypt = [configValue(logNeedEncryptKey) boolValue];
    needTrack = [configValue(logSwitchKey) boolValue];
    trackQueue = [NSOperationQueue new];
    trackQueue.maxConcurrentOperationCount = 1;
    timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSS"];
    
}
@end
