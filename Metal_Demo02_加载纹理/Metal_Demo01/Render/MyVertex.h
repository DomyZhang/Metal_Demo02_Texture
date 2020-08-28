//
//  MyVertex.h
//  Metal_Demo01
//
//  Created by Domy on 2020/8/27.
//  Copyright © 2020 Domy. All rights reserved.
//

/*
 介绍:
 头文件包含了 Metal shaders 与 C/Objc 源 之间共享的类型和枚举常数
*/


#ifndef MyVertex_h
#define MyVertex_h

// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用
typedef enum CCVertexInputIndex {
    
    // 顶点
    MyVertexInputIndexVertices     = 0,
    // 视图大小
    MyVertexInputIndexViewportSize = 1,
} MyVertexInputIndex;


// 结构体: 顶点/颜色 值
typedef struct {
    
    // 像素空间的位置
    // 像素中心点(100,100)
    vector_float2 position;

    // 2D 纹理
    vector_float2 textureCoordinate;
} MyVertex;

// 纹理索引
typedef enum MyTextureIndex {
    
    MyTextureIndexBaseColor = 0
}MyTextureIndex;

#endif /* MyVertex_h */
