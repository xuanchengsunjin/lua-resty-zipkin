local class = require "libs.classic"
local util = require "libs.opentrace.util"
local cjson_safe = require "cjson.safe"

local endpoint
local SpanContext
local Span 
local opentracing

local _M = class:extend()

local SPAN_CTX_KEY = "span_ctx"
local SPAN_CONTEXT_CTX_KEY = "span_context_ctx"

function _M:new(reporter, serviceName)
    endpoint = endpoint or require "libs.opentrace.endpoint"
    SpanContext = SpanContext or require "libs.opentrace.span_context"
    Span = Span or require "libs.opentrace.span"
    opentracing = opentracing or require "libs.opentrace.opentracing"
    self.reporter = reporter
    self.localEndPoint = endpoint:new(serviceName or util.GeServiceName(), util.GetLocalIP(), util.GetPort())
end

function _M:Inject(span_context)
    local trace_id = span_context:GetTraceID()
    local span_id = span_context:GetID()
    -- ngx.header["x-b3-traceid"] = trace_id:String()
    -- ngx.header["x-b3-spanid"] =  span_id:String()
    ngx.req.set_header("x-b3-traceid", trace_id:String())
    ngx.req.set_header("x-b3-spanid", span_id:String())
    ngx.req.set_header("trace_id", trace_id:String())
    if true == span_context.shouldSample then
        -- ngx.header["x-b3-sampled"] = "1" 
        ngx.req.set_header("v", "1")
    end
    local parent_span_id = span_context:GetParentID()
    if parent_span_id then
        ngx.req.set_header("x-b3-parentspanid", parent_span_id:String())
        -- ngx.header["x-b3-parentspanid"] = parent_span_id:String()
    end
end

--- @return SpanContext
function _M:Extract(format, headers, ctx)
    ctx = ctx or ngx.ctx

    if ctx[SPAN_CONTEXT_CTX_KEY] then
        return ctx[SPAN_CONTEXT_CTX_KEY]
    end

    local span_context

    local trace_id,span_id,parentId,shouldSimple
    if format == opentracing.HTTP_HEADER_FORMAT and headers and "table" == type(headers) then
       -- 处理HTTP header注入的....
    --    ngx.log(ngx.ERR,"headers:", cjson_safe.encode(headers))
       -- 解析http 头部    
       trace_id,span_id,parentId,shouldSimple = util.parse_zipkin_b3_header(headers)
       if trace_id and span_id then
          span_context = SpanContext(trace_id, span_id, parentId, shouldSimple)
          ctx[SPAN_CONTEXT_CTX_KEY] = span_context
        --   self:Inject(span_context)
          return span_context
       else
        --   ngx.log(ngx.ERR, "trace_id_parse_error .. ")
      end
    end
    trace_id = util.GenerateTraceID()
    span_context = SpanContext(trace_id)
    ctx[SPAN_CONTEXT_CTX_KEY] = span_context
    -- 注入到http header
    -- self:Inject(span_context)
    return span_context
end

--- 从spanContext生成span(父子关系)
--- @return Span
function _M:StartSpan(operationName, spanContext)
    if not operationName then
        return
    end

    local id = util.GenerateSpanID()
    local parent_span_id = spanContext:GetID() or nil
    local trace_id = spanContext:GetTraceID() or util.GenerateTraceID()
    local shouldSample = spanContext:GetShouldSample()
    local new_span_contect = SpanContext(trace_id, id, parent_span_id, shouldSample)
    local span = Span(new_span_contect, operationName, new_span_contect:GetTraceID(), new_span_contect:GetID(), new_span_contect:GetParentID(), self:get_local_endpoint(), util.get_timestamp_now())
    return span
end

--- 从spanContext生成span(兄弟关系)
--- @return Span
function _M:StartSpanFrom(operationName, spanContext)
    if not operationName then
        return
    end

    local id = util.GenerateSpanID()
    local parent_span_id = spanContext:GetParentID() or nil
    local trace_id = spanContext:GetTraceID() or util.GenerateTraceID()
    local shouldSample = spanContext:GetShouldSample()
    local new_span_contect = SpanContext(trace_id, id, parent_span_id, shouldSample)
    local span = Span(new_span_contect, operationName, new_span_contect:GetTraceID(), new_span_contect:GetID(), new_span_contect:GetParentID(), self:get_local_endpoint(), util.get_timestamp_now())
    return span
end

--- @return Span
function _M:StartSpanFromSpan(operationName, span)
    if not operationName or not span then
        return
    end
    
    local spanContext = span:Context()
    if not spanContext then
        return
    end
    
    local span = Span(spanContext, operationName, spanContext:GetTraceID(), util.GenerateSpanID(), spanContext:GetID(), self:get_local_endpoint(), util.get_timestamp_now())
    return span
end


function _M:InjextSpanToCtx(ctx, span)
    ctx = ctx or ngx.ctx
    ctx[SPAN_CTX_KEY] = span
end


function _M:InjextSpanContextToCtx(ctx, span_context)
    ctx = ctx or ngx.ctx
    ctx[SPAN_CONTEXT_CTX_KEY] = span_context
end

--- @return SpanContext
function _M:GetSpanContextFromCtx(ctx)
    ctx = ctx or ngx.ctx
    return ctx[SPAN_CONTEXT_CTX_KEY]
end

--- @return Span
function _M:GetSpanFromCtx(ctx)
    ctx = ctx or ngx.ctx
    return ctx[SPAN_CTX_KEY]
end

function _M:report(span)
    self.reporter.report(span)
end

function _M:get_local_endpoint()
    return self.localEndPoint
end

return _M