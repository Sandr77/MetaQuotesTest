//
//  ExceptionCatcher.h
//  MetaQuotesTest
//
//  Created by Andrey Snetkov on 25/03/2019.
//  Copyright © 2019 Andrey Snetkov. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}
