//
//  DWLogTracker.h
//  DWLogTracker
//
//  Created by Wicky on 2018/4/22.
//  Copyright © 2018年 Wicky. All rights reserved.
//

/**
 DWLogTracker
 
 埋点工具类
 组装日志信息，写入本地或上传，同时提供日志捕捉、加密及分级的远端控制实现
 */
#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, LogLevel) {///日志等级
    LogLevelIgnore = 1 << 0,
    LogLevelNormal = 1 << 1,
    LogLevelInfo = 1 << 2,
    LogLevelWarning = 1 << 3,
    LogLevelError = 1 << 4,
    LogLevelAll = LogLevelNormal | LogLevelInfo | LogLevelWarning | LogLevelError,
};

@interface DWLogTracker : NSObject
NS_ASSUME_NONNULL_BEGIN

/**
 捕捉日志

 @param event 事件
 @param label 标签
 @param parameter 参数
 @param fileName 保存文件名
 @param subDirectory 子目录
 @param logLevel 日志等级
 
 @disc
 1.日志格式：*label* - event - *parameter(Json)* （加*项若为nil则不拼接）
 2.fileName为保存的文件名，无需添加路径。若为nil则不在本地保存，直接逐条上传，若不为nil则先保存至本地，调用 -uploadLogWithFileName: 在进行整体上传
 3.subDirectory为nil时也为非本地模式
 4.parameter中value支持格式：NSString/NSNumber/NSArray/NSDictionary/NSNull
 */
+(void)trackEvent:(NSString *)event label:(nullable NSString *)label parameter:(nullable NSDictionary *)parameter fileName:(nullable NSString *)fileName subDirectory:(nullable NSString *)subDirectory logLevel:(LogLevel)logLevel;
+(void)trackNormalEvent:(NSString *)event label:(nullable NSString *)label parameter:(nullable NSDictionary *)parameter fileName:(nullable NSString *)fileName subDirectory:(nullable NSString *)subDirectory;
+(void)trackInfoEvent:(NSString *)event label:(nullable NSString *)label parameter:(nullable NSDictionary *)parameter fileName:(nullable NSString *)fileName subDirectory:(nullable NSString *)subDirectory;
+(void)trackWarningEvent:(NSString *)event label:(nullable NSString *)label parameter:(nullable NSDictionary *)parameter fileName:(nullable NSString *)fileName subDirectory:(nullable NSString *)subDirectory;
+(void)trackErrorEvent:(NSString *)event label:(nullable NSString *)label parameter:(nullable NSDictionary *)parameter fileName:(nullable NSString *)fileName subDirectory:(nullable NSString *)subDirectory;
+(void)trackNormal:(NSString *)event label:(nullable NSString *)label;
+(void)trackInfo:(NSString *)event label:(nullable NSString *)label;
+(void)trackWarning:(NSString *)event label:(nullable NSString *)label;
+(void)trackError:(NSString *)event label:(nullable NSString *)label;


/**
 上传指定文件名的日志文件

 @param fileName 文件名
 */
+(void)uploadLogFile:(NSString *)fileName subDirectory:(NSString *)subDirectory;


/**
 上传子目录下所有日志文件
 
 @param subDirectory 子目录
 */
+(void)uploadAllLogFilesAtSubDirectory:(NSString *)subDirectory;


/**
 上传上次启动未上传完毕的日志文件
 */
+(void)uploadLeftLogFile;


/**
 设置是否开启日志收集
 
 @param on 是否收集
 */
+(void)setTrackSwitchOn:(BOOL)on;


/**
 返回当前是否收集日志

 @return 是否收集
 */
+(BOOL)trackSwitchOn;


/**
 设置是否需要日志加密

 @param encrypt 是否加密
 */
+(void)setNeedEncryptLog:(BOOL)encrypt;


/**
 返回日志是否需要加密

 @return 加密需求
 */
+(BOOL)needEncryptLog;


/**
 设置收集日志等级

 @param logLevel 日志等级
 */
+(void)setTrackLogLevel:(LogLevel)logLevel;


/**
 返回当前收集等级

 @return 当前收集等级
 */
+(LogLevel)logLevel;


/**
 远程获取日志收集等级

 @param parameter 参数
 @param completion 请求回调
 */
+(void)fetchTrackLogLevelWithParameter:(nullable id)parameter completion:(void(^)(LogLevel logLevel,BOOL needChange))completion;


/**
 远程获取是否需要加密日志

 @param parameter 参数
 @param completion 请求回调
 */
+(void)fetchNeedEncryptLogWithParameter:(nullable id)parameter completion:(void(^)(BOOL needEncrypt))completion;


/**
 远程获取是否收集日志

 @param parameter 参数
 @param completion 请求回调
 */
+(void)fetchWhetherTrackLogWithParameter:(nullable id)parameter completion:(void(^)(BOOL needTrack))completion;

NS_ASSUME_NONNULL_END
@end
