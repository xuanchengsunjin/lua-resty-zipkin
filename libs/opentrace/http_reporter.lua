local _M = {}

function _M.init(http_host)
    if not http_host then
        return
    end
    _M.zipkin_http_host = http_host
    return true
end

function _M.report(span)
    -- 获取序列化好的span
    local str = span:MarshalJSON()
    -- ngx.log(ngx.ERR, "str:", str)
end

return _M