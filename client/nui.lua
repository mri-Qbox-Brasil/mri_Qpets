local nuiOpen = false

QBCore = exports['qb-core']:GetCoreObject()

-- Open NUI Menu when a pet item is used
RegisterNetEvent('keep-companion:client:usePetItem', function(itemName)
    ExecuteCommand('petmenu')
end)

RegisterCommand('petmenu', function()
    if nuiOpen then return end
    
    QBCore.Functions.TriggerCallback('keep-companion:server:getPets', function(pets)
        nuiOpen = true
        SetNuiFocus(true, true)
        
        local PlayerData = QBCore.Functions.GetPlayerData()
        local jobName = PlayerData and PlayerData.job and PlayerData.job.name or 'unemployed'
        
        local shopPets = {}
        for i, pet in ipairs(Config.pets) do
            local nameStr = pet.name:gsub("keepcompanion", ""):gsub("^%l", string.upper)
            table.insert(shopPets, {
                index = i,
                name = pet.name,
                model = pet.model,
                price = pet.price or 5000,
                displayName = nameStr,
                distinct = pet.distinct
            })
        end
        
        SendNUIMessage({
            action = 'setVisible',
            data = true
        })
        
        SendNUIMessage({
            action = 'setPets',
            data = pets
        })
        
        SendNUIMessage({
            action = 'setPlayerJob',
            data = jobName
        })
        
        SendNUIMessage({
            action = 'setShopPets',
            data = shopPets
        })
    end)
end, false)

-- NUI Callbacks
RegisterNUICallback('hideFrame', function(data, cb)
    nuiOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'setVisible',
        data = false
    })
    
    cb('ok')
end)

RegisterNUICallback('getPets', function(data, cb)
    QBCore.Functions.TriggerCallback('keep-companion:server:getPets', function(pets)
        cb(pets)
    end)
end)

-- Spawn Pet
RegisterNUICallback('spawnPet', function(data, cb)
    local petId = data.petId
    QBCore.Functions.TriggerCallback('keep-companion:server:spawnPet', function(success)
        cb({ success = success })
    end, petId)
end)

-- Despawn Pet
RegisterNUICallback('despawnPet', function(data, cb)
    local petId = data.petId
    QBCore.Functions.TriggerCallback('keep-companion:server:despawnPet', function(success)
        cb({ success = success })
    end, petId)
end)

-- Remove/Dispense Pet
RegisterNUICallback('removePet', function(data, cb)
    local petId = data.petId
    QBCore.Functions.TriggerCallback('keep-companion:server:removePet', function(success)
        cb({ success = success })
    end, petId)
end)

-- Pet Action (Feed, water, pet, heal)
RegisterNUICallback('petAction', function(data, cb)
    local petId = data.petId
    local action = data.action
    
    if action == 'feed' then
        TriggerEvent('keep-companion:client:start_feeding_animation')
        cb({ success = true })
    elseif action == 'water' then
        start_drinking_animation()
        cb({ success = true })
    elseif action == 'pet' then
        TriggerEvent('keep-companion:client:start_petting_animation')
        cb({ success = true })
    elseif action == 'heal' then
        if ActivePed and ActivePed.data then
            for _, petData in pairs(ActivePed.data) do
                if petData.itemData and petData.itemData.metadata.id == petId then
                    TriggerServerEvent('keep-companion:server:revivePet', {
                        itemData = petData.itemData,
                        model = petData.model
                    }, 'Heal')
                    break
                end
            end
        end
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

-- Buy Pet from NUI Shop
RegisterNUICallback('buyPet', function(data, cb)
    TriggerServerEvent('mri_Qpets:server:buyPet', data.index)
    cb({ success = true })
end)

-- Update NUI when pet stats change
RegisterNetEvent('keep-companion:client:updateNUI', function()
    if nuiOpen then
        QBCore.Functions.TriggerCallback('keep-companion:server:getPets', function(pets)
            SendNUIMessage({
                action = 'setPets',
                data = pets
            })
        end)
    end
end)
