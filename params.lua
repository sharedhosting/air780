local params, chl = {}, config.notify.http.channel

function params.weCom(t, f, n, msg)
    local c = chl.weCom
    if not c then return end
    local txt = t == 'call' and (f..'致电'..n) or (t == 'sms' and (f..'发来短信：'..msg..' 收信：'..n) or msg)
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode({msgtype='text', text={content=txt}})
end

function params.ntfy(t, f, n, msg)
    local c = chl.ntfy
    if not c then return end
    local title = t == 'call' and '📞 来电提醒' or (t == 'sms' and '📩 新短信通知' or '⚙️ 系统通知')
    local body  = t == 'call' and (f..' 致电 '..n) or (t == 'sms' and string.format('发件人: %s\n收件人: %s\n内容:\n%s', f, n, msg) or msg)
    return 'POST', c.url, {Title=title, Priority='high', Tags='warning', ['Content-Type']='text/plain; charset=utf-8'}, body
end

function params.bark(t, f, n, msg)
    local c = chl.bark
    if not c then return end
    local p = t == 'call' and {body=f..' 致电 '..n} or (t == 'sms' and {title=f, body=msg} or {title=n, body=msg})
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode(p)
end

function params.gotify(t, f, n, msg)
    local c = chl.gotify
    if not c then return end
    local title = t == 'call' and '📞 来电提醒' or (t == 'sms' and '📩 新短信通知' or '⚙️ 系统通知')
    local body  = t == 'call' and (f..' 致电 '..n) or (t == 'sms' and string.format('发件人: %s\n收件人: %s\n内容:\n%s', f, n, msg) or msg)
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode({title=title, message=body, priority=5})
end

return params
