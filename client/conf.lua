function lovr.conf(t)
    -- t.headset.drivers = {"desktop", "vrapi", "oculus"}
    t.headset.drivers = {"desktop"}
    t.window.title = "real shit"
    t.modules.headset = true

    t.graphics.debug = true

    t.window.msaa = 8
    t.headset.supersample = true
    t.headset.msaa = 8
    return t
end
