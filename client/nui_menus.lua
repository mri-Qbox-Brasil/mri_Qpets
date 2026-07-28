-- ============================
--    NUI Menu System
-- ============================
-- Handles all menu and input dialogs via React UI

QBCore = exports['qb-core']:GetCoreObject()

-- Helper to open menu
local function openReactMenu(title, items, description)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        data = {
            title = title,
            description = description,
            items = items
        }
    })
end

-- Helper to open input dialog
local function openReactInput(title, fields, callbackEvent, description)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openInput',
        data = {
            title = title,
            description = description,
            fields = fields,
            callbackEvent = callbackEvent
        }
    })
end

-- Register NUI callbacks for menu actions
RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('clickMenuItem', function(data, cb)
    SetNuiFocus(false, false)
    TriggerEvent('keep-companion:client:clickMenuItem', data.id)
    cb('ok')
end)

RegisterNUICallback('closeInput', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Rename Pet
RegisterNUICallback('renamePet', function(data, cb)
    local newName = data.name
    
    if not newName or newName == '' then
        QBCore.Functions.Notify('Nome inválido', 'error', 3000)
        cb({ success = false })
        return
    end
    
    if #newName > 12 then
        QBCore.Functions.Notify('Nome muito longo (máximo 12 caracteres)', 'error', 3000)
        cb({ success = false })
        return
    end
    
    if ActivePed and ActivePed.data then
        for _, petData in pairs(ActivePed.data) do
            if petData.itemData then
                petData.itemData.metadata.name = newName
                TriggerServerEvent('keep-companion:server:updateAllowedmetadata', petData.itemData.metadata, { key = 'name' })
                QBCore.Functions.Notify('Pet renomeado para ' .. newName, 'success', 3000)
                break
            end
        end
    end
    
    cb({ success = true })
end)

-- Collar Color
RegisterNUICallback('setCollarColor', function(data, cb)
    local color = data.color
    
    if ActivePed and ActivePed.data then
        for _, petData in pairs(ActivePed.data) do
            if petData.itemData then
                petData.itemData.metadata.collarColor = color
                TriggerServerEvent('keep-companion:server:updateAllowedmetadata', petData.itemData.metadata, { key = 'collarColor' })
                
                -- Update collar visually
                if petData.collar then
                    SetPedComponentVariation(petData.collar, 0, tonumber(color), 0, 0)
                end
                
                QBCore.Functions.Notify('Cor da coleira atualizada', 'success', 3000)
                break
            end
        end
    end
    
    cb({ success = true })
end)

-- Export functions for use in other scripts
exports('openReactMenu', openReactMenu)
exports('openReactInput', openReactInput)
