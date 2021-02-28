[![Alt text](https://img.shields.io/static/v1?label=Language&message=lua&color=blue)](http://www.lua.org/)![Alt text](https://img.shields.io/static/v1?label=Release&message=V1.0.0&color=yellow)[![Alt text](https://img.shields.io/static/v1?label=Blog&message=csdn&color=blue)](https://blog.csdn.net/weixin_40783338?spm=1000.2115.3001.5343)[![Alt text](https://img.shields.io/static/v1?label=openresty&message=Nginx&color=green)](https://github.com/openresty/lua-nginx-module)



# lua-resty-zipkin
------------------------------


### Content

[Zipkin](https://zipkin.io/)是一款开源的**分布式实时数据追踪系统**（Distributed Tracking System），基于 **Google Dapper**的论文设计而来，由 Twitter 公司开发贡献。其主要功能是聚集来自各个异构系统的实时监控数据。分布式跟踪系统还有其他比较成熟的实现，例如：Naver的Pinpoint、Apache的HTrace、阿里的鹰眼Tracing、京东的Hydra、新浪的Watchman，美团点评的CAT，skywalking等。

为什么用**Zipkin**:

随着业务越来越复杂，系统也随之进行各种拆分，特别是随着微服务架构和容器技术的兴起，看似简单的一个应用，后台可能有几十个甚至几百个服务在支撑；一个前端的请求可能需要多次的服务调用最后才能完成；当请求变慢或者不可用时，我们无法得知是哪个后台服务引起的，这时就需要解决如何快速定位服务故障点，**Zipkin分布式跟踪系统**就能很好的解决这样的问题。

具体可以看看[zipkin的详细介绍](https://zipkin.io/)

-------------------

### Introduction

APM服务采用zipkin,为此先介绍zipkin相关概念:

- 1. **Trace**
Zipkin使用Trace结构表示对一次请求的跟踪，一次请求可能由后台的若干服务负责处理，每个服务的处理是一个Span，Span之间有依赖关系，Trace就是树结构的Span集合；

- 2. **Span**
每个服务的处理跟踪是一个Span，可以理解为一个基本的工作单元，包含了一些描述信息：id，parentId，name，timestamp，duration，annotations等，例如：
```json
{
      "traceId": "bd7a977555f6b982", #标记一次请求的跟踪，相关的Spans都有相同的traceId；
      "name": "get-traces", #span的名称，一般是接口方法的名称
      "id": "ebf33e1a81dc6f71", #span id
      "parentId": "bd7a977555f6b982",   
      "timestamp": 1458702548478000,
      "duration": 354374,
      "annotations": [
        {
          "endpoint": {
            "serviceName": "zipkin-query",
            "ipv4": "192.168.1.2",
            "port": 9411
          },
          "timestamp": 1458702548786000,
          "value": "cs"
        }
      ],
      "binaryAnnotations": [
        {
          "key": "lc",
          "value": "JDBCSpanStore",
          "endpoint": {
            "serviceName": "zipkin-query",
            "ipv4": "192.168.1.2",
            "port": 9411
          }
        }
      ]
}
```

- 3. **traceId**：标记一次请求的跟踪，相关的Spans都有相同的traceId；
- 4. **id**：span id；
- 5. **name**：span的名称，一般是接口方法的名称；
- 6. **parentId**：
可选的id，当前Span的父Span id，通过parentId来保证Span之间的依赖关系，
如果没有parentId，表示当前Span为根Span；

- 7. **timestamp**：
Span创建时的时间戳，使用的单位是微秒（而不是毫秒），所有时间戳都有错误，
包括主机之间的时钟偏差以及时间服务重新设置时钟的可能性，
出于这个原因，Span应尽可能记录其duration；

- 8. **duration**：持续时间使用的单位是微秒（而不是毫秒）；

- 9. **annotations注释**：用于及时记录事件；有一组核心注释用于定义RPC请求的开始和结束；
```shell
cs:Client Send，客户端发起请求；
sr:Server Receive，服务器接受请求，开始处理；
ss:Server Send，服务器完成处理，给客户端应答；
cr:Client Receive，客户端接受应答从服务器
```

--------------------------------------

### 架构

- **普通方式**
```
   服务向zipkin通过http上传数据,zipkin接受、分析数据，过程全在内存进行，成本高，无法持久化数据。
```

` **升级方式**
```
   服务 ------ipload-----> kafka  <----------订阅----------------zipkin服务--------(从kafka获取数据,上传ES)-------->elasticsearch 
```

### Installation

```bash

1 将libs目录拷贝至Openresty项目一级目录下，按下面使用说明使用。

```

### 使用


- 1. **修改nginx.conf：**
 
   server模块增加:

```bash
    access_by_lua_file  "conf/libs/opentrace/resty_access_by_lua.lua"; # 在access阶段,初始化span
    log_by_lua_file "conf/libs/opentrace/resty_log_by_lua.lua"; # 在log阶段,向kafak上传reportspan
```
            
- 2. **修改init_by_lua.lua：**
 
   (初始化的操作需要在init_by_lua阶段完成，如果子贫困、服务异常，会自动宣告重启失败,保证服务不受zipkin影响)

```lua
   opentracing = require "libs.opentrace.opentracing"
   -- 初始化zipkin,传参为项目名
   opentracing.init("user")

```

- 3. **apollo相关配置：**
   通过**配置文件**的方式:
   /usr/local/openresty/nginx/conf/zipkin_kafka_host.txt kafka IP地址 例如:127.0.0.1
   /usr/local/openresty/nginx/conf/zipkin_kafka_port.txt kafka 端口 例如:9092

---------------

#### 相关方法介绍(使用)

```lua
   -- 获取全局tracer,相当于一个trace
   local golabaltracer = opentracing.GetGlobalTracer()
   -- 从http头部信息，获取spanContext,作为span的上下文,保存span的base info,可以从一个spanContext获取span或新生成一个child(span)
   local span_context = golabaltracer:Extract(opentracing.HTTP_HEADER_FORMAT, ngx.req.get_headers(), ngx.ctx)
   -- 初始化span的name
   local opereation_name = ngx.var.uri or "zipkin"
   -- 从spanContext获取Span
   local span = golabaltracer:StartSpan(opereation_name, span_context)
   if span then
      -- 将span信息Inject到http头部，方便传输到下一个服务
      golabaltracer:InjextSpanToCtx(ngx.ctx, span)
      -- span设置标签
      span:SetTag("method", ngx.var.request_method)
      span:SetTag("param", ngx.var.request_uri)
      span:SetTag("kind", "http_request")
      -- 获取span的spanContext
      local span_context = span:Context()
      golabaltracer:Inject(span_context)
      -- 将spanContext保存到ngx.ctx全局上下文中
      golabaltracer:InjextSpanContextToCtx(ngx.ctx, span_context)
      -- 新建cs事件
      span:Annotate("cs")
   end

   -- 从ngx.ctx获取span
   local span = golabaltracer:GetSpanFromCtx(ngx.ctx)
```


      