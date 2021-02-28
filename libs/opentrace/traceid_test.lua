local trace_id = require "libs.opentrace.trace_id"
local ffi = require 

local print = print

if ngx then
    print = ngx.print
end


-- local traceID = trace_id(92525356897233366,53453263535363334635)
-- print("trace_id:", traceID:String())