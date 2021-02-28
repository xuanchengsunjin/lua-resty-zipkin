local util = require "libs.opentrace.util"
local opentracing = require "libs.opentrace.opentracing"

local print = print

if ngx then
    print = ngx.print
end

opentracing.init()
print("GetGlobalTracer:", opentracing.GetGlobalTracer())

local golabaltracer = opentracing.GetGlobalTracer()
print("get_local_endpoint:",golabaltracer:get_local_endpoint())
print("reporter:",golabaltracer.reporter)

local span_context = golabaltracer:Extract()
print("span_context:", span_context)
print("trace_id:", span_context:GetTraceID())
print("GetID:", span_context:GetID())
print("GetParentID:", span_context:GetParentID())

local span = golabaltracer:StartSpanFrom("span_hhhh", span_context)
print("span:", span)
print("span_traceid:", span.traceId)
print("span_id:", span.id)
print("span_parentId:", span.parentId)
print("span_localEndpoint:", span.localEndpoint)
print("span_timestamp:", span.timestamp)
print("span_tags:", span.tags)
print("span_tracer:", span.tracer)
print("span_name:",span.name)
print("span_duration:",span.duration)

span:Finish()

print("span_duration:",span.duration)