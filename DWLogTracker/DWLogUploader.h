//
//  DWLogUploader.h
//  DWLogTracker
//
//  Created by MOMO on 2018/4/23.
//  Copyright © 2018年 Wicky. All rights reserved.
//

/**
 日志上传类
 上传日志或日志文件
 */
#import <Foundation/Foundation.h>

@interface DWLogUploader : NSObject
NS_ASSUME_NONNULL_BEGIN

/**
 上传队列，未指定默认为最大并发量为1的子队列
 */
@property (nonatomic ,strong) NSOperationQueue * uploadQueue;


/**
 日志缓冲池大小，默认值为50
 */
@property (nonatomic ,assign) NSInteger poolSize;


/**
 单例方法

 @return 实例
 */
+(instancetype)uploader;


/**
 上传日志

 @param log 日志
 @param queue 上传队列
 
 @disc
 1.存在日志缓冲池，只有缓冲池中日志数量超过上限才会上传
 2.
 */
+(void)uploadLog:(NSString *)log onQueue:(nullable NSOperationQueue *)queue;
+(void)uploadLog:(NSString *)log;


/**
 上传日志文件

 @param fileName 文件名
 @param queue 上传队列
 @param subDirectory 子目录
 @param completion 上传完成回调
 */
+(void)uploadLogFile:(NSString *)fileName subDirectory:(NSString *)subDirectory onQueue:(nullable NSOperationQueue *)queue completion:(nullable void(^)(BOOL))completion;
+(void)uploadLogFile:(NSString *)fileName subDirectory:(NSString *)subDirectory completion:(nullable void(^)(BOOL success))completion;
NS_ASSUME_NONNULL_END
@end
