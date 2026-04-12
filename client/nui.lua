-- ============================
--          NUI Integration
-- ============================

local nuiOpen = false

QBCore = exports['qb-core']:GetCoreObject()


-- Get all player pets
local function getPlayerPets()
    local pets = {}
    local inventory = exports.ox_inventory:GetPlayerItems()
    
    if not inventory then return pets end
    
    for slot, item in pairs(inventory) do
        -- Check if item is a pet
        for key, petConfig in pairs(Config.pets) do
            if item.name == petConfig.name and item.metadata and item.metadata.hash then
                -- Check if this pet is currently active
                local isActive = false
                if ActivePed and ActivePed.data then
                    for _, activePetData in pairs(ActivePed.data) do
                        if activePetData.itemData and activePetData.itemData.metadata.hash == item.metadata.hash then
                            isActive = true
                            break
                        end
                    end
                end
                
                local formattedPet = {
                    id = slot,
                    name = item.name,
                    model = petConfig.model,
                    maxHealth = petConfig.maxHealth or 200,
                    currentHealth = item.metadata.health or 100,
                    distinct = petConfig.distinct or 'no dog',
                    level = item.metadata.level or 1,
                    xp = item.metadata.xp or 0,
                    hunger = item.metadata.food or 100,
                    thirst = item.metadata.thirst or 0,
                    happiness = item.metadata.happiness or 100,
                    customName = item.metadata.name,
                    collarColor = item.metadata.collarColor,
                    isActive = isActive,
                    abilities = {
                        canHunt = item.metadata.canHunt or false,
                        huntingLevel = item.metadata.huntingLevel or 0
                    }
                }
                
                table.insert(pets, formattedPet)
            end
        end
    end
    
    return pets
end

-- Open NUI Menu
RegisterCommand('petmenu', function()
    if nuiOpen then return end
    
    local pets = getPlayerPets()
    
    nuiOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'setVisible',
        data = true
    })
    
    SendNUIMessage({
        action = 'setPets',
        data = pets
    })
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
    local pets = getPlayerPets()
    cb(pets)
end)

RegisterNUICallback('petAction', function(data, cb)
    local petId = data.petId
    local action = data.action
    
    -- Get pet from inventory by slot (petId)
    local inventory = exports.ox_inventory:GetPlayerItems()
    local petItem = nil
    
    for slot, item in pairs(inventory) do
        if slot == petId then
            petItem = item
            break
        end
    end
    
    if not petItem then
        cb({ success = false })
        return
    end
    
    -- Perform action based on type
    if action == 'feed' then
        TriggerServerEvent('keep-companion:server:increaseFood', petItem)
        cb({ success = true })
    elseif action == 'water' then
        QBCore.Functions.TriggerCallback('keep-companion:server:decrease_thirst', function(success)
            cb({ success = success or false })
        end, petItem)
    elseif action == 'pet' then
        -- Increase happiness
        if petItem.metadata then
            petItem.metadata.happiness = math.min(100, (petItem.metadata.happiness or 100) + 15)
            TriggerServerEvent('keep-companion:server:updateAllowedmetadata', petItem.metadata, { key = 'happiness' })
        end
        cb({ success = true })
    elseif action == 'heal' then
        local petData = Pet:findbyhash(GetPlayerServerId(PlayerId()), petItem.metadata.hash)
        if petData then
            TriggerServerEvent('keep-companion:server:revivePet', {
                itemData = petItem,
                model = petData.model
            }, 'Heal')
        end
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('removePet', function(data, cb)
    local petId = data.petId
    
    -- Get pet from inventory by slot
    local inventory = exports.ox_inventory:GetPlayerItems()
    local petItem = nil
    
    for slot, item in pairs(inventory) do
        if slot == petId then
            petItem = item
            break
        end
    end
    
    if not petItem or not petItem.metadata or not petItem.metadata.hash then
        cb({ success = false })
        return
    end
    
    -- Despawn pet
    Pet:despawnPet(GetPlayerServerId(PlayerId()), petItem, false)
    cb({ success = true })
end)

-- Update NUI when pet stats change
RegisterNetEvent('keep-companion:client:updateNUI', function()
    if nuiOpen then
        local pets = getPlayerPets()
        SendNUIMessage({
            action = 'setPets',
            data = pets
        })
    end
end)
