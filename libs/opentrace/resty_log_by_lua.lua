local golabaltracer = opentracing.GetGlobalTracer()

local span = golabaltracer:GetSpanFromCtx(ngx.ctx)
if span then
    span:SetTag("http_status", ngx.var.status)
    span:SetTag("request_time", ngx.var.request_time)
    -- span:Annotate("cs")
    span:Finish()
end