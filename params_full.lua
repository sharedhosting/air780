local params, chl = {}, config.notify.http.channel

-- 企业微信 (weCom)
function params.weCom(t, f, n, msg)
    local c = chl.weCom
    if not c then return end
    local txt = t == 'call' and ('📞 来电提醒\n'..f..' 致电 '..n) or (t == 'sms' and string.format('📩 新短信通知\n发件人: %s\n收件人: %s\n内容:\n%s', f, n, msg) or ('⚙️ 系统通知\n'..msg))
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode({msgtype='text', text={content=txt}})
end

-- 飞书 (feishu)
function params.feishu(t, f, n, msg)
    local c = chl.feishu
    if not c then return end
    local txt = t == 'call' and ('📞 来电提醒\n'..f..' 致电 '..n) or (t == 'sms' and string.format('📩 新短信通知\n发件人: %s\n收件人: %s\n内容:\n%s', f, n, msg) or ('⚙️ 系统通知\n'..msg))
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode({msg_type='text', content={text=txt}})
end

-- Bark
function params.bark(t, f, n, msg)
    local c = chl.bark
    if not c then return end
    local p = t == 'call' and {title='📞 来电提醒', body=f..' 致电 '..n} or (t == 'sms' and {title='📩 '..f, body=msg} or {title='⚙️ 系统通知', body=msg})
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode(p)
end

-- Gotify
function params.gotify(t, f, n, msg)
    local c = chl.gotify
    if not c then return end
    local title = t == 'call' and '📞 来电提醒' or (t == 'sms' and '📩 新短信通知' or '⚙️ 系统通知')
    local body  = t == 'call' and (f..' 致电 '..n) or (t == 'sms' and string.format('发件人: %s\n收件人: %s\n内容:\n%s', f, n, msg) or msg)
    return 'POST', c.url, {['Content-Type']='application/json; charset=utf-8'}, json.encode({title=title, message=body, priority=5})
end

-- Ntfy
function params.ntfy(t, f, n, msg)
    local c = chl.ntfy
    if not c then return end
    local title = t == 'call' and '📞 来电提醒' or (t == 'sms' and '📩 新短信通知' or '⚙️ 系统通知')
    local body  = t == 'call' and (f..' 致电 '..n) or (t == 'sms' and string.format('发件人: %s\n收件人: %s\n内容:\n%s', f, n, msg) or msg)
    return 'POST', c.url, {Title=title, Priority='high', Tags='warning', ['Content-Type']='text/plain; charset=utf-8'}, body
end

-- WxPusher (微信推送)
function params.wxpusher(t, f, n, msg)
    local c = chl.wxpusher
    if not c then return end
    local summary = t == 'call' and ('📞 来电: '..f) or (t == 'sms' and ('📩 短信: '..f) or '⚙️ 系统通知')
    local content = t == 'call' and string.format('**📞 来电提醒**\n- **主叫**: %s\n- **被叫**: %s', f, n) or (t == 'sms' and string.format('**📩 新短信通知**\n- **发件人**: %s\n- **收件人**: %s\n- **内容**:\n%s', f, n, msg) or ('**⚙️ 系统通知**\n\n'..msg))
    return 'POST', 'https://wxpusher.zjiecode.com/api/send/message', {['Content-Type']='application/json; charset=utf-8'}, json.encode({appToken=c.appToken, summary=summary, content=content, contentType=3, uids=c.uids, topicIds=c.topicIds})
end

-- TelegramBot
function params.TelegramBot(t, f, n, msg)
    local c = chl.TelegramBot
    if not c then return end
    local txt = t == 'call' and string.format('📞 <b>来电提醒</b>\n号码: %s\n被叫: %s', f, n) or (t == 'sms' and string.format('📩 <b>新短信</b>\n发件人: %s\n收件人: %s\n内容:\n%s', f, n, msg) or string.format('⚙️ <b>系统通知</b>\n%s', msg))
    return 'POST', 'https://api.telegram.org/bot'..c.token..'/sendMessage', {['Content-Type']='application/json; charset=utf-8'}, json.encode({chat_id=c.id, text=txt, parse_mode='HTML'})
end

return params
