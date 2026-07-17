return {
    network = {
        dns  = { '180.184.2.2', '223.5.5.5' },
        IPv6 = 0
    },
    -- 新增定时任务配置
    task = {
        keep_alive = {
            enable  = 1,             -- 1: 开启，0: 关闭
            number  = '13800000000', -- 接收保活短信的目标手机号
            days    = 15,            -- 循环发送间隔（天）
            content = '设备保活短信：系统运行正常' -- 短信内容
        }
    },
    
    notify = {
        http = {
            options = {
                timeout = 8,
                retry   = 10
            },
            channel = {
                wxpusher = { enable = 1, url = 'https://wxpusher.zjiecode.com/api/send/message', appToken = 'AT_xxxxxxxxxxxxxxxx', uids = {'UID_xxxxxxxxxxxxxxxx'} },
                ntfy   = { enable = 1, url = 'https://ntfy.sh/xxxxx' },
                bark   = { enable = 1, url = 'https://api.day.app/xxxxxxxx' },
                gotify = { enable = 1, url = 'http://natde1.net/message?token=xxxxxxx' }
            }
        }
    },
    call = {
        accept = { L = 0, M = 1 }, -- L:座机, M:手机
        reply  = {
            sms = {
                enable  = 1,
                content = '%s，很抱歉无法及时处理您的来电，您可短信给我留言，我会尽快与您联系。这是一条自动回复短信'
            }
        }
    },
    sim = {
        -- 按需保留实际使用的 ICCID 映射即可
        ['89860115840501500001'] = { num = '13900000001' }
    },
    system = {
        power = { notify = 1, usb = 1, reboot = 8 },
        led   = {
            network = { gpio = 27 },
            event   = { gpio = 27, total = 5, wait = 60 }
        },
        ctrl  = { '000' } -- 允许控制的号码名单，'000' 代表禁止任何号码控制
    }
}
