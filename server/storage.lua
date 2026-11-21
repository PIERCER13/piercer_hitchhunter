Storage = { incidents = {} }

local FILE = 'data/incidents.json'

function Storage.load()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            Storage.incidents = data
            return
        end
    end
    Storage.incidents = {}
end

function Storage.save()
    while #Storage.incidents > Config.MaxIncidents do
        table.remove(Storage.incidents, 1)
    end
    SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(Storage.incidents), -1)
end

function Storage.clear()
    Storage.incidents = {}
    Storage.save()
end

function Storage.find(id)
    for i = #Storage.incidents, 1, -1 do
        if Storage.incidents[i].id == id then return Storage.incidents[i] end
    end
end
