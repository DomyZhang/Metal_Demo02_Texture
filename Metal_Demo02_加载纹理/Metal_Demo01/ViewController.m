//
//  ViewController.m
//  Metal_Demo01
//
//  Created by Domy on 2020/8/27.
//  Copyright © 2020 Domy. All rights reserved.
//

#import "ViewController.h"
#import "MyMetalRender.h"

@interface ViewController () {
    
    MTKView *_view;
    MyMetalRender *_render;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _view = (MTKView *)self.view;
    // 一个 MTLDevice 对象 表示 GPU
    _view.device = MTLCreateSystemDefaultDevice();
    // 判断是否设置成功
    if (!_view.device) {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    // render
    _render = [[MyMetalRender alloc] initWithMTKView:_view];
    
    [_render mtkView:_view drawableSizeWillChange:_view.drawableSize];
    _view.delegate = _render;
    // 设置帧速率 --> 指定时间来调用 drawInMTKView 方法--视图需要渲染时调用 默认60
//    _view.preferredFramesPerSecond = 60;
}


@end
