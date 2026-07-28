Framework = {}
QBCore = nil

local function InitFramework()
    if GetResourceState('qbx_core') == 'started' then
        -- Native QBX structure
        QBCore = exports['qb-core']:GetCoreObject() -- QBX compatible CoreObject wrapper
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end

InitFramework()

function Framework.GetPlayer(source)
    if not QBCore then InitFramework() end
    if QBCore then
        return QBCore.Functions.GetPlayer(source)
    end
    return nil
end

function Framework.GetCitizenId(source)
    local player = Framework.GetPlayer(source)
    if player then
        return player.PlayerData.citizenid
    end
    return nil
end

function Framework.GetPlayerMoney(source, type)
    local player = Framework.GetPlayer(source)
    if player then
        return player.PlayerData.money[type] or 0
    end
    return 0
end

function Framework.RemovePlayerMoney(source, amount, type)
    local player = Framework.GetPlayer(source)
    if player then
        if player.Functions.RemoveMoney then
            return player.Functions.RemoveMoney(type, amount, "mri_qpets_purchase")
        end
    end
    return false
end

function Framework.Notify(source, message, type, duration)
    local notifyType = type or 'inform'
    if notifyType == 'primary' then notifyType = 'info' end
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Pets',
        description = message,
        type = notifyType,
        duration = duration or 3000
    })
end
