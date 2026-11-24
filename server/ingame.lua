RegisterNetEvent('piercer_hitchhunter:open', function()
    local src = source
    if Auth.isAllowed(src) then
        TriggerClientEvent('piercer_hitchhunter:open', src)
    else
        Auth.notify(src, 'error', Utils.L('Voce nao tem permissao para usar o hitchhunter.', "You don't have permission to use hitchhunter."))
    end
end)

RegisterNetEvent('piercer_hitchhunter:rpc', function(id, path, method, args)
    local src = source
    if not Auth.isAllowed(src) or type(path) ~= 'string' or type(method) ~= 'string' then
        return TriggerClientEvent('piercer_hitchhunter:rpcResult', src, id, { error = 'unauthorized' }, 401)
    end
    if args ~= nil and type(args) ~= 'table' then args = nil end
    local code, body = Api.handle(path, method, Config.IngameIncidentLimit, args)
    TriggerClientEvent('piercer_hitchhunter:rpcResult', src, id, body, code)
end)
