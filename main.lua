local mt = {}
local proxy_mt = {}

function mt.__index(t, key)
    return t.__data[key]
end

function mt.__newindex(t, key, value)
    local old = t.__data[key]
    t.__data[key] = value
    -- notify clone obj
    if old then
        for _,p in ipairs(t.__proxy_objs) do
            p[key] = old
        end
    end
end

function mt.__pairs(t)
    return next, t.__data, nil
end

local weak_table = {__mode = "v"}
local function leader_init(origin_table)
    local self = {}
    rawset(self, "__data", origin_table)
    rawset(self, "__proxy_objs", setmetatable({}, weak_table))
    setmetatable(self, mt)
    return self
end

function proxy_mt.__index(t, key)
    return t.__data[key] or self.__ref[key]
end

function proxy_mt.__newindex(t, key, value)
    if not t.__data[key] then
        t.__data[key] = value
    end
end

local function mynext(proxy_obj, index)
    local k, v = next(proxy_obj.__ref, index)
    return k, proxy_obj.__data[k] or v
end

function proxy_mt.__pairs(t)
    return mynext, t, nil
end

local function slave_init(origin_table)
    local self = {}
    rawset(self, "__ref", origin_table)
    rawset(self, "__data", {})
    setmetatable(self, proxy_mt)
    return self
end

local function leader_append_proxy(leader, proxy)
    local proxy_objs = rawget(leader, "__proxy_objs")
    table.insert(proxy_objs, proxy)
end

function mt:remove_proxy(proxy)
    for i, p in ipairs(self.__proxy_objs) do
        if p == proxy then
            table.remove(self.__proxy_objs, i)
            break
        end
    end
end

local function proxy(origin_table)
    -- create proxy_leader to replace origin table
    local leader = leader_init(origin_table)
    -- create proxy_slave for reference
    local slave = slave_init(origin_table)
    leader_append_proxy(leader, slave)
    return leader, slave
end

local function print_table(t)
    for k, v in pairs(t) do
        print(k, v)
    end
end

local function test()
    local a = {b = 1, c = 2}
    local a_proxy, a_slave = proxy(a)
    print("before =============================")
    print("a_proxy:")
    print_table(a_proxy)
    print("a_slave:")
    print_table(a_slave)
    a_proxy.b = 3
    print("after one assign =============================")
    print("a_proxy:")
    print_table(a_proxy)
    print("a_slave:")
    print_table(a_slave)
    print("after second assign =============================")
    a_proxy.b = 4
    print("a_proxy:")
    print_table(a_proxy)
    print("a_slave:")
    print_table(a_slave)
    print("after assign to slave =============================")
    a_slave.b = 8
    print("a_proxy:")
    print_table(a_proxy)
    print("a_slave:")
    print_table(a_slave)

end

test()
