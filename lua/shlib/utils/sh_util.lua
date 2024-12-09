-- ik this isn't really async don't @ me
function SHLIB:Async(func)
    return coroutine.wrap(func)
end

-- This is only for debugging
function SHLIB:Wait(time)
    local running = coroutine.running()

    timer.Simple(time, function()
        coroutine.resume(running)
    end)

    coroutine.yield()
end

function SHLIB:HttpGet(url)
    local co = coroutine.running()

    http.Fetch(url,
        function(body)
            coroutine.resume(co, true, body)
        end,

        function()
            coroutine.resume(co, false)
        end
    )

    return coroutine.yield()
end