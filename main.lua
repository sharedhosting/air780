PROJECT = 'Air780_SMS'
VERSION = '0.5.55'

log.setLevel(2)
log.style(1)

_G.sys     = require 'sys'
_G.sysplus = require 'sysplus'
_G.config  = require 'config'
_G.led     = require 'led'

local model     = require 'model'
local sim       = require 'sim'
local params    = require 'params'
local subscribe = require 'subscribe'

if wdt then
    wdt.init(9000)
    sys.timerLoopStart(wdt.feed, 3000)
end

if errDump then errDump.config(false) end

pm.force(pm.NONE)
pm.power(pm.GPS, false)
pm.power(pm.GPS_ANT, false)
pm.power(pm.CAMERA, false)

mobile.config(mobile.CONF_STATICCONFIG, 1)
mobile.config(mobile.CONF_QUALITYFIRST, 2)
mobile.ipv6(config.network.IPv6 == 1)
mobile.syncTime(false)
mobile.setAuto(10000, 30000, 5)

local statusMap = {
    sim = { RDY='已经就绪', NORDY='状态异常', SIM_PIN='需要验证', GET_NUMBER='获取号码' },
    cc  = { READY='功能就绪', PLAY='有人致电', INCOMINGCALL='正在振铃', ANSWER_CALL_DONE='电话接通', DISCONNECTED='对方挂断', HANGUP_CALL_DONE='主动挂断' }
}

local network = { onl = false, dis = 0 }

function isMobile(num)
    return num and #num == 11 and num:match('^1[3-9]')
end

sys.subscribe('ip_reset', function(...)
    if not network.onl then return end
    network = { onl = false, dis = network.dis + 1 }
    mobile.reset()
    log.info('IP网络', '重置', ..., json.encode(network))
end)

sys.subscribe('ip_wait', function()
    sys.taskInit(function()
        local res = sys.waitUntil('IP_READY', 60000)
        if not res then
            network.onl = true
            sys.publish('ip_reset', '超时未联网')
        end
    end)
end)

sys.subscribe('IP_LOSE', function() sys.publish('ip_reset', '断网') end)

sys.subscribe('SIM_IND', function(s, v)
    if s == 'RDY' then sys.publish('ip_wait') end
    log.info('SIM卡', statusMap.sim[s] or '未知', s, v)
end)

local http_opt = config.notify.http.options
sys.subscribe('http_notify', function(method, url, headers, body, n)
    if n > http_opt.retry then return end
    sys.taskInit(function()
        local _, _, _, ipv6 = socket.localIP()
        local code, _, res = http.request(method, url, headers, body, {
            timeout = http_opt.timeout * 1000,
            ipv6    = (ipv6 ~= nil)
        }).wait()

        if code == 200 then
            log.info('HTTP', code, res)
        else
            sys.wait(3000)
            sys.publish('http_notify', method, url, headers, body, n + 1)
        end
    end)
end)

local ctrl, http_chl = {}, {}
for _, v in ipairs(config.system.ctrl) do ctrl[v] = true end
for k, v in pairs(config.notify.http.channel) do
    if v.enable == 1 then table.insert(http_chl, k) end
end

sys.subscribe('sms_build_call', function(from)
    local cfg = config.call.reply.sms
    if cfg.enable == 1 and isMobile(from) then
        sys.publish('sms_send', from, string.format(cfg.content, from))
    end
end)

-- 短信指令控制（已修复：支持任意分隔符，零 Table 垃圾回收）
sys.subscribe('sms_build_sms', function(from, content)
    if #config.system.ctrl < 1 or ctrl[from] then
        -- 匹配规则：以 SMS/sms 开头，兼容 ##、#、逗号、空格、冒号等任意分隔符
        local cmd, target, rTxt = content:match('^(%a+)[%s#,:]+(%d+)[%s#,:]+(.+)$')
        if cmd and cmd:lower() == 'sms' and target and rTxt then
            sys.publish('sms_send', target, rTxt)
        end
    end
end)

local userAgent = http_opt.ua or string.format('Mozilla/5.0 (%s; %s; %s; %s) %s', model.os(), model.bsp(), model.chip(), model.hw(), model.build())

sys.subscribe('notify_build', function(type, from, content)
    sys.publish('sms_build_' .. type, from, content)
    if #http_chl < 1 then return end

    sys.taskInit(function()
        local num = (type == 'msg') and model.bsp() or sim.num()
        for _, value in ipairs(http_chl) do
            local fn = params[value]
            if fn then
                local method, url, headers, body = fn(type, from, num, content)
                if method and headers then
                    headers['User-Agent'] = userAgent
                    sys.publish('http_notify', method, url, headers, body, 1)
                end
            end
        end
    end)
end)

sys.subscribe('IP_READY', function(...)
    if not network.onl then
        network.onl = true
        for i, ns in ipairs(config.network.dns) do socket.setDNS(nil, i, ns) end
    end

    if config.system.power.notify ~= 1 then return end
    config.system.power.notify = 0

    local content = string.format(
        "%s设备开机通知\r\n温度 %s\r\n电压 %s\r\nIMEI %s\r\n手机号 %s\r\n网络 %s\r\nPLMN %s\r\nIMSI %s\r\nICCID %s\r\n信号 %s dBm",
        model.bsp(), model.temp(), model.vbat(), model.imei(), sim.num(), sim.com(), sim.plmn(), mobile.imsi(), mobile.iccid(), mobile.rsrp()
    )
    sys.publish('notify_build', 'msg', '', content)
end)

sys.subscribe('SMS_INC', function(from, txt)
    sys.publish('notify_build', 'sms', from, txt)
end)

local call = { incoming = false, count = 0 }
sys.subscribe('CC_IND', function(status)
    local cfg  = config.call.accept
    local from = cc.lastNum()

    if status == 'READY' then cc.init(0)
    elseif status == 'ANSWER_CALL_DONE' then cc.hangUp()
    elseif status == 'DISCONNECTED' or status == 'HANGUP_CALL_DONE' then call = { incoming = false, count = 0 }
    elseif status == 'INCOMINGCALL' then
        if not call.incoming then sys.publish('notify_build', 'call', from, '') end
        call.incoming = true
        call.count = call.count + 1
        if call.count == 3 and ((isMobile(from) and cfg.M == 1) or cfg.L == 1) then
            cc.accept()
        end
    end
end)

sys.timerLoopStart(sys.publish, 30000, 'memory_clean')

local power = config.system.power
if power.reboot > 0 then sys.timerStart(pm.reboot, 3600000 * power.reboot) end
if power.usb ~= 1 then sys.timerStart(pm.power, 120000, pm.USB, false) end

-- 定时保活短信任务（基于 fskv 跨重启持久化累计小时）
local ka = config.task and config.task.keep_alive
if ka and ka.enable == 1 and isMobile(ka.number) then
    sys.taskInit(function()
        fskv.init()
        sys.waitUntil('IP_READY') -- 确保 SIM 卡与网络就绪

        -- 每 1 小时计数一次（3600000 ms）
        sys.timerLoopStart(function()
            local target_hours = ka.days * 24
            local run_hours = (fskv.get('ka_hours') or 0) + 1

            if run_hours >= target_hours then
                log.info('保活任务', '达到设定天数，发送保活短信', ka.number)
                sys.publish('sms_send', ka.number, ka.content)
                fskv.set('ka_hours', 0)
            else
                fskv.set('ka_hours', run_hours)
            end
        end, 3600000)
    end)
end

sys.run()
