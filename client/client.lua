local CoreName = exports['qb-core']:GetCoreObject()

local function GetPedActualHealth(percent, maxHealth)
    local minHealth = 100
    if percent <= 0 then return 0 end
    return math.floor(minHealth + (percent / 100.0) * (maxHealth - minHealth))
end

local function GetPedPercentHealth(actualHealth, maxHealth)
    local minHealth = 100
    if actualHealth <= minHealth then return 0 end
    local pct = ((actualHealth - minHealth) / (maxHealth - minHealth)) * 100.0
    return math.min(100.0, math.max(0.0, pct))
end

function isModelK9(model)
    if not model then return false end
    if not Config.k9 or not Config.k9.models then return false end
    local m = string.lower(model)
    for _, k9 in pairs(Config.k9.models) do
        if m == string.lower(k9) then
            return true
        end
    end
    return false
end

-- ============================
--         Pet Class
-- ============================
ActivePed = {
    data = {
        -- model = '',
        -- entity = '',
        -- hostile = '',
        -- lastCoord = '',
        -- variation = '',
        -- health = '',
    },
    onControl = -1
}
-- itemData.name is item's name
-- itemData.metadata.name is pet's name

--- inital pet data
function ActivePed:new(model, hostile, item, ped, netId)
    -- set modelString and canHunt
    local index = (#self.data + 1)
    if self.data[index] == nil then
        self.data[index] = {}
        self.onControl = 1
    else
        self.onControl = self.onControl + 1
    end
    -- move onControll to last spawned pet

    self.data[index]['model'] = model
    self.data[index]['entity'] = ped
    self.data[index]['netId'] = netId
    self.data[index]['hostile'] = hostile
    self.data[index]['itemData'] = item
    self.data[index]['lastCoord'] = GetEntityCoords(ped) -- if we don't have coord we know entity is missing
    self.data[index]['variation'] = item.metadata.variation
    self.data[index]['health'] = item.metadata.health
    self.data[index]['healthPct'] = item.metadata.health or 100

    for key, information in pairs(Config.pets) do
        if information.name == item.name then
            self.data[index]['modelString'] = information.model
            self.data[index]['maxHealth'] = information.maxHealth
            for w in information.distinct:gmatch("%S+") do
                if w == 'yes' then
                    self.data[index]['canHunt'] = true
                elseif w == 'no' then
                    self.data[index]['canHunt'] = false
                end
            end
            return
        end
    end
end

--- return current active pet
function ActivePed:read()
    local index = ActivePed.onControl
    return ActivePed.data[index]
end

--- clean current ped data
function ActivePed:remove(index)
    local entity = self.data[index].entity
    local netId = nil
    if DoesEntityExist(entity) then
        netId = NetworkGetNetworkIdFromEntity(entity)
        if netId and netId ~= 0 then
            exports['ox_target']:removeEntity(netId)
        end
        DeleteEntity(entity)
    end
    if netId and netId ~= 0 then
        TriggerServerEvent('keep-companion:server:ForceRemoveNetEntity', netId)
    end
    self.data[index] = nil
    -- assign onControl to valid value
    if #self.data == 0 then
        self.onControl = -1
        return
    end
    for key, value in pairs(self.data) do
        self.onControl = key
        return
    end
end

function ActivePed:removeAll()
    local tmpHash = {}
    for key, value in pairs(ActivePed:petsList()) do
        local netId = NetworkGetNetworkIdFromEntity(value.pedHandle)
        if netId and netId ~= 0 then
            exports['ox_target']:removeEntity(netId)
        end
        DeletePed(value.pedHandle)
        table.insert(tmpHash, value.itemData)
        local currentItem = {
            id = value.itemData.metadata.id or nil,
            slot = value.itemData.slot or nil
        }

        TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
            key = 'XP',
        })
    end
    TriggerServerEvent('keep-companion:server:onPlayerUnload', tmpHash)
    self.data = {}
    self.onControl = -1
end

function ActivePed:switchControl(to)
    if to > #self.data or to < 1 then
        return
    end
    self.onControl = to
end

function ActivePed:findByHash(hash)
    for key, data in pairs(self.data) do
        if data.itemData.metadata.id == hash then
            return key, data
        end
    end
end

function ActivePed:petsList()
    local tmp = {}
    for key, data in pairs(self.data) do
        table.insert(tmp, {
            key = key,
            name = data.itemData.metadata.name,
            pedHandle = data.entity,
            itemData = {
                metadata = {
                    id = data.itemData.metadata.id
                }
            }
        })
    end
    return tmp
end




RegisterNetEvent('keep-companion:client:callCompanion')
AddEventHandler('keep-companion:client:callCompanion', function(modelName, hostileTowardPlayer, item)
    -- add another layer when player spawn it inside Vehicle
    local model = (tonumber(modelName) ~= nil and tonumber(modelName) or GetHashKey(modelName))
    local plyPed = PlayerPedId()
    local ped = nil
    SetCurrentPedWeapon(plyPed, 0xA2719263, true)
    ClearPedTasks(plyPed)

    whistleAnimation(plyPed, 1500)

    CoreName.Functions.Progressbar("callCompanion", "Chamando...", Config.Settings.callCompanionDuration * 1000,
        false, false, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        }, {}, {}, {}, function()
        ClearPedTasks(plyPed)

        local spawnCoord = getSpawnLocation(plyPed)
        ped = CreateAPed(model, spawnCoord)
        
        -- Ensure network ID is valid and registered
        local netId = NetworkGetNetworkIdFromEntity(ped)
        local timeout = 100
        while (not netId or netId == 0) and timeout > 0 do
            Wait(10)
            netId = NetworkGetNetworkIdFromEntity(ped)
            timeout = timeout - 1
        end

        QBCore.Functions.TriggerCallback('keep-companion:server:updatePedData', function(result)
            if hostileTowardPlayer == true then
                -- if player is not owner of pet it will attack player
                QBCore.Functions.Notify(Lang:t('error.not_owner_of_pet'), 'error', 5000)
            end
            ClearPedTasks(ped)
            TaskFollowTargetedPlayer(ped, plyPed, 3.0, true)
            -- -- add blip to entity

            if Config.Settings.PetMiniMap.showblip ~= nil and Config.Settings.PetMiniMap.showblip == true then
                createBlip({
                    entity = ped,
                    sprite = Config.Settings.PetMiniMap.sprite,
                    colour = Config.Settings.PetMiniMap.colour,
                    text = item.metadata.name,
                    shortRange = false
                })
            end

            -- init ped data inside client
            ActivePed:new(modelName, hostileTowardPlayer, item, ped, netId)
            local index, petData = ActivePed:findByHash(item.metadata.id)

            -- check for variation data
            if petData.itemData.metadata.variation ~= nil then
                PetVariation:setPedVariation(ped, modelName, petData.itemData.metadata.variation)
            end
            SetEntityMaxHealth(ped, petData.maxHealth)
            local initialHealth = GetPedActualHealth(petData.itemData.metadata.health or 100, petData.maxHealth)
            SetEntityHealth(ped, initialHealth)
            local currentHealth = GetEntityHealth(ped)
            if initialHealth <= 100 then
                QBCore.Functions.Notify("Seu pet está desmaiado! Use um Kit de Primeiros Socorros para reanimá-lo.", "error", 5000)
            end

            exports['ox_target']:addEntity(netId, {
                {
                    name = 'pet_petting',
                    icon = "fa-solid fa-hand-holding-heart",
                    label = "Acariciar",
                    canInteract = function(entity) return (IsEntityDead(entity) == false and ActivePed.read() ~= nil) end,
                    onSelect = function()
                        TriggerEvent('keep-companion:client:start_petting_animation')
                    end
                },
                {
                    name = 'pet_follow',
                    icon = "fa-solid fa-walking",
                    label = "Seguir",
                    canInteract = function(entity) return (IsEntityDead(entity) == false and ActivePed.read() ~= nil) end,
                    onSelect = function() TaskFollowTargetedPlayer(ped, PlayerPedId(), 3.0, false) end
                },
                {
                    name = 'pet_stay',
                    icon = "fa-solid fa-hand",
                    label = "Ficar / Parar",
                    canInteract = function(entity) return (IsEntityDead(entity) == false and ActivePed.read() ~= nil) end,
                    onSelect = function() ClearPedTasks(ped) end
                },
                {
                    name = 'pet_feed',
                    icon = "fa-solid fa-utensils",
                    label = "Alimentar",
                    canInteract = function(entity) return (IsEntityDead(entity) == false and ActivePed.read() ~= nil) end,
                    onSelect = function() TriggerEvent('keep-companion:client:start_feeding_animation') end
                },
                {
                    name = 'pet_water',
                    icon = "fa-solid fa-bottle-water",
                    label = "Dar água",
                    canInteract = function(entity) return (IsEntityDead(entity) == false and ActivePed.read() ~= nil) end,
                    onSelect = function() start_drinking_animation() end
                },
                {
                    name = 'pet_go_there',
                    icon = "fa-solid fa-location-arrow",
                    label = "Mandar ao Local",
                    canInteract = function(entity) return (IsEntityDead(entity) == false and ActivePed.read() ~= nil) end,
                    onSelect = function() goThere(ped) end
                },
                {
                    name = 'pet_attack',
                    icon = "fa-solid fa-skull",
                    label = "Atacar Alvo",
                    canInteract = function(entity) 
                        local activePed = ActivePed.read()
                        return (IsEntityDead(entity) == false and activePed ~= nil and activePed.canHunt == true) 
                    end,
                    onSelect = function() attackLogic(alreadyHunting) end
                },
                {
                    name = 'pet_hunt_grab',
                    icon = "fa-solid fa-dog",
                    label = "Caçar e Trazer",
                    canInteract = function(entity) 
                        local activePed = ActivePed.read()
                        return (IsEntityDead(entity) == false and activePed ~= nil and activePed.canHunt == true) 
                    end,
                    onSelect = function() HuntandGrab(PlayerPedId(), ActivePed.read()) end
                },
                {
                    name = 'pet_search_person',
                    icon = "fa-solid fa-magnifying-glass",
                    label = "Revistar Pessoa (K9)",
                    canInteract = function(entity) 
                        if not PlayerJob or not Framework.IsPoliceJob(PlayerJob.name) then return false end
                        local activePed = ActivePed.read()
                        return (IsEntityDead(entity) == false and activePed ~= nil and isModelK9(activePed.model)) 
                    end,
                    onSelect = function() SearchLogic(PlayerPedId(), ActivePed.read()) end
                },
                {
                    name = 'pet_search_car',
                    icon = "fa-solid fa-car-burst",
                    label = "Revistar Veículo (K9)",
                    canInteract = function(entity) 
                        if not PlayerJob or not Framework.IsPoliceJob(PlayerJob.name) then return false end
                        local activePed = ActivePed.read()
                        return (IsEntityDead(entity) == false and activePed ~= nil and isModelK9(activePed.model)) 
                    end,
                    onSelect = function() 
                        local vehicle = CoreName.Functions.GetClosestVehicle()
                        if vehicle ~= 0 then k9SearchVehicle(vehicle, ActivePed.read()) end
                    end
                },
                {
                    name = 'pet_dashboard',
                    icon = "fa-solid fa-star",
                    label = "Menu do Pet",
                    canInteract = function(entity) return (ActivePed.read() ~= nil) end,
                    onSelect = function() ExecuteCommand('petmenu') end
                },
                {
                    name = 'pet_get_in_car',
                    icon = "fa-solid fa-car-side",
                    label = "Colocar no Carro",
                    canInteract = function(entity) return (IsEntityDead(entity) == false and ActivePed.read() ~= nil) end,
                    onSelect = function() getIntoCar() end
                },
                {
                    name = 'pet_heal',
                    icon = "fas fa-first-aid",
                    label = "Curar",
                    canInteract = function(entity) return (IsEntityDead(entity) == false and GetEntityHealth(entity) < GetEntityMaxHealth(entity) and ActivePed.read() ~= nil) end,
                    onSelect = function() request_healing_process(ped, item, 'Heal') end
                },
                {
                    name = 'pet_revive',
                    icon = "fas fa-skull-crossbones",
                    label = "Reanimar",
                    canInteract = function(entity) return (IsEntityDead(entity) == true and ActivePed.read() ~= nil) end,
                    onSelect = function() request_healing_process(ped, item, 'revive') end
                },
                {
                    name = 'pet_despawn',
                    icon = "fa-solid fa-house-user",
                    label = "Guardar Animal",
                    canInteract = function(entity) return (ActivePed.read() ~= nil) end,
                    onSelect = function() TriggerEvent('keep-companion:client:despawn', item) end
                }
            })

            if petData.hostile == true then
                TriggerServerEvent('keep-companion:server:despwan_not_owned_pet', petData.itemData.metadata.id)
                return
            end

            if currentHealth > 100 then
                creatActivePetThread(ped, item)
            end
        end, {
            item = item, model = model, entity = ped, netId = netId
        })
    end)
end)

RegisterNetEvent('keep-companion:client:useFirstAid', function()
    local activePet = ActivePed:read()
    if not activePet then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end
    
    local ped = activePet.entity
    local isDead = IsEntityDead(ped) or GetEntityHealth(ped) <= 100
    local processType = isDead and 'revive' or 'Heal'
    
    request_healing_process(ped, activePet.itemData, processType)
end)

function request_healing_process(ped, item, process_type)
    local hasitem = QBCore.Functions.HasItem(Config.core_items.firstaid.item_name)
    if not hasitem then QBCore.Functions.Notify(Lang:t('error.not_enough_first_aid'), 'error', 5000) return end

    local plyID = PlayerPedId()
    local timeout = Config.core_items.firstaid.settings.duration
    local current_pet = ActivePed.data[ActivePed:findByHash(item.metadata.id)]

    if process_type == 'Heal' then
        timeout = timeout * math.floor(Config.core_items.firstaid.settings.healing_duration_multiplier)
        makeEntityFaceEntity(ped, plyID) -- pet face owner
        TaskPause(ped, 5000)
    else
        timeout = timeout * math.floor(Config.core_items.firstaid.settings.revive_duration_multiplier)
    end
    makeEntityFaceEntity(plyID, ped) -- owner face pet

    Animator(plyID, "PLAYER", 'revive', {
        animation = 'tendtodead',
        sequentialTimings = {
            [1] = timeout,
            [2] = 0,
            [3] = 0,
            step = 1,
            Timeout = timeout
        }
    })
    -- firstaidforpet
    CoreName.Functions.Progressbar("reviveing", "Reanimando...",
        timeout * 1000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }, {}, {}, {}, function()
        TriggerServerEvent('keep-companion:server:revivePet', current_pet, process_type)
        TaskFollowTargetedPlayer(ped, plyID, false)
    end)
end

RegisterNetEvent('keep-companion:client:update_health_value', function(item, amount)
    -- Resolve entity from netId (server handles are not valid client-side)
    local entity = nil
    if item.netId then
        entity = NetworkGetEntityFromNetworkId(item.netId)
    elseif item.entity then
        entity = item.entity
    end
    if not entity or not DoesEntityExist(entity) then return end

    local maxHealth = GetEntityMaxHealth(entity)
    -- amount is a 0-100 percentage from the server; convert to actual GTA V health range
    local actualHealth = GetPedActualHealth(amount, maxHealth)
    SetEntityHealth(entity, actualHealth)

    -- Update client cache so the thread is in sync
    if ActivePed and ActivePed.data then
        for _, savedData in pairs(ActivePed.data) do
            if savedData.entity == entity then
                savedData.healthPct = amount
                break
            end
        end
    end
end)


--- when the player is AFK for a certain time pet will wander around
---@param timeOut table
---@param afk number
local function afkWandering(timeOut, afk, plyPed, ped)
    local coord = GetEntityCoords(plyPed)
    if IsPedStopped(plyPed) and IsPedInAnyVehicle(plyPed) == false then
        if timeOut[1] < afk.afkTimerRestAfter then
            timeOut[1] = timeOut[1] + 1
            -- code here
            if timeOut[1] == afk.wanderingInterval then
                if timeOut.lastAction == nil or (timeOut.lastAction ~= nil and timeOut.lastAction == 'animation') then
                    ClearPedTasks(ped) -- clear last animation
                    TaskWanderInArea(ped, coord, 4.0, 2, 8.0)
                    timeOut.lastAction = 'wandering'
                end
            end
            if timeOut[1] == afk.animationInterval then
                ClearPedTasks(ped) -- clear TaskWanderInArea
                Animator(ped, ActivePed:read().model, 'siting')
                timeOut.lastAction = 'animation'
            end
        else
            timeOut[1] = 0 --
        end
    else
        timeOut[1] = 0
    end
end

--- this set of Functions will executed evetry sec to tracker pet's behaviour.
---@param ped any
function creatActivePetThread(ped, item)
    local afk = Config.Balance.afk
    local count = Config.DataUpdateInterval -- this value is
    local plyPed = PlayerPedId()
    CreateThread(function()
        local tmpcount = 0
        local savedData = ActivePed.data[ActivePed:findByHash(item.metadata.id)]
        local fninished = false
        -- it's table just to have passed by reference.
        local timeOut = {
            0,
            lastAction = nil
        }
        while DoesEntityExist(ped) and fninished == false do
            afkWandering(timeOut, afk, plyPed, ped)

            -- update every 10 sec
            if tmpcount >= count then
                local activeped = savedData
                local currentItem = {
                    id = activeped.itemData.metadata.id,
                    slot = activeped.itemData.slot
                }

                TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                    key = 'XP',
                })

                tmpcount = 0
            end
            tmpcount = tmpcount + 1

            -- update health
            local currentHealth = GetEntityHealth(savedData.entity)
            local currentPct = GetPedPercentHealth(currentHealth, savedData.maxHealth)
            if not IsEntityDead(savedData.entity) and currentHealth > 100 and savedData.healthPct ~= currentPct then
                -- ped is still alive, sync to server
                TriggerServerEvent('keep-companion:server:updateAllowedInfo', {
                    id = savedData.itemData.metadata.id,
                    slot = savedData.itemData.slot
                }, {
                    key = 'health',
                    netId = NetworkGetNetworkIdFromEntity(ped),
                    healthPct = currentPct
                })
                savedData.healthPct = currentPct
            end
            -- pet is dead
            if IsEntityDead(savedData.entity) or currentHealth <= 100 then
                TriggerServerEvent('keep-companion:server:updateAllowedInfo', {
                    id = savedData.itemData.metadata.id,
                    slot = savedData.itemData.slot
                }, {
                    key = 'health',
                    netId = NetworkGetNetworkIdFromEntity(ped),
                    healthPct = 0
                })
                fninished = true
            end
            Wait(1000)
        end
    end)
end

RegisterNetEvent('keep-companion:client:forceKill', function(hash, reason)
    local index, petData = ActivePed:findByHash(hash)
    local c_health = GetEntityHealth(petData.entity)
    if c_health < 100 then
        return
    end
    petData.health = 0
    SetEntityHealth(petData.entity, 0)
    local msg = Lang:t('error.your_pet_died_by')
    msg = string.format(msg, reason)
    QBCore.Functions.Notify(msg, 'error', 5000)
end)

RegisterNetEvent('keep-companion:client:despawn')
AddEventHandler('keep-companion:client:despawn', function(item, revive)
    if revive ~= nil and revive == true then
        -- revive skip animation
        local index, pedData = ActivePed:findByHash(item.metadata.id)
        ActivePed:remove(index)
        TriggerServerEvent('keep-companion:server:setAsDespawned', item)
        return
    end
    local plyPed = PlayerPedId()

    SetCurrentPedWeapon(plyPed, 0xA2719263, true)
    ClearPedTasks(plyPed)
    whistleAnimation(plyPed, 1500)

    CoreName.Functions.Progressbar("despawn", "Retornando...", Config.Settings.despawnDuration * 1000, false, false, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false
    }, {}, {}, {}, function()
        ClearPedTasks(plyPed)
        Citizen.CreateThread(function()
            local index, pedData = ActivePed:findByHash(item.metadata.id)
            ActivePed:remove(index)
            TriggerServerEvent('keep-companion:server:setAsDespawned', item)
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ActivePed:removeAll()
    PlayerData = {} -- empty playerData
end)

-- =========================================
--          Commands Client Events
-- =========================================

RegisterNetEvent('keep-companion:client:start_feeding_animation', function()
    local current_pet = ActivePed:read()

    if current_pet == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    local c_health = GetEntityHealth(current_pet.entity)
    if c_health <= 100 then
        QBCore.Functions.Notify(Lang:t('error.your_pet_is_dead'), 'error', 5000)
        return
    end

    local hasitem = QBCore.Functions.HasItem(Config.core_items.food.item_name)
    if not hasitem then
        QBCore.Functions.Notify("Você não tem ração de pet!", 'error', 5000)
        return
    end

    CoreName.Functions.Progressbar("feeding", "Alimentando...", Config.core_items.food.settings.duration * 1000, false, false,
        {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        }, {}, {}, {}, function()
        TriggerServerEvent('keep-companion:server:increaseFood', current_pet.itemData)
    end)
end)

RegisterNetEvent('keep-companion:client:start_petting_animation', function()
    local current_pet = ActivePed:read()
    if current_pet == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    local c_health = GetEntityHealth(current_pet.entity)
    if c_health <= 100 then
        QBCore.Functions.Notify(Lang:t('error.your_pet_is_dead'), 'error', 5000)
        return
    end

    local plyPed = PlayerPedId()
    local entity = current_pet.entity
    local modelName = current_pet.model

    makeEntityFaceEntity(plyPed, entity)
    makeEntityFaceEntity(entity, plyPed)
    local coords = GetEntityCoords(plyPed)
    local forward = GetEntityForwardVector(plyPed)
    local x, y, z = table.unpack(coords + forward * 1.0)
    SetEntityCoords(entity, x, y, z, 0, 0, 0, 0)
    TaskPause(entity, 5000)
    Animator(entity, modelName, 'tricks', { animation = 'petting_chop' })
    Animator(plyPed, 'A_C_Rottweiler', 'tricks', { animation = 'petting_franklin' })
    TriggerServerEvent('hud:server:RelieveStress', Config.Balance.petting_stress_relief)
    -- Sync happiness boost to server
    TriggerServerEvent('keep-companion:server:updateAllowedInfo', {
        id = current_pet.itemData.metadata.id,
        slot = current_pet.itemData.slot
    }, { key = 'happiness' })
end)

function start_drinking_animation()
    local current_pet = ActivePed:read()

    if current_pet == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    local c_health = GetEntityHealth(current_pet.entity)
    if c_health <= 100 then
        QBCore.Functions.Notify(Lang:t('error.your_pet_is_dead'), 'error', 5000)
        return
    end

    local hasitem = QBCore.Functions.HasItem(Config.core_items.waterbottle.item_name)
    if not hasitem then
        QBCore.Functions.Notify("Você não tem água de pet!", 'error', 5000)
        return
    end

    CoreName.Functions.Progressbar("pet_drinking", "Dando água...", Config.core_items.waterbottle.settings.duration * 1000,
        false, false, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        }, {}, {}, {}, function()
        -- Use the correct server event that actually increases thirst
        TriggerServerEvent('keep-companion:server:filling_event', current_pet.itemData)
    end)
end

RegisterNetEvent('keep-companion:client:filling_animation', function(item)
    CoreName.Functions.Progressbar("filling_animation", "Enchendo garrafa...",
        Config.core_items.waterbottle.settings.duration * 1000, false, false, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        }, {}, {}, {}, function()
        TriggerServerEvent('keep-companion:server:filling_event', item)
    end)
end)

RegisterNetEvent('keep-companion:client:rename_name_tag', function(item)
    if ActivePed:read() == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    local name = exports['qb-input']:ShowInput({
        header = "rename: " .. ActivePed:read().itemData.metadata.name,
        submitText = "rename",
        inputs = { {
            type = 'text',
            isRequired = true,
            name = 'pet_name',
            text = "enter pet name"
        } }
    })
    if name then
        if not name.pet_name then
            return
        end
        TriggerServerEvent('keep-companion:server:rename_name_tag', name.pet_name)
    end
end)



RegisterNetEvent('keep-companion:client:rename_name_tagAction', function(name)
    -- process of updating pet's name
    local activePed = ActivePed:read() or nil
    local validation = ValidatePetName(name, 12)

    if activePed == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    if activePed.itemData.metadata.id == nil or type(name) ~= "string" then
        QBCore.Functions.Notify(Lang:t('error.failed_to_start_procces'), 'error', 5000)
        return
    end

    if type(validation) == "table" and next(validation) ~= nil then
        QBCore.Functions.Notify(Lang:t('error.failed_to_validate_name'), 'error', 5000)
        if validation.reason == 'badword' then
            QBCore.Functions.Notify(Lang:t('error.badword_inside_pet_name'), 'error', 5000)
            print_table(validation.words)
            return
        elseif validation.reason == 'maxCharacter' then
            QBCore.Functions.Notify(Lang:t('error.more_than_one_word_as_name'), 'error', 5000)
            return
        end
        return
    end

    CoreName.Functions.Progressbar("waitingForName", "Aprendendo nome...",
        Config.core_items.nametag.settings.duration * 1000, false, false, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true
        }, {}, {}, {}, function()
        QBCore.Functions.TriggerCallback('keep-companion:server:renamePet', function(result)
            if type(result) == "string" then
                QBCore.Functions.Notify(Lang:t('success.pet_rename_was_successful') .. result, 'success', 5000)
            end
        end, {
            id = activePed.itemData.metadata.id or nil,
            hash = activePed.itemData.metadata.id or nil,
            slot = activePed.itemData.slot or nil,
            name = name
        })
    end)
end)

RegisterNetEvent('keep-companion:client:collar_process', function()
    -- process of updating pet's owernship
    local activePed = ActivePed:read() or nil

    if activePed == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    if activePed.itemData.metadata.id == nil then
        QBCore.Functions.Notify(Lang:t('error.failed_to_find_pet'), 'error', 5000)
        return
    end

    local inputData = exports['qb-input']:ShowInput({
        header = "New owner id: ",
        submitText = "Confirm",
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'cid',
                text = "new owner id"
            },
        }
    })
    if inputData then
        if not inputData.cid then
            return
        end
        CoreName.Functions.Progressbar("waitingForOwenership", "Recohecendo novo dono...",
            Config.core_items.collar.settings.duration * 1000, false, false, {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true
            }, {}, {}, {},
            function()
                local c_pet = ActivePed:read()
                if c_pet == nil then
                    QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
                    return
                end
                QBCore.Functions.TriggerCallback('keep-companion:server:collar_change_owenership', function(result)
                    if result.state == false then
                        QBCore.Functions.Notify(result.msg, 'error', 5000)
                        return
                    end
                    QBCore.Functions.Notify(result.msg, 'success', 5000)
                end, {
                    new_owner_cid = inputData.cid,
                    id = ActivePed:read().itemData.metadata.id,
                    hash = ActivePed:read().itemData.metadata.id,
                })
            end
        )
    end
end)
