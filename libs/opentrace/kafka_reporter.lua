local _M = {}

local client = require "libs.kafka.client"
local producer = require "libs.kafka.producer"

local topic = "zipkin"

function _M.init(kafka_host, kafka_port)
    if not kafka_host then
        return
    end
    _M.kafka_host = kafka_host
    _M.kafka_port = tonumber(kafka_port) or 9092

    _M.broker_list = {
        {
            host = _M.kafka_host, port = _M.kafka_port,
        }
    }
    
    return true
end

function _M.report(span)
    -- 获取序列化好的span
    local str = span:MarshalJSON()
    if not _M.producer then
        local p = producer:new(_M.broker_list, { producer_type = "async" ,batch_num = 200 })
        if not p then
            ngx.log(ngx.ERR, "producer failed")
        else
            _M.producer = p
        end
    end

    -- 异步发送，注意不能同步发送
    if _M.producer then
        _M.producer:send(topic, nil, str)
    end
 
    -- ngx.log(ngx.ERR, "str:", str)
end

return _M