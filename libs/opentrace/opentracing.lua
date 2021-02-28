local _M = {}

local tracer
local httpReporter
local kafkaReporter

-- 相关常量
_M.HTTP_HEADER_FORMAT = "HTTP_HEADER_FORMAT"
_M.RPC_HEADER_FORMAT = "HTTP_HEADER_FORMAT"

local common_util = require "libs.util.common_util"

function _M.init(serviceName)
    -- 初始化全局Trace
    httpReporter = httpReporter or require "libs.opentrace.http_reporter"
    kafkaReporter = kafkaReporter or require "libs.opentrace.kafka_reporter"
    tracer = tracer or require "libs.opentrace.tracer"

    local ZIPKIN_HOST = common_util.GetEnvFromFile("zipkin_http_host")
    if not ZIPKIN_HOST then
        error("opentracing init failed! ZIPKIN_HOST error:" .. tostring(ZIPKIN_HOST))
    end

    local KAFKA_HOST = common_util.GetEnvFromFile("zipkin_kafka_host")
    if not KAFKA_HOST then
        error("opentracing init failed! KAFKA_HOST error:" .. tostring(KAFKA_HOST))
    end

    local KAFKA_PORT = common_util.GetEnvFromFile("zipkin_kafka_port")
   
    if KAFKA_HOST and kafkaReporter.init(KAFKA_HOST, KAFKA_PORT) then
        _M.Tracer = tracer(kafkaReporter, serviceName)
    elseif ZIPKIN_HOST and httpReporter.init(ZIPKIN_HOST) then
        _M.Tracer = tracer(httpReporter, serviceName)
    else
        error("opentracing init failed! no reporter")
    end
end

--- 根据http头部获取Carrier
function _M.HTTPHeadersCarrier()
    return {}
end

--- 返回全局tracer
function _M.GetGlobalTracer()
    return _M.Tracer
end

--- 设置全局tracer
function _M.SetGlobalTracer(tracer)
    _M.Tracer = tracer
end


return _M