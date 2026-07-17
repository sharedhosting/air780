local model = {}

function model.temp()
    adc.open(adc.CH_CPU)
    local v = adc.get(adc.CH_CPU)
    adc.close(adc.CH_CPU)
    return v and string.format('%.2f', v / 1000) or '0'
end

function model.vbat()
    adc.open(adc.CH_VBAT)
    local v = adc.get(adc.CH_VBAT)
    adc.close(adc.CH_VBAT)
    return v and string.format('%.2f', v / 1000) or '0'
end

-- 直接映射底层的 C/Lua 函数句柄，省去外层闭包开销
model.os, model.bsp, model.hw = rtos.firmware, hmeta.model, hmeta.hwver
model.chip, model.build = hmeta.chip, rtos.buildDate
model.sn, model.imei = mobile.sn, mobile.imei

return model
