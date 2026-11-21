local isOpen = false
local pending, counter = {}, 0

local function setOpen(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close' })
end

RegisterCommand('hitchhunter', function()
    if isOpen then return setOpen(false) end
    TriggerServerEvent('piercer_hitchhunter:open')
end, false)

RegisterNetEvent('piercer_hitchhunter:open', function()
    setOpen(true)
end)

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    cb({})
end)

-- A NUI pede dados; repassamos ao servidor e devolvemos a resposta.
RegisterNUICallback('rpc', function(data, cb)
    counter = counter + 1
    pending[counter] = cb
    TriggerServerEvent('piercer_hitchhunter:rpc', counter, data.path, data.method, data.args)
    SetTimeout(15000, function()
        if pending[counter] == cb then
            pending[counter] = nil
            cb({ __status = 504, error = 'timeout' })
        end
    end)
end)

RegisterNetEvent('piercer_hitchhunter:rpcResult', function(id, body, code)
    local cb = pending[id]
    if not cb then return end
    pending[id] = nil
    if type(body) == 'table' and not body[1] then body.__status = code end
    cb({ __status = code, data = body })
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
