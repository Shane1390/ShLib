-- ik this isn't really async don't @ me
function SHLIB:Async(func)
    local thread = coroutine.create(func)

    return function(...)
        self:ResumeThread(thread, ...)
    end
end

function SHLIB:ResumeThread(thread, ...)
    local status, err = coroutine.resume(thread, ...)
    if not status then print("[SHLIB] Error in thread: " .. debug.traceback(thread, err)) end
end

function hook.AddAsync(name, label, func)
    hook.Add(name, label, function(...)
        SHLIB:Async(function(...)
            func(...)
        end)(...)
    end)
end

function timer.SimpleAsync(time, func)
    timer.Simple(time, function()
        SHLIB:Async(function()
            func()
        end)()
    end)
end

function timer.CreateAsync(id, delay, rep, func)
    timer.Create(id, delay, rep, function()
        SHLIB:Async(function()
            func()
        end)()
    end)
end

-- This is only for debugging
function SHLIB:Wait(time)
    local running = coroutine.running()

    timer.Simple(time, function()
        self:ResumeThread(running)
    end)

    coroutine.yield()
end

function SHLIB:HttpGet(url)
    local co = coroutine.running()

    http.Fetch(url,
        function(body)
            self:ResumeThread(co, true, body)
        end,

        function()
            self:ResumeThread(co, false)
        end
    )

    return coroutine.yield()
end