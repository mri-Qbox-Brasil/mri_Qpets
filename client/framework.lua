Framework = {}
QBCore = nil

local function InitFramework()
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end

InitFramework()

function Framework.GetPlayerData()
    if not QBCore then InitFramework() end
    if QBCore then
        return QBCore.Functions.GetPlayerData()
    end
    return nil
end

function Framework.GetPlayerJob()
    local playerData = Framework.GetPlayerData()
    if playerData then
        return playerData.job
    end
    return nil
end

function Framework.Notify(message, type, duration)
    local notifyType = type or 'inform'
    if notifyType == 'primary' then notifyType = 'info' end
    if lib then
        lib.notify({
            title = 'Pets',
            description = message,
            type = notifyType,
            duration = duration or 3000
        })
    elseif QBCore then
        QBCore.Functions.Notify(message, type or 'primary', duration or 3000)
    else
        TriggerEvent('chat:addMessage', { args = { 'PETS', message } })
    end
end

-- Global player data synchronization
PlayerData = nil
PlayerJob = nil

CreateThread(function()
    while not QBCore do 
        Wait(100) 
    end
    local data = QBCore.Functions.GetPlayerData()
    while not data or not data.job do
        Wait(500)
        data = QBCore.Functions.GetPlayerData()
    end
    PlayerData = data
    PlayerJob = data.job
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local data = QBCore.Functions.GetPlayerData()
    PlayerData = data
    PlayerJob = data.job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

function Framework.IsPoliceJob(jobName)
    if not jobName then return false end
    local j = string.lower(jobName)
    return j == 'police' or j == 'policia' or j == 'sheriff' or j == 'lspd' or j == 'sasp' or j == 'bcso' or j == 'statepolice'
end
