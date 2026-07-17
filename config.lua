return {
    network = {
        dns  = { '180.184.2.2', '223.5.5.5' },
        IPv6 = 0
    },
    notify = {
        http = {
            options = {
                timeout = 8,
                retry   = 10
            },
            channel = {
                weCom  = { enable = 1, url = 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=cc591cd2-927d-4932-a01b-36a562710041' },
                ntfy   = { enable = 1, url = 'https://ntfy.sh/uUHWKD9-217-218' },
                bark   = { enable = 1, url = 'https://api.day.app/ADDMksvUGGBPc8znT66Ht6' },
                gotify = { enable = 1, url = 'http://natde1.net/message?token=AsfsgUIaZNIwDxwQ' }
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
