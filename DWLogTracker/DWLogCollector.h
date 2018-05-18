//
//  DWLogCollector.h
//  DWLogTracker
//
//  Created by Wicky on 2018/4/22.
//  Copyright © 2018年 Wicky. All rights reserved.
//

/**
 DWLogCollector
 
 日志收集类
 将埋点日志收集至内存或文件系统
 */
#import <Foundation/Foundation.h>

@interface DWLogCollector : NSObject
NS_ASSUME_NONNULL_BEGIN

/**
 收集日志

 @param log 日志
 @param fileName 保存文件名
 @param subDirectory 子目录
 
 @disc
 1.fileName为保存的文件名，无需添加路径，若为nil则不在本地保存。
 2.若子目录为nil则直接保存在主目录下
 */
+(void)collectLog:(NSString *)log fileName:(nullable NSString *)fileName subDirectory:(nullable NSString *)subDirectory onQueue:(nullable NSOperationQueue *)queue;


/**
 返回当前收集的日志
 
 @return 收集的日志数组
 */
+(NSMutableArray *)logs;


/**
 移除内存中的日志
 */
+(void)removeAllLogsOnQueue:(nullable NSOperationQueue *)queue;


/**
 以文件名移除本地日志文件

 @param fileName 文件名
 @param subDirectory 子目录
 
 @disc
 fileName为保存的文件名，无需添加路径
 */
+(void)removeLocalLogFileWithFileName:(NSString *)fileName subDirectory:(NSString *)subDirectory onQueue:(nullable NSOperationQueue *)queue;


/**
 移除子目录下所有文件

 @param subDirectory 子目录
 */
+(void)removeAllLocalLogAtSubDirectory:(NSString *)subDirectory onQueue:(nullable NSOperationQueue *)queue;


/**
 移除所有本地日志
 */
+(void)removeAllLocalLogFilesOnQueue:(nullable NSOperationQueue *)queue;


/**
 返回日志存储路径

 @return 日志存储路径
 */
+(NSString *)collectorMainPath;


/**
 返回当前全部本地日志文件

 @return 全部日志文件名数组
 */
+(NSArray *)localLogFiles;


/**
 返回子目录下所有文件

 @param subDirectory 子目录
 @return 子目录下全部文件
 */
+(NSArray *)localLogFilesAtSubDirectory:(NSString *)subDirectory;


/**
 返回主目录下全部日志目录

 @return 全部日志目录
 */
+(NSArray *)localLogDirectorys;
NS_ASSUME_NONNULL_END
@end
