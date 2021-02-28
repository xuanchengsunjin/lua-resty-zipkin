local class = require "libs.classic"
local util = require "libs.opentrace.util"
local cjson_safe = require "cjson.safe"
local opentracing
local Annotations

local _M = class:extend()

--- 构造函数
function _M:new(spanContext, operationName, traceID, id, parentId, localEndpoint, timestamp)
    opentracing = opentracing or require "libs.opentrace.opentracing"
    if not spanContext or not operationName or not traceID or not id then
        return nil
    end
    
    self.spanContext = spanContext
    self.name = operationName -- span name
    self.traceId = traceID 
    self.id = id -- span id
    self.parentId = parentId -- parent span id
    self.localEndpoint = localEndpoint
    self.timestamp = timestamp or util.get_timestamp_now()
    self.tags = {}
    
    self.tracer = opentracing.GetGlobalTracer() -- 设置tracer
end

--- 设置OperationName
function _M:SetOperationName(operationName)
    self.name = operationName
end

--- 设置tag
function _M:SetTag(key, value)
    if not key or not value then
        return
    end
    self.tags[key] = value

    return true
end

--- 记录错误日志(非规范方法)
function _M:RecordErrorLog(str)
    self.tags["_error"] = self.tags["_error"] or table.new(2, 0)
    table.insert(self.tags["_error"], str)
    return true
end

--- 记录fetal日志(非规范方法)
function _M:RecordFetalLog(str)
    self.tags["_fetal"] = self.tags["_fetal"] or table.new(2, 0)
    table.insert(self.tags["_fetal"], str)
    return true
end

--- 记录warn日志(非规范方法)
function _M:RecordWarnLog(str)
    self.tags["_warn"] = self.tags["_warn"] or table.new(2, 0)
    table.insert(self.tags["_warn"], str)
    return true
end

--- event:
--[[  
    cs:Client Send，客户端发起请求；
    sr:Server Receive，服务器接受请求，开始处理；
    ss:Server Send，服务器完成处理，给客户端应答；
    cr:Client Receive，客户端接受应答从服务器；
]]
function _M:Annotate(event, time)
    if not event then
        return
    end
 
    time = time or ngx.now() * 1000000
    local data = table.new(0, 3)
    data.timestamp = time
    data.value = event
    local localEndPoint= self.localEndpoint
    if localEndPoint then
        data.endpoint = {
            serviceName = localEndPoint.serviceName,
            ipv4 = localEndPoint.ipv4,
            port = localEndPoint.port,
        }
    end
    self.annotations = self.annotations or table.new(2, 0)
    table.insert(self.annotations, data)
end

--- span finish
function _M:Finish()
    self.duration = math.floor(util.get_timestamp_now() - self.timestamp) -- span的duration
    -- report the span
    if true == self.spanContext.shouldSample then
        -- 如果为debug模式，则不上传
        return
    end
    self.tracer:report(self)
end

--- @return spanContext
function _M:Context()
    return self.spanContext
end

function _M:SetLocalEndpoint(localEndpoint)
    self.localEndpoint = localEndpoint
end

function _M:LogEvent(event)
    self:Annotate(event)
end

--- 加入binaryAnnotation和Tag,埋点信息(已经废弃)
function _M:AddBinaryAnnotationAndTag(key, value)
    if not key or not value then
        return
    end
    self.tags[key] = value

    local binaryAnnotation = table.new(0, 4)
    binaryAnnotation.key = key
    binaryAnnotation.value = value
    local localEndPoint= self.localEndpoint
    if localEndPoint then
        binaryAnnotation.endpoint = {
            serviceName = localEndPoint.serviceName,
            ipv4 = localEndPoint.ipv4,
            port = localEndPoint.port,
        }
    end
    self:addBinaryAnnotation(binaryAnnotation)
end

--- 加入binaryAnnotation,埋点信息(已经废弃)
function _M:AddBinaryAnnotation(key, value)
    if not key or not value then
        return
    end

    local binaryAnnotation = table.new(0, 4)
    binaryAnnotation.key = key
    binaryAnnotation.value = value
    local localEndPoint= self.localEndpoint
    if localEndPoint then
        binaryAnnotation.endpoint = {
            serviceName = localEndPoint.serviceName,
            ipv4 = localEndPoint.ipv4,
            port = localEndPoint.port,
        }
    end
    self:addBinaryAnnotation(binaryAnnotation)
end

function _M:addBinaryAnnotation(binaryAnnotation)
    if not self.binaryAnnotations then
        self.binaryAnnotations = {}
    end
    table.insert(self.binaryAnnotations, binaryAnnotation)
end

function _M:property()
    local obj = table.new(0, 4)
    obj.name = self.name
    obj.traceId = self.traceId and self.traceId:String() or nil
    obj.id = self.id and self.id:String() or nil
    obj.parentId = self.parentId and self.parentId:String() or nil
    obj.localEndpoint = self.localEndpoint and self.localEndpoint:property() or nil
    obj.timestamp = self.timestamp 
    obj.tags = self.tags
    if obj.tags then
        if obj.tags._error then
            obj.tags._error = cjson.encode(obj.tags._error)
        end

        if obj.tags._fetal then
            obj.tags._fetal = cjson.encode(obj.tags._fetal)
        end

        if obj.tags._warn then
            obj.tags._warn = cjson.encode(obj.tags._warn)
        end
    end
    obj.duration = self.duration
    obj.annotations = self.annotations
    obj.binaryAnnotation = self.binaryAnnotation
    return obj
end

--- @return string
function _M:MarshalJSON()
    -- 去除不需要序列化的字段
    local obj = self:property()

    return cjson_safe.encode({obj})
end

return _M