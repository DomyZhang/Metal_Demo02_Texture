//
//  MyMetalRender.m
//  Metal_Demo01
//
//  Created by Domy on 2020/8/27.
//  Copyright © 2020 Domy. All rights reserved.
//

#import "MyMetalRender.h"
#import "MyVertex.h"

// 定义颜色结构体
typedef struct {
    float red, green, blue, alpha;
} Color;

@implementation MyMetalRender
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    
    // 渲染管道有 顶点着色器和片元着色器 它们存储在 .metal shader 文件中
    id<MTLRenderPipelineState> _pipelineState;
    
    // 当前视图大小,这样我们可以在渲染通道使用这个视图
    vector_uint2 _viewportSize;
    
    // 存储顶点 缓冲区
    id<MTLBuffer> _vertices;
    // 顶点个数
    NSUInteger _numVertices;
    
    // 纹理对象
    id<MTLTexture> _texture;
    
    MTKView *myMTKView;
}

- (id)initWithMTKView:(MTKView *)mtkView {
    
    if (self = [super init]) {
        
        // 1.获取 GPU 设备
        _device = mtkView.device;
        
        myMTKView = mtkView;
        
        // 顶点数据
        [self configVertex];
        
        // 设置渲染管道相关
        [self configPipeline];
        
        // 设置纹理数据
        [self configTexture];
        
    }
    return self;
}

- (void)configVertex {
    
    // 1.根据顶点/纹理坐标建立一个MTLBuffer
    static const MyVertex quadVertices[] = {
        // 像素坐标,纹理坐标
        { {  250,  -250 },  { 1.f, 0.f } },
        { { -250,  -250 },  { 0.f, 0.f } },
        { { -250,   250 },  { 0.f, 1.f } },
        
        { {  250,  -250 },  { 1.f, 0.f } },
        { { -250,   250 },  { 0.f, 1.f } },
        { {  250,   250 },  { 1.f, 1.f } },
    };
    
    // 2. 创建顶点缓冲区
    _vertices = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
    
    // 3.计算顶点数量
    _numVertices = sizeof(quadVertices) / sizeof(MyVertex);
    
}

- (void)configPipeline {
    
    // 1.在项目中加载所有的(.metal)着色器文件
    // 从bundle中获取.metal文件
    id<MTLLibrary> defaultLib = [_device newDefaultLibrary];
    // 顶点/片元函数
    id<MTLFunction> vertexFunc = [defaultLib newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunc = [defaultLib newFunctionWithName:@"fragmentShader"];
    
    // 2.配置用于创建管道状态的管道
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.label = @"Simple Pipeline";
    // 可编程顶点/片元函数, 用于处理渲染过程中的各个顶点
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    // 一组存储颜色数据的组件
    pipelineDescriptor.colorAttachments[0].pixelFormat = myMTKView.colorPixelFormat;
    
    // 3.同步创建并返回 渲染管线状态对象
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    // 判断是否返回了管线状态对象
    if (!_pipelineState) {
        // 如果没有正确设置管道描述符，则管道状态创建可能失败
        NSLog(@"Failed to created pipeline state, error %@", error);
        return;
    }
    
    // 创建命令队列
    _commandQueue = [_device newCommandQueue];
}

- (void)configTexture {
    
    UIImage *image = [UIImage imageNamed:@"cat.jpg"];
    
    // 纹理描述
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    // 设置 每个像素有红绿蓝和alpha通道，其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1);
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    // 设置纹理尺寸
    textureDescriptor.width = image.size.width;
    textureDescriptor.height = image.size.height;
    
    // 创建纹理
    _texture = [_device newTextureWithDescriptor:textureDescriptor];
    
    // 4. 创建MTLRegion 结构体  [纹理上传的范围]
    /*
     typedef struct {
        MTLOrigin origin; //开始位置x,y,z
        MTLSize   size; //尺寸width,height,depth
     } MTLRegion;
     */
    // MLRegion 结构用于标识纹理的特定区域。 此 demo 使用图像数据填充整个纹理，因此，覆盖整个纹理的像素区域等于纹理的尺寸。
    MTLRegion region = {{ 0, 0, 0 }, {image.size.width, image.size.height, 1}};
    
    // 获取图片位图数据
    Byte *imageByte = [self loadImage:image];
    
    // UIImage 的数据需要转成二进制才能上传，且不用jpg、png的 NSData
    if (imageByte) {
        
        // 复制图片数据到 texture
        [_texture replaceRegion:region mipmapLevel:0 withBytes:imageByte bytesPerRow:4*image.size.width];
        free(imageByte);
        imageByte = NULL;
    }
}

- (Byte *)loadImage:(UIImage *)image {
    
    CGImageRef sprImage = image.CGImage;
    size_t width = CGImageGetWidth(sprImage);
    size_t height = CGImageGetHeight(sprImage);
    
    // 计算图片大小
    Byte *imgData = (Byte *)calloc(4 * width * height, sizeof(Byte));
    
    // 创建画布
    CGContextRef sprContext = CGBitmapContextCreate(imgData, width, height, 8, width *4, CGImageGetColorSpace(sprImage), kCGImageAlphaPremultipliedLast);
    // 在CGContextRef上绘图
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(sprContext, rect, sprImage);
    
    // 图片翻转
    CGContextTranslateCTM(sprContext, rect.origin.x, rect.origin.y);
    CGContextTranslateCTM(sprContext, 0, rect.size.height);
    CGContextScaleCTM(sprContext, 1.0, -1.0);
    CGContextScaleCTM(sprContext, -rect.origin.x, -rect.origin.y);
    CGContextDrawImage(sprContext, rect, sprImage);
    
    // 绘制完成 释放
    CGContextRelease(sprContext);
    
    return imgData;
    
    return nil;
}

#pragma mark - MTKView delegate -
// 每当视图渲染时 调用
- (void)drawInMTKView:(nonnull MTKView *)view {
    
    // 1.
    // 2.为当前渲染的每个渲染 传递 创建 一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommandBuffer";
    
    // 3.MTLRenderPassDescriptor:一组渲染目标，用作渲染通道生成的像素的输出目标。
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor) {
        // 4.创建 渲染命令编码
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        // 5.设置 可绘制区域 Viewport
        /*
        typedef struct {
            double originX, originY, width, height, znear, zfar;
        } MTLViewport;
         */
        // 视口指定 Metal 渲染内容的 drawable 区域。 视口是具有x和y偏移，宽度和高度以及近和远平面的 3D 区域
        // 为管道分配自定义视口,需要通过调用 setViewport：方法将 MTLViewport 结构 编码为渲染命令编码器。 如果未指定视口，Metal会设置一个默认视口，其大小与用于创建渲染命令编码器的 drawable 相同。
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        
        // 6.设置当前渲染管道状态对象
        [renderEncoder setRenderPipelineState:_pipelineState];

        // 7.数据传递给着色函数 -- 从应用程序(OC 代码)中发送数据给 Metal 顶点着色器 函数
        // 顶点 + 颜色
        //   1) 指向要传递给着色器的内存的指针
        //   2) 我们想要传递的数据的内存大小
        //   3)一个整数索引，它对应于我们的“vertexShader”函数中的缓冲区属性限定符的索引。
        [renderEncoder setVertexBuffer:_vertices offset:0 atIndex:MyVertexInputIndexVertices];

        // viewPortSize 数据
        //  1) 发送到顶点着色函数中,视图大小
        //  2) 视图大小内存空间大小
        //  3) 对应的索引
        [renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:MyVertexInputIndexViewportSize];
        
        // 纹理数据传
        [renderEncoder setFragmentTexture:_texture atIndex:MyTextureIndexBaseColor];
        
        
        // 8.绘制 draw
        // @method drawPrimitives:vertexStart:vertexCount:
        // @brief 在不使用索引列表的情况下,绘制图元
        // @param 绘制图形组装的基元类型
        // @param 从哪个位置数据开始绘制,一般为0
        // @param 每个图元的顶点个数,绘制的图型顶点数量
        /*
         MTLPrimitiveTypePoint = 0, 点
         MTLPrimitiveTypeLine = 1, 线段
         MTLPrimitiveTypeLineStrip = 2, 线环
         MTLPrimitiveTypeTriangle = 3,  三角形
         MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
         */
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        
        // 9.编码完成 - 表示该编码器生成的命令都已完成,并且从 MTLCommandBuffer 中分离
        [renderEncoder endEncoding];
        
        // 10.一旦框架缓冲区完成，使用当前可绘制的进度表
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    // 11. 最后,完成渲染并将命令缓冲区推送到 GPU
    [commandBuffer commit];
}

// 当 MTKView 视图发生大小改变时调用
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
    // 保存可绘制的大小，绘制时，将会把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

@end
