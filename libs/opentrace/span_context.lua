local class = require "libs.classic"

local _M = class:extend()

--- 构造函数
function _M:new(traceID, id, parentId, shouldSample)
    self.traceID = traceID 
    self.id = id -- span id
    self.parentId = parentId -- parent span id
    self.shouldSample = shouldSample
end

--- @return string
function _M:GetTraceID()
    return self.traceID
end

--- @return string
function _M:GetID()
    return self.id
end

--- @return string
function _M:GetParentID()
    return self.parentId
end

function _M:GetShouldSample()
    return self.shouldSample or false
end

return _M