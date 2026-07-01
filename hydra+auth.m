//
//  HydraPlugin+Auth.m
//  Antelope
//
//  Created by qizhang22 on 2025/2/18.
//

#import "HydraPlugin+Auth.h"
#import <objc/runtime.h>
#import "LYDefaultServerRequest.h"

NSString *GCurrentServiceId;
NSArray *GAuthPluginArr;
NSMutableDictionary *GauthCacheDic;


@implementation HydraPlugin (Auth)

static NSMutableDictionary<NSString *, NSValue *> *originalMethodImplementations;

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    IMP originalIMP = method_getImplementation(originalMethod);
    const char *typeEncoding = method_getTypeEncoding(originalMethod);

    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            originalIMP,
                            typeEncoding);
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }

    // 保存原始方法的实现
    NSString *key = [NSString stringWithFormat:@"%@_%@", NSStringFromClass(class), NSStringFromSelector(originalSelector)];
    originalMethodImplementations[key] = [NSValue valueWithPointer:originalIMP];
}

void swizzleHydraPluginMethods(void) {
    int numClasses;
    Class *classes = NULL;

    numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);

        for (int i = 0; i < numClasses; i++) {
            Class cls = classes[i];
            if (class_getSuperclass(cls) == [HydraPlugin class]) {
                unsigned int methodCount;
                Method *methods = class_copyMethodList(cls, &methodCount);

                for (unsigned int j = 0; j < methodCount; j++) {
                    Method method = methods[j];
                    SEL selector = method_getName(method);
                    const char *typeEncoding = method_getTypeEncoding(method);
                    NSString *methodName = NSStringFromSelector(selector);
                    if ([methodName.lowercaseString containsString:@"withblock"] && strstr(typeEncoding, "@") && strstr(typeEncoding, "@?")) {
                        NSString *selectorName = NSStringFromSelector(selector);
                        NSString *swizzledSelectorName = [NSString stringWithFormat:@"swizzled_%@", selectorName];
                        SEL swizzledSelector = NSSelectorFromString(swizzledSelectorName);

                        if (!class_getInstanceMethod(cls, swizzledSelector)) {
                            class_addMethod(cls, swizzledSelector, (IMP)swizzled_method, typeEncoding);
                        }
                        swizzleMethod(cls, selector, swizzledSelector);
                    }
                }

                free(methods);
            }
        }

        free(classes);
    }
}

void swizzled_method(id self, SEL _cmd, HydraWebAction *action, HydraPluginBlock block) {
    NSLog(@"Swizzled method called: %@", NSStringFromSelector(_cmd));

    // 能力鉴权判断
//    BOOL shouldContinue = YES;
    NSString *plugin = nil;
    if ([action isKindOfClass:[HydraWebAction class]]) {
        plugin = [NSString stringWithFormat:@"%@.%@",action.service,action.action];
    }
    if (![LYCommonTool strNilOrEmpty:plugin]) {
        [HydraPlugin pluginAuthWithPlugin:plugin Handle:^(BOOL auth) {
            if (auth) {
                // 调用原方法的实现
                NSString *key = [NSString stringWithFormat:@"%@_%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
                IMP originalIMP = [originalMethodImplementations[key] pointerValue];

                if (originalIMP) {
                    ((void (*)(id, SEL, HydraWebAction *, HydraPluginBlock))originalIMP)(self, _cmd, action, block);
                }
            } else {
                // 鉴权失败
                if (block) {
                    block(nil, ILLEGAL_OPERATION);
                }
            }
        }];
    }
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        originalMethodImplementations = [NSMutableDictionary dictionary];
        swizzleHydraPluginMethods();
        [self getAuthPlugins];
    });
}




+(void)getAuthPlugins{
    LYDefaultServerRequest *request = [LYDefaultServerRequest new];
    request.requestURL = @"/wqt/antelope-wqt/ability/getAbilityAuthList";
    request.requestMethod = LYRequestMethodGET;
    [request startWithSuccess:^(LYNetworkResponse * _Nonnull response) {
        NSDictionary *responseObject = response.responseObject;
        if([responseObject[@"code"] integerValue] == 0) {
            if ([responseObject[@"result"] isKindOfClass:[NSArray class]]) {
                GAuthPluginArr = responseObject[@"result"];
                NSLog(@"%@",GAuthPluginArr)
            }
        }
    } failure:^(LYNetworkResponse * _Nonnull response) {
    }];
}

+(void)pluginAuthWithPlugin:(NSString *)plugin Handle:(void(^)(BOOL auth))handle{
    // 参数检查
    if (!plugin || ![plugin isKindOfClass:[NSString class]]) {
        handle(NO);
        return;
    }

    // 初始化缓存字典
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        GauthCacheDic = [NSMutableDictionary new];
    });
    
    // 检查缓存
    NSArray *autArr = [GauthCacheDic valueForKey:GCurrentServiceId];
    if ([autArr isKindOfClass:[NSArray class]] && autArr.count > 0) {
        handle([autArr containsObject:plugin]);
        return;
    }
    
    if ([autArr isKindOfClass:[NSString class]]) {
        if ([(NSString *)autArr isEqualToString:@"all"]) {
            handle(YES);
            return;
        } else if ([(NSString *)autArr isEqualToString:@"none"]) {
            handle(NO);
            return;
        }
    }
    
    // 特殊情况处理
    if ([LYCommonTool strNilOrEmpty:GCurrentServiceId]) {
        handle(YES);
        return;
    }
    
    if (![GAuthPluginArr isKindOfClass:[NSArray class]] || GAuthPluginArr.count == 0) {
        handle(YES);
        return;
    }
    
    if (![GAuthPluginArr containsObject:plugin]) {
        handle(YES);
        return;
    }
    
    LYDefaultServerRequest *request = [LYDefaultServerRequest new];
    request.requestURL = @"/wqt/antelope-wqt/ability/getAppAbility";
    request.requestMethod = LYRequestMethodGET;
    request.requestParameter = @{
        @"appId": GCurrentServiceId
    };
        
    [request startWithSuccess:^(LYNetworkResponse * _Nonnull response) {
        NSDictionary *responseObject = response.responseObject;
        if ([responseObject[@"code"] integerValue] == 0) {
            NSArray *tmpArr = responseObject[@"result"];
            if ([tmpArr isKindOfClass:[NSArray class]]) {
                if (tmpArr.count > 0) {
                    if (tmpArr.count == 1 && [tmpArr.firstObject isEqualToString:@"all"]) {
                        [GauthCacheDic setValue:@"all" forKey:GCurrentServiceId];
                        handle(YES);
                        return;
                    } else {
                        [GauthCacheDic setValue:tmpArr forKey:GCurrentServiceId];
                        handle([tmpArr containsObject:plugin]);
                        return;
                    }
                } else {
                    [GauthCacheDic setValue:@"none" forKey:GCurrentServiceId];
                    handle(NO);
                    return;
                }
            } else {
                [GauthCacheDic setValue:@"none" forKey:GCurrentServiceId];
                handle(NO);
                return;
            }
        } else {
            [GauthCacheDic setValue:@"none" forKey:GCurrentServiceId];
            handle(NO);
            return;
        }
    } failure:^(LYNetworkResponse * _Nonnull response) {
        [GauthCacheDic setValue:@"none" forKey:GCurrentServiceId];
        handle(NO);
        return;
    }];
}

@end
