//
//  DirectPlugin.m
//  Antelope
//
//  Created by qizhang22 on 2025/6/26.
//

#import "DirectPlugin.h"
#import <DirectHelper/DirectHelperInterface.h>
#import "DirectManager.h"
#import "GNativeHttpRequest.h"

#define kDirectRegKey(userName) [@"Direct_reg_" stringByAppendingString:userName]

@implementation DirectPlugin


/** 判断是否注册 */
- (void)isReged:(HydraWebAction *)action withBlock:(HydraPluginBlock)block{
    [DirectHelperInterface getInstance].delegate = [DirectManager shareManager];
    NSString *userName = action.params[@"userName"];
    if ([LYCommonTool strNilOrEmpty:userName]) {
        block(@{@"data":@"userName为空"},ARGUMENT_MISSING);
        return;
    }
    BOOL isreged = [kUserDefault boolForKey:kDirectRegKey(userName)];
    block(@{@"data":@(isreged)},IFLY_OK);
}


/** 注册 */
- (void)regOperation:(HydraWebAction *)action withBlock:(HydraPluginBlock)block{
    NSString *userName = action.params[@"userName"];
    if ([LYCommonTool strNilOrEmpty:userName]) {
        block(@{@"data":@"userName为空"},ARGUMENT_MISSING);
        return;
    }
    [[DirectHelperInterface getInstance] regOperation:userName callBack:^(DirectHelperCode status, NSString * _Nonnull outData) {
        NSLog(@"注册返回：%lu -- %@",(unsigned long)status,outData);
        if (status == SUCCESS) {
            [kUserDefault setBool:YES forKey:kDirectRegKey(userName)];
        }
        block(@{@"data":outData,@"code":@(status)},IFLY_OK);
    }];
}


/** 验证 */
- (void)authOperation:(HydraWebAction *)action withBlock:(HydraPluginBlock)block{
    NSString *userName = action.params[@"userName"];
    NSString *signData = action.params[@"signData"];
    if ([LYCommonTool strNilOrEmpty:userName] || [LYCommonTool strNilOrEmpty:signData] ) {
        block(@{@"data":@"userName或signData为空"},ARGUMENT_MISSING);
        return;
    }
    [[DirectHelperInterface getInstance] authOperation:userName signData:signData callBack:^(DirectHelperCode status, NSString * _Nonnull outData) {
        NSLog(@"验证返回：%lu -- %@",(unsigned long)status,outData);
        if (status == SUCCESS) {
            NSError *error;
            outData = [outData stringByReplacingOccurrencesOfString:@"<GMKEY>" withString:@""];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[outData dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:&error];
            if (error) {
            }else{
                [GNativeHttpRequest postRequestByServiceUrl:kDdirectUrl andApi:@"auth/send" andParams:dict andCallBack:^(NSDictionary *resultData, NSError *error) {
                    if (!error) {
                        block(@{@"data":outData,@"code":@(status)},IFLY_OK);
                    }else{
                        block(@{@"data":error.description,@"code":@(NETWORKERROR)},IFLY_OK);
                        return;
                    }
                }];
            }
        }else{
            block(@{@"data":outData,@"code":@(status)},IFLY_OK);
        }
    }];
}


/** 开始进行活体检测 */
- (void)startFos:(HydraWebAction *)action withBlock:(HydraPluginBlock)block {
    if (![DirectHelperInterface getInstance].delegate) {
        [DirectHelperInterface getInstance].delegate = [DirectManager shareManager];
    }
    [[DirectHelperInterface getInstance] startFosBioassay:UserRoute.getCurrentViewController aliveCallback:^(int code, NSString *message, NSString *imageKey, NSString *image) {
        NSDictionary *dic = @{
            @"code":@(code)?:@0,
            @"message":message?:@"",
            @"imageKey":imageKey?:@"",
            @"image":image?:@""
        };
        block(dic,IFLY_OK);
        NSLog(@"活体检测返回：%d -- %@ -- %@ -- %@",code,message,imageKey,image);
    }];
}


/** 缓存身份标识 */
- (void)setIdentity:(HydraWebAction *)action withBlock:(HydraPluginBlock)block{
    [DirectHelperInterface getInstance].delegate = [DirectManager shareManager];
    NSString *idKey = action.params[@"idKey"];
    NSString *idValue = action.params[@"idValue"];
    if ([LYCommonTool strNilOrEmpty:idKey] || [LYCommonTool strNilOrEmpty:idValue]) {
        block(@{@"data":@"idKey或idValue为空"},ARGUMENT_MISSING);
        return;
    }
    [kUserDefault setValue:idValue forKey:idKey];
    block(@{@"code":@(0)},IFLY_OK);
}

@end
