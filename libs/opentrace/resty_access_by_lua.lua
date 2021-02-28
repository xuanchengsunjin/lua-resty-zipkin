local cjson_safe = require "cjson.safe"

local golabaltracer = opentracing.GetGlobalTracer()
-- ngx.log(ngx.ERR, "header:", cjson_safe.encode(ngx.req.get_headers()), "uri:", ngx.var.uri)
local span_context = golabaltracer:Extract(opentracing.HTTP_HEADER_FORMAT, ngx.req.get_headers(), ngx.ctx)

local opereation_name = ngx.var.uri or "zipkin"
local span = golabaltracer:StartSpan(opereation_name, span_context)
if span then
    golabaltracer:InjextSpanToCtx(ngx.ctx, span)
    span:SetTag("method", ngx.var.request_method)
    span:SetTag("param", ngx.var.request_uri)
    span:SetTag("kind", "http_request")
    local span_context = span:Context()
    golabaltracer:Inject(span_context)
    golabaltracer:InjextSpanContextToCtx(ngx.ctx, span_context)
    -- span:Annotate("cs")
end