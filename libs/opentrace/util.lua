local TraceId = require "libs.opentrace.trace_id"
local SpanID = require "libs.opentrace.span_id"

local common_util = require "libs.util.common_util"

local _M = {}

local print = print

if ngx then
    print = ngx.print
end

--- 获取us级时间戳
--- @return number
function _M.get_timestamp_now()
    local time = ngx.now()*1000000
    return time
end

--- 生成traceID
--- @return string
function _M.GenerateTraceID()
    local time_now = ngx.now()*1000
    math.randomseed(time_now)
    local hight = tonumber( math.floor(math.random()*100000) .. tostring(time_now)) or 0
    local remote_addr = _M.get_real_ip() or ""
    local str = string.gsub(remote_addr, "%D", "")

    local low = tonumber(tostring(math.floor(math.random()*1000000)) .. (str or "")) or 0 
    return TraceId(hight, low)
end

--- 获取客户端真实IP
function _M.get_real_ip()
    if ngx.var.http_x_forwarded_for then
        return string.match(ngx.var.http_x_forwarded_for..",","[%d%.]+")
    end

    local x_is_ip = ngx.req.get_headers()["X-IS-CLIENT-IP"]
	if x_is_ip then
		return x_is_ip
	end

	return ngx.req.get_headers()["X-Real-IP"] or ngx.var.remote_addr
end

--- 生成SpanID
--- @return string
function _M.GenerateSpanID()
    math.random(ngx.now()*1000)
    local hight = math.floor(math.random()*100000000000)
    -- local low = math.floor(math.random()*100000)
    return SpanID(hight)
end

--- 获取ServiceName
function _M.GeServiceName()
    local s = os.getenv("HOSTNAME") or "wocao"
    return s
end

--- 获取IP ADDRESS
function _M.GetLocalIP()
    return common_util.GetLocalIP()
end

--- 获取Port
function _M.GetPort()
    local s = tonumber(os.getenv("IP_PORT") or 80)
    return s
end

--- 判断TraceID格式
function _M.CheckTraceIDFormat(traceID)
    if traceID and (#traceID == 16 or #traceID == 32) and traceID:match("%x") then
        return true
    end
    return false
end

--- 判断SpanID格式
function _M.CheckSpanIDFormat(spanID)
    if spanID and #spanID == 16 and spanID:match("%x") then
        return true
    end
    return false
end

function _M.print(obj)
    if not obj then
        print(obj)
        return
    end

    if "table" == type(obj) then
        for k,v in ipairs(obj) do
            print(k ..":" .. v)
        end
    else
        print(obj)
    end
end

--- @return trace_id, span_id, parent_id, should_sample
function _M.parse_zipkin_b3_header(headers)
    local should_sample = headers["x-b3-sampled"]
    if should_sample == "1" or should_sample == "true" then
      should_sample = true
    elseif should_sample == "0" or should_sample == "false" then
      should_sample = false
    elseif should_sample ~= nil then
      ngx.log(ngx.ERR, "x-b3-sampled header invalid; ignoring.")
      should_sample = nil
    end

    local debug_header = headers["x-b3-flags"]
    if debug_header == "1" then
        should_sample = true
    elseif debug_header ~= nil then
        ngx.log(ngx.ERR,"x-b3-flags header invalid; ignoring.")
        should_sample = nil
    end

    local trace_id, span_id, sampled, parent_id

    local trace_id_header = headers["x-b3-traceid"]
    if true == _M.CheckTraceIDFormat(trace_id_header) then
       
        local high = tonumber(string.sub(trace_id_header, 1, 16), 16)
        local low = tonumber(string.sub(trace_id_header, 17, 32), 16)
        trace_id = TraceId(high, low)
    end

    local span_id_header = headers["x-b3-spanid"]
    if true == _M.CheckSpanIDFormat(span_id_header) then
        span_id = SpanID(tonumber(span_id_header, 16))
    end

    local parent_id_header = headers["x-b3-parentspanid"]
    if true == _M.CheckTraceIDFormat(parent_id_header) then
        parent_id = SpanID(tonumber(parent_id_header, 16))
    end

    return trace_id, span_id, parent_id, should_sample
end

-- table对象转可以序列化的table
function _M.object_to_table(original)

    if not original then
        return nil
    end

    local original_type = type(original)
    nlog.debug("original_type:" .. tostring(original_type))

    if original_type == "table" and original.String and "function" == type(original.String) then
        return original:String()
    end

    if original_type == "table" then
        local obj = {}
        for k, v in pairs(original) do
            nlog.debug("k:" .. tostring(k))
            if k and v and "__index" ~= k then
                local a = _M.object_to_table(v)
                if a then
                    obj[k] = a
                end
            end
        end
        return obj
    end

    if original_type == "function" then
        return nil
    end

    if "userdata" == original_type then
        return
    end 
    return original
end

return _M