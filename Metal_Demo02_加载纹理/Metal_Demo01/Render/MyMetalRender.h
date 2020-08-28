//
//  MyMetalRender.h
//  Metal_Demo01
//
//  Created by Domy on 2020/8/27.
//  Copyright © 2020 Domy. All rights reserved.
//

#import <Foundation/Foundation.h>

@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

@interface MyMetalRender : NSObject <MTKViewDelegate>

- (id)initWithMTKView:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
