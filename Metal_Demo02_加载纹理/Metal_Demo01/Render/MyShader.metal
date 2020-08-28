//
//  MyShader.metal
//  Metal_Demo01
//
//  Created by Domy on 2020/8/27.
//  Copyright © 2020 Domy. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;// 使用命名空间 Metal

// 导入 Metal shader 代码和执行Metal API命令的C代码之间共享的头
#import "MyVertex.h"


// 顶点着色器输出和片段着色器输入 -- 经过了光栅化的数据
// 结构体
typedef struct {
    // 处理空间的顶点信息
    float4 clipSpacePosition[[position]];
    // 纹理
    float2 textureCoordinate;
} RasterizerData;


// 顶点着色函数
/*
处理顶点数据:
   1) 执行坐标系转换,将生成的顶点剪辑空间写入到返回值中.
   2) 将顶点颜色值传递给返回值
*/
/*
 参数含义：
 param1: uint vertexID [[vertex_id]]： 当前所处理的顶点号;
            不由我们操控 --> 三角形3个顶点，并行处理，我们无法知道当前处理的谁
 param2: constant MyVertex *vertices [[buffer(MyVertexInputIndexVertices)]]：
            buffer(index) --> vertices 的缓存位置；
            constant 修饰 表示 vertices 不可变
 */
vertex RasterizerData vertexShader (uint vertexID [[vertex_id]],
                                    constant MyVertex *vertices [[buffer(MyVertexInputIndexVertices)]],
                                    constant vector_uint2 *viewportSizePointer [[buffer(MyVertexInputIndexViewportSize)]]) {
    
    // 定义输出
    RasterizerData out;
    
    //初始化输出剪辑空间位置
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);

    // 索引到我们的数组位置以获得当前顶点
    // 我们的位置是在像素维度中指定的.
    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    // 将 vierportSizePointer 从 verctor_uint2 转换为 vector_float2 类型
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);

    // 归一化设备坐标空间,NDC --> 每个顶点着色器的输出位置在剪辑空间中
    // 剪辑空间中的(-1,-1)表示视口的左下角,而(1,1)表示视口的右上角.
    // 计算和写入 XY值到我们的剪辑空间的位置.为了从像素空间中的位置转换到剪辑空间的位置,我们将像素坐标除以视口的大小的一半.
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    
    out.clipSpacePosition.z = 0.0f;
    out.clipSpacePosition.w = 1.0f;

    // 把输入的颜色直接赋值给输出颜色. 这个值将于构成三角形的顶点的其他颜色值插值,从而为我们片段着色器中的每个片段生成颜色值.
    out.textureCoordinate = vertices[vertexID].textureCoordinate;
    
    // 完成! 将结构体传递到管道中下一个阶段:
    return out;
}


// 当顶点函数执行3次,三角形的每个顶点都执行一次后,则执行管道中的下一个阶段 --> 栅格化/光栅化 之后 --> 片元函数


// 片元函数
// [[stage_in]],片元着色函数使用的 单个片元输入数据 是由顶点着色函数输出,然后经过光栅化生成的。单个片元输入函数数据可以使用 "[[stage_in]]" 属性修饰符.
// 一个顶点着色函数可以读取单个顶点的输入数据, 这些输入数据存储于参数传递的 缓存 中,使用 顶点和实例ID 在这些缓存中寻址.读取到单个顶点的数据. 另外,单个顶点输入数据也可以通过使用 "[[stage_in]]" 属性修饰符的产生 传递给 顶点着色函数.
// 被 stage_in 修饰的结构体的成员不能是如下：Packed vectors 紧密填充类型向量, matrices 矩阵, structs 结构体, references or pointers to type 某类型的引用或指针. arrays,vectors,matrices 标量,向量,矩阵数组.
/* 参数 texture2d<half> colorTexture [[texture(MyTextureIndexBaseColor)]]
 纹理对象 colorTexture，对应的ID：texture(index)
 */

fragment float4 fragmentShader (RasterizerData in [[stage_in]],
                                texture2d<half> colorTexture [[texture(MyTextureIndexBaseColor)]]) {
    
    constexpr sampler textureSampler(mag_filter::linear,
                                     min_filter::linear);// 采样器放大缩小展示方式
    const half4 colorSampler = colorTexture.sample(textureSampler, in.textureCoordinate);
    // 纹素
    return float4(colorSampler);
}
