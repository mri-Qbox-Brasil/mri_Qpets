local QBCore = exports['qb-core']:GetCoreObject()
local ox_inventory = exports.ox_inventory

Pet = {
    players = {} -- active spawned pets: Pet.players[source][dbId] = petData
}

-- Helper function to round values
local function Round(num, dp)
    local mult = 10 ^ (dp or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- ============================
--          Class Methods
-- ============================

function Pet:isMaxLimitPedReached(source)
    local count = 0
    if not self.players[source] then
        return false
    end
    for _ in pairs(self.players[source]) do
        count = count + 1
    end
    return count >= Config.MaxActivePetsPetPlayer
end

function Pet:setAsSpawned(source, dbId, petData)
    self.players[source] = self.players[source] or {}
    self.players[source][dbId] = petData
    MySQL.update.await('UPDATE player_pets SET active = 1 WHERE id = ?', {dbId})
end

function Pet:setAsDespawned(source, dbId)
    if self.players[source] and self.players[source][dbId] then
        local petData = self.players[source][dbId]
        
        -- Save stats before despawning
        MySQL.update.await('UPDATE player_pets SET active = 0, health = ?, hunger = ?, thirst = ?, happiness = ?, xp = ?, level = ? WHERE id = ?', {
            petData.health,
            petData.hunger,
            petData.thirst,
            petData.happiness,
            petData.xp,
            petData.level,
            dbId
        })
        
        self.players[source][dbId] = nil
    end
end

-- ============================
--          Callbacks
-- ============================

-- Fetch all player's pets
QBCore.Functions.CreateCallback('keep-companion:server:getPets', function(source, cb)
    local citizenid = Framework.GetCitizenId(source)
    if not citizenid then return cb({}) end

    local pets = MySQL.query.await('SELECT * FROM player_pets WHERE citizenid = ?', {citizenid})
    local formattedPets = {}
    
    for _, pet in ipairs(pets) do
        local petConfig = nil
        for _, cfg in pairs(Config.pets) do
            if cfg.model == pet.model then
                petConfig = cfg
                break
            end
        end
        
        local isActive = false
        if Pet.players[source] and Pet.players[source][pet.id] then
            isActive = true
        end

        local ageHours = math.floor(pet.age / 3600)
        local stage = 'Filhote'
        if ageHours >= 4 then
            stage = 'Adulto'
        elseif ageHours >= 1 then
            stage = 'Jovem'
        end

        local maxHealth = petConfig and petConfig.maxHealth or 100
        -- DB stores health as 0-100 percent; expose it as-is so UI shows correct bar
        local currentHealthPct = math.max(0, math.min(100, pet.health or 100))

        table.insert(formattedPets, {
            id = pet.id,
            name = petConfig and petConfig.name or 'petfood',
            model = pet.model,
            maxHealth = 100,
            currentHealth = currentHealthPct,
            distinct = petConfig and petConfig.distinct or 'no dog',
            level = pet.level,
            xp = pet.xp,
            hunger = pet.hunger,
            thirst = pet.thirst,
            happiness = pet.happiness,
            customName = pet.name,
            isActive = isActive,
            stage = stage,
            abilities = {
                canHunt = petConfig and string.find(petConfig.distinct, 'yes') ~= nil or false,
                huntingLevel = pet.level
            }
        })
    end
    
    cb(formattedPets)
end)

-- Spawn Pet
QBCore.Functions.CreateCallback('keep-companion:server:spawnPet', function(source, cb, petId)
    local citizenid = Framework.GetCitizenId(source)
    if not citizenid then return cb(false) end

    local pet = MySQL.single.await('SELECT * FROM player_pets WHERE id = ? AND citizenid = ?', {petId, citizenid})
    if not pet then
        Framework.Notify(source, "Pet não encontrado ou não pertence a você", "error")
        return cb(false)
    end

    -- Despawn any existing pet first to enforce limit
    if Pet.players[source] then
        for dbId, _ in pairs(Pet.players[source]) do
            TriggerClientEvent('keep-companion:client:despawn', source, {metadata = {id = dbId}}, true)
            Pet:setAsDespawned(source, dbId)
        end
    end

    local petConfig = nil
    for _, cfg in pairs(Config.pets) do
        if cfg.model == pet.model then
            petConfig = cfg
            break
        end
    end

    TriggerClientEvent('keep-companion:client:callCompanion', source, pet.model, false, {
        id = pet.id,
        name = petConfig and petConfig.name or pet.model,
        metadata = {
            id = pet.id,
            name = pet.name,
            gender = pet.gender == 'female',
            age = pet.age,
            food = pet.hunger,
            thirst = pet.thirst,
            happiness = pet.happiness,
            level = pet.level,
            XP = pet.xp,
            health = pet.health,
            variation = pet.variation
        }
    })
    cb(true)
end)

-- Despawn Pet
QBCore.Functions.CreateCallback('keep-companion:server:despawnPet', function(source, cb, petId)
    local citizenid = Framework.GetCitizenId(source)
    if not citizenid then return cb(false) end

    if Pet.players[source] and Pet.players[source][petId] then
        TriggerClientEvent('keep-companion:client:despawn', source, {metadata = {id = petId}}, false)
        cb(true)
    else
        cb(false)
    end
end)

-- Dispense Pet (Delete from database)
QBCore.Functions.CreateCallback('keep-companion:server:removePet', function(source, cb, petId)
    local citizenid = Framework.GetCitizenId(source)
    if not citizenid then return cb(false) end

    -- Check ownership
    local pet = MySQL.single.await('SELECT * FROM player_pets WHERE id = ? AND citizenid = ?', {petId, citizenid})
    if not pet then
        Framework.Notify(source, "Pet não encontrado ou não pertence a você", "error")
        return cb(false)
    end

    -- Despawn first if spawned
    if Pet.players[source] and Pet.players[source][petId] then
        TriggerClientEvent('keep-companion:client:despawn', source, {metadata = {id = petId}}, true)
        Pet.players[source][petId] = nil
    end

    -- Delete from Database
    local deleted = MySQL.query.await('DELETE FROM player_pets WHERE id = ?', {petId})
    if deleted then
        Framework.Notify(source, "Você dispensou o seu pet com sucesso.", "success")
        cb(true)
    else
        cb(false)
    end
end)

-- Rename Pet Callback
QBCore.Functions.CreateCallback('keep-companion:server:renamePet', function(source, cb, item)
    local citizenid = Framework.GetCitizenId(source)
    if not citizenid or not item.id or not item.name then return cb(false) end

    -- Validate ownership
    local pet = MySQL.single.await('SELECT * FROM player_pets WHERE id = ? AND citizenid = ?', {item.id, citizenid})
    if not pet then
        Framework.Notify(source, "Você não é o dono deste pet!", "error")
        return cb(false)
    end

    local updated = MySQL.update.await('UPDATE player_pets SET name = ? WHERE id = ?', {item.name, item.id})
    if updated then
        -- Despawn if currently spawned to force visual name updates
        if Pet.players[source] and Pet.players[source][item.id] then
            TriggerClientEvent('keep-companion:client:despawn', source, {metadata = {id = item.id}}, true)
            Pet:setAsDespawned(source, item.id)
        end
        cb(item.name)
    else
        cb(false)
    end
end)

-- Register client tracking feedback
QBCore.Functions.CreateCallback('keep-companion:server:updatePedData', function(source, cb, clientRes)
    local dbId = clientRes.item.metadata.id
    if not dbId then return cb(false) end

    local entity = NetworkGetEntityFromNetworkId(clientRes.netId)
    local petData = {
        id = dbId,
        name = clientRes.item.name,
        model = clientRes.model,
        entity = entity,
        netId = clientRes.netId,
        health = clientRes.item.metadata.health or 100,
        hunger = clientRes.item.metadata.food or 100,
        thirst = clientRes.item.metadata.thirst or 100,
        happiness = clientRes.item.metadata.happiness or 100,
        xp = clientRes.item.metadata.XP or 0,
        level = clientRes.item.metadata.level or 1,
        variation = clientRes.item.metadata.variation or 'dark',
        customName = clientRes.item.metadata.name or clientRes.item.name
    }

    Pet:setAsSpawned(source, dbId, petData)
    cb(true)
end)

-- Update health/XP sent from client
RegisterNetEvent('keep-companion:server:updateAllowedmetadata', function(petMetadata, data, customSrc)
    local src = customSrc or source
    local citizenid = Framework.GetCitizenId(src)
    if not citizenid or not petMetadata.id then return end

    if Pet.players[src] and Pet.players[src][petMetadata.id] then
        local activePet = Pet.players[src][petMetadata.id]
        
        if data.key == 'health' then
            if data.healthPct then
                activePet.health = math.floor(data.healthPct)
                if activePet.health <= 0 then
                    activePet.health = 0
                    if data.netId then
                        local entity = NetworkGetEntityFromNetworkId(data.netId)
                        if entity and DoesEntityExist(entity) then
                            SetEntityHealth(entity, 0)
                        end
                    end
                end
                MySQL.update.await('UPDATE player_pets SET health = ? WHERE id = ?', {activePet.health, petMetadata.id})
                TriggerClientEvent('keep-companion:client:updateNUI', src)
            elseif data.netId then
                local entity = NetworkGetEntityFromNetworkId(data.netId)
                if entity and DoesEntityExist(entity) then
                    local c_health = GetEntityHealth(entity)
                    if c_health <= 100 then
                        activePet.health = 0
                        SetEntityHealth(entity, 0)
                    else
                        -- Convert actual GTA health (100..maxHealth) to 0-100 percent for DB storage
                        local petConfig = nil
                        for _, cfg in pairs(Config.pets) do
                            if cfg.model == activePet.model then petConfig = cfg; break end
                        end
                        local maxHealth = petConfig and petConfig.maxHealth or 200
                        local minHealth = 100
                        local pct = math.min(100, math.max(0, ((c_health - minHealth) / (maxHealth - minHealth)) * 100.0))
                        activePet.health = math.floor(pct)
                    end
                    MySQL.update.await('UPDATE player_pets SET health = ? WHERE id = ?', {activePet.health, petMetadata.id})
                    TriggerClientEvent('keep-companion:client:updateNUI', src)
                end
            end
        elseif data.key == 'XP' then
            -- Handled passively by the server thread
        elseif data.key == 'happiness' then
            activePet.happiness = math.min(100, (activePet.happiness or 100) + 15)
            MySQL.update.await('UPDATE player_pets SET happiness = ? WHERE id = ?', {activePet.happiness, petMetadata.id})
            TriggerClientEvent('keep-companion:client:updateNUI', src)
        elseif data.key == 'name' then
            activePet.customName = petMetadata.name
            MySQL.update.await('UPDATE player_pets SET name = ? WHERE id = ?', {petMetadata.name, petMetadata.id})
            TriggerClientEvent('keep-companion:client:updateNUI', src)
        elseif data.key == 'collarColor' then
            activePet.variation = petMetadata.collarColor
            MySQL.update.await('UPDATE player_pets SET variation = ? WHERE id = ?', {petMetadata.collarColor, petMetadata.id})
            TriggerClientEvent('keep-companion:client:updateNUI', src)
        end
    end
end)

-- Event helper to link updateAllowedInfo triggers (fixing event mismatch)
RegisterNetEvent('keep-companion:server:updateAllowedInfo', function(petItem, data)
    local src = source
    TriggerEvent('keep-companion:server:updateAllowedmetadata', petItem, data, src)
end)

-- Set active pet as despawned when despawn event finishes
RegisterNetEvent('keep-companion:server:setAsDespawned', function(item)
    local src = source
    if not item or not item.metadata or not item.metadata.id then return end
    Pet:setAsDespawned(src, item.metadata.id)
end)

RegisterNetEvent('keep-companion:server:ForceRemoveNetEntity', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)

-- ============================
--        Decay & XP Loops
-- ============================

-- Periodic Status Decay Thread
CreateThread(function()
    while true do
        Wait(Config.StatusDecay.Interval * 1000)
        
        for source, activePets in pairs(Pet.players) do
            local player = Framework.GetPlayer(source)
            if not player then
                -- Player dropped, cleanup
                for dbId, petData in pairs(activePets) do
                    if petData.entity and DoesEntityExist(petData.entity) then
                        DeleteEntity(petData.entity)
                    end
                    MySQL.update.await('UPDATE player_pets SET active = 0 WHERE id = ?', {dbId})
                end
                Pet.players[source] = nil
            else
                for dbId, petData in pairs(activePets) do
                    -- Decay Hunger
                    petData.hunger = math.max(0, (petData.hunger or 100) - Config.StatusDecay.Hunger)
                    
                    -- Decay Thirst (hydration)
                    petData.thirst = math.max(0, (petData.thirst or 100) - Config.StatusDecay.Thirst)
                    
                    -- Decay Happiness
                    petData.happiness = math.max(0, (petData.happiness or 100) - Config.StatusDecay.Happiness)
                    
                    -- Decay Health if starving/dehydrated
                    local healthChanged = false
                    if petData.hunger == 0 then
                        petData.health = math.max(0, (petData.health or 100) - Config.StatusDecay.HealthHungerZero)
                        healthChanged = true
                    end
                    if petData.thirst == 0 then
                        petData.health = math.max(0, (petData.health or 100) - Config.StatusDecay.HealthThirstZero)
                        healthChanged = true
                    end
                    
                    -- Update Entity Health visually on client (client manages the entity)
                    if healthChanged then
                        TriggerClientEvent('keep-companion:client:update_health_value', source, {netId = petData.netId}, petData.health)
                    end
                    
                    -- If health reaches 0, handle fainting on the server
                    if petData.health == 0 and healthChanged then
                        local entity = NetworkGetEntityFromNetworkId(petData.netId)
                        if entity and entity ~= 0 and DoesEntityExist(entity) then
                            SetEntityHealth(entity, 0)
                        end
                        Framework.Notify(source, string.format("Seu pet %s desmaiou de fome ou sede extrema!", petData.customName or petData.model), "error")
                    end

                    -- Save state to DB
                    MySQL.update.await('UPDATE player_pets SET health = ?, hunger = ?, thirst = ?, happiness = ?, age = age + ? WHERE id = ?', {
                        petData.health,
                        petData.hunger,
                        petData.thirst,
                        petData.happiness,
                        Config.StatusDecay.Interval,
                        dbId
                    })
                end
            end
        end
        
        -- Broadcast NUI sync event
        for source, _ in pairs(Pet.players) do
            TriggerClientEvent('keep-companion:client:updateNUI', source)
        end
    end
end)

-- Periodic XP Gain Thread
CreateThread(function()
    while true do
        Wait(Config.XP.Interval * 1000)
        
        for source, activePets in pairs(Pet.players) do
            local player = Framework.GetPlayer(source)
            if player then
                for dbId, petData in pairs(activePets) do
                    local entity = NetworkGetEntityFromNetworkId(petData.netId)
                    if entity and entity ~= 0 and DoesEntityExist(entity) and petData.health > 0 then
                        -- Earn passive XP
                        petData.xp = (petData.xp or 0) + Config.XP.PassiveAmount
                        
                        -- Calculate level up
                        local currentLevel = petData.level or 1
                        local xpNeeded = Config.XP.Formula(currentLevel)
                        
                        if petData.xp >= xpNeeded and currentLevel < Config.XP.MaxLevel then
                            petData.level = currentLevel + 1
                            petData.xp = petData.xp - xpNeeded
                            Framework.Notify(source, string.format("Seu pet %s subiu de nível! Agora é Nível %d", petData.customName or petData.model, petData.level), "success")
                        end
                        
                        -- Save to DB
                        MySQL.update.await('UPDATE player_pets SET xp = ?, level = ? WHERE id = ?', {
                            petData.xp,
                            petData.level,
                            dbId
                        })
                    end
                end
            end
        end
    end
end)

-- ============================
--     Usable Items (ox_inventory)
-- ============================

local function remove_item(src, name, amount)
    return exports.ox_inventory:RemoveItem(src, name, amount)
end

-- Pet Food
QBCore.Functions.CreateUseableItem(Config.core_items.food.item_name, function(source, item)
    local activePetId = nil
    local activePetData = nil
    if Pet.players[source] then
        for dbId, data in pairs(Pet.players[source]) do
            activePetId = dbId
            activePetData = data
            break
        end
    end
    
    if not activePetId then
        Framework.Notify(source, "Você não tem nenhum pet ativo!", "error")
        return
    end

    TriggerClientEvent('keep-companion:client:start_feeding_animation', source)
end)

RegisterNetEvent('keep-companion:server:increaseFood', function(item)
    local source = source
    local activePetId = nil
    local activePetData = nil
    if Pet.players[source] then
        for dbId, data in pairs(Pet.players[source]) do
            activePetId = dbId
            activePetData = data
            break
        end
    end

    if not activePetId then return end

    if not remove_item(source, Config.core_items.food.item_name, 1) then
        Framework.Notify(source, "Falha ao remover ração do seu inventário", "error")
        return
    end

    activePetData.hunger = math.min(100, (activePetData.hunger or 100) + Config.core_items.food.settings.amount)
    activePetData.xp = activePetData.xp + Config.XP.CaredAmount
    
    -- Level up check
    local xpNeeded = Config.XP.Formula(activePetData.level)
    if activePetData.xp >= xpNeeded and activePetData.level < Config.XP.MaxLevel then
        activePetData.level = activePetData.level + 1
        activePetData.xp = activePetData.xp - xpNeeded
        Framework.Notify(source, string.format("Seu pet subiu de nível! Agora é Nível %d", activePetData.level), "success")
    end

    MySQL.update.await('UPDATE player_pets SET hunger = ?, xp = ?, level = ? WHERE id = ?', {
        activePetData.hunger,
        activePetData.xp,
        activePetData.level,
        activePetId
    })

    Framework.Notify(source, "Você alimentou seu pet!", "success")
    TriggerClientEvent('keep-companion:client:updateNUI', source)
end)

-- Pet Water Bottle
QBCore.Functions.CreateUseableItem(Config.core_items.waterbottle.item_name, function(source, item)
    local activePetId = nil
    if Pet.players[source] then
        for dbId, _ in pairs(Pet.players[source]) do
            activePetId = dbId
            break
        end
    end
    
    if not activePetId then
        Framework.Notify(source, "Você não tem nenhum pet ativo!", "error")
        return
    end

    -- Trigger client animation
    TriggerClientEvent('keep-companion:client:filling_animation', source, item)
end)

RegisterNetEvent('keep-companion:server:filling_event', function(item)
    local src = source
    local activePetId = nil
    local activePetData = nil
    if Pet.players[src] then
        for dbId, data in pairs(Pet.players[src]) do
            activePetId = dbId
            activePetData = data
            break
        end
    end

    if not activePetId then return end

    if not remove_item(src, Config.core_items.waterbottle.item_name, 1) then
        Framework.Notify(src, "Garrafa de água vazia ou indisponível", "error")
        return
    end

    local refillValue = Config.core_items.waterbottle.settings.thirst_reduction_per_drinking
    activePetData.thirst = math.min(100, (activePetData.thirst or 100) + refillValue)

    MySQL.update.await('UPDATE player_pets SET thirst = ? WHERE id = ?', {activePetData.thirst, activePetId})
    Framework.Notify(src, "Você deu água para seu pet!", "success")
    TriggerClientEvent('keep-companion:client:updateNUI', src)
end)

-- Rename / Name Tag
QBCore.Functions.CreateUseableItem(Config.core_items.nametag.item_name, function(source, item)
    local activePetId = nil
    if Pet.players[source] then
        for dbId, _ in pairs(Pet.players[source]) do
            activePetId = dbId
            break
        end
    end
    
    if not activePetId then
        Framework.Notify(source, "Você não tem nenhum pet ativo!", "error")
        return
    end

    TriggerClientEvent('keep-companion:client:rename_name_tag', source, {metadata = {id = activePetId}})
end)

RegisterNetEvent('keep-companion:server:rename_name_tag', function(name)
    local src = source
    local activePetId = nil
    if Pet.players[src] then
        for dbId, _ in pairs(Pet.players[src]) do
            activePetId = dbId
            break
        end
    end

    if not activePetId then return end

    if not remove_item(src, Config.core_items.nametag.item_name, 1) then
        Framework.Notify(src, "Você não tem uma etiqueta de nome!", "error")
        return
    end

    TriggerClientEvent("keep-companion:client:rename_name_tagAction", src, name)
end)

-- Pet Revive & First Aid
QBCore.Functions.CreateUseableItem(Config.core_items.firstaid.item_name, function(source, item)
    local activePetId = nil
    if Pet.players[source] then
        for dbId, _ in pairs(Pet.players[source]) do
            activePetId = dbId
            break
        end
    end

    if not activePetId then
        Framework.Notify(source, "Você não tem nenhum pet ativo!", "error")
        return
    end

    TriggerClientEvent('keep-companion:client:useFirstAid', source)
end)

RegisterNetEvent('keep-companion:server:revivePet', function(item, process_type)
    local src = source
    local activePetId = item.itemData.metadata.id
    if not activePetId then return end

    local petData = Pet.players[src][activePetId]
    if not petData then return end

    if not remove_item(src, Config.core_items.firstaid.item_name, 1) then
        Framework.Notify(src, "Sem kit de primeiros socorros!", "error")
        return
    end

    if petData.health <= 0 or process_type == 'revive' then
        petData.health = 100
        MySQL.update.await('UPDATE player_pets SET health = ? WHERE id = ?', {petData.health, activePetId})
        TriggerClientEvent('keep-companion:client:despawn', src, {metadata = {id = activePetId}}, true)
        Pet:setAsDespawned(src, activePetId)
        Framework.Notify(src, "Seu pet foi reanimado e recolhido!", "success")
    else
        petData.health = 100
        MySQL.update.await('UPDATE player_pets SET health = ? WHERE id = ?', {petData.health, activePetId})
        TriggerClientEvent('keep-companion:client:update_health_value', src, {netId = petData.netId}, petData.health)
        Framework.Notify(src, "Pet curado com sucesso!", "success")
    end
end)

-- Register Pet Items as usable items
for _, pet in ipairs(Config.pets) do
    QBCore.Functions.CreateUseableItem(pet.name, function(source, item)
        local citizenid = Framework.GetCitizenId(source)
        if not citizenid then return end

        local petId = item.metadata and item.metadata.id
        if petId then
            -- Item already has an associated pet ID!
            -- Check ownership of this pet in the database
            local dbPet = MySQL.single.await('SELECT * FROM player_pets WHERE id = ? AND citizenid = ?', {petId, citizenid})
            if not dbPet then
                Framework.Notify(source, "Este pet pertence a outro jogador ou não existe!", "error")
                return
            end

            -- Toggle spawn/despawn
            if Pet.players[source] and Pet.players[source][petId] then
                -- Despawn
                TriggerClientEvent('keep-companion:client:despawn', source, {metadata = {id = petId}}, false)
            else
                -- Spawn
                -- Despawn any existing active pet first
                if Pet.players[source] then
                    for dbId, _ in pairs(Pet.players[source]) do
                        TriggerClientEvent('keep-companion:client:despawn', source, {metadata = {id = dbId}}, true)
                        Pet:setAsDespawned(source, dbId)
                    end
                end

                local petConfig = nil
                for _, cfg in pairs(Config.pets) do
                    if cfg.model == dbPet.model then
                        petConfig = cfg
                        break
                    end
                end

                TriggerClientEvent('keep-companion:client:callCompanion', source, dbPet.model, false, {
                    id = dbPet.id,
                    name = petConfig and petConfig.name or dbPet.model,
                    metadata = {
                        id = dbPet.id,
                        name = dbPet.name,
                        gender = dbPet.gender == 'female',
                        age = dbPet.age,
                        food = dbPet.hunger,
                        thirst = dbPet.thirst,
                        happiness = dbPet.happiness,
                        level = dbPet.level,
                        XP = dbPet.xp,
                        health = dbPet.health,
                        variation = dbPet.variation
                    }
                })
                Framework.Notify(source, "Chamando seu pet...", "success")
            end
        else
            -- This is a new pet item! Let's register it in the DB for the player
            local petConfig = nil
            for _, cfg in pairs(Config.pets) do
                if cfg.name == item.name then
                    petConfig = cfg
                    break
                end
            end

            if not petConfig then
                Framework.Notify(source, "Modelo do pet inválido!", "error")
                return
            end

            -- Insert pet into DB with default values
            local id = MySQL.insert.await('INSERT INTO player_pets (citizenid, name, model, gender, variation, age, level, xp, health, hunger, thirst, happiness) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                citizenid,
                petConfig.name:gsub("keepcompanion", ""):gsub("^%l", string.upper),
                petConfig.model,
                'male',
                'dark',
                0,
                1,
                0,
                100,
                100,
                100,
                100
            })

            if id then
                -- Save pet ID to this item's metadata so it is registered
                local newMetadata = item.metadata or {}
                newMetadata.id = id
                newMetadata.name = petConfig.name:gsub("keepcompanion", ""):gsub("^%l", string.upper)
                newMetadata.variation = 'dark'
                
                exports.ox_inventory:SetMetadata(source, item.slot, newMetadata)

                Framework.Notify(source, "Você registrou um novo pet! Personalize-o agora.", "success")
                
                -- Trigger immediate customization process!
                local metadatarmation = {
                    pet_variation_list = PetVariation:getPedVariationsNameList(petConfig.model),
                    pet_metadatarmation = petConfig,
                    disable = { rename = false },
                    type = 'init'
                }
                TriggerClientEvent('keep-companion:client:initialization_process', source, {
                    name = petConfig.name,
                    slot = item.slot,
                    metadata = {
                        id = id,
                        name = newMetadata.name,
                        variation = 'dark'
                    }
                }, metadatarmation)

                TriggerClientEvent('keep-companion:client:updateNUI', source)
            end
        end
    end)
end

function getMaxHealth(model)
    for _, value in pairs(Config.pets) do
        if value.model == model then
            return value.maxHealth
        end
    end
    return 200
end

-- Customization confirms (nui_customization.lua confirms it)
RegisterNetEvent('keep-companion:server:compelete_initialization_process', function(item, process_type)
    local src = source
    local citizenid = Framework.GetCitizenId(src)
    if not citizenid or not item.metadata.id then return end

    MySQL.update.await('UPDATE player_pets SET name = ?, variation = ? WHERE id = ? AND citizenid = ?', {
        item.metadata.name,
        item.metadata.variation,
        item.metadata.id,
        citizenid
    })

    if item.slot and item.slot > 0 then
        exports.ox_inventory:SetMetadata(src, item.slot, item.metadata)
    end

    Framework.Notify(src, "Configurações do pet salvas!", "success")
    TriggerClientEvent('keep-companion:client:updateNUI', src)
end)

-- Pet collar change ownership
QBCore.Functions.CreateCallback('keep-companion:server:collar_change_owenership', function(source, cb, data)
    local player_owner = QBCore.Functions.GetPlayer(source)
    if not player_owner then return cb({state = false, msg = "Dono não encontrado"}) end
    
    local targetSource = tonumber(data.new_owner_cid)
    local player_new_owner = QBCore.Functions.GetPlayer(targetSource)
    
    if not player_new_owner then
        return cb({state = false, msg = "ID do jogador de destino não encontrado"})
    end

    local targetCitizenId = player_new_owner.PlayerData.citizenid
    local petId = data.id or data.hash -- using id directly

    local pet = MySQL.single.await('SELECT * FROM player_pets WHERE id = ? AND citizenid = ?', {petId, player_owner.PlayerData.citizenid})
    if not pet then
        return cb({state = false, msg = "Pet não encontrado ou não pertence a você"})
    end

    if not remove_item(source, 'collarpet', 1) then
        return cb({state = false, msg = "Você não possui uma coleira de pet"})
    end

    -- Despawn if currently spawned
    if Pet.players[source] and Pet.players[source][petId] then
        TriggerClientEvent('keep-companion:client:despawn', source, {metadata = {id = petId}}, true)
        Pet.players[source][petId] = nil
    end

    -- Update Database Owner
    MySQL.update.await('UPDATE player_pets SET citizenid = ?, active = 0 WHERE id = ?', {targetCitizenId, petId})

    cb({state = true, msg = "Transferência de propriedade concluída!"})
end)

-- Clean exit on drop
AddEventHandler('playerDropped', function()
    local src = source
    if Pet.players[src] then
        for dbId, petData in pairs(Pet.players[src]) do
            if petData.entity and DoesEntityExist(petData.entity) then
                DeleteEntity(petData.entity)
            end
            MySQL.update.await('UPDATE player_pets SET active = 0 WHERE id = ?', {dbId})
        end
        Pet.players[src] = nil
    end
end)

RegisterNetEvent('keep-companion:server:onPlayerUnload', function()
    local src = source
    if Pet.players[src] then
        for dbId, petData in pairs(Pet.players[src]) do
            if petData.entity and DoesEntityExist(petData.entity) then
                DeleteEntity(petData.entity)
            end
            Pet:setAsDespawned(src, dbId)
        end
        Pet.players[src] = nil
    end
end)

-- Grooming Kit
QBCore.Functions.CreateUseableItem(Config.core_items.groomingkit.item_name, function(source, item)
    local activePetId = nil
    if Pet.players[source] then
        for dbId, _ in pairs(Pet.players[source]) do
            activePetId = dbId
            break
        end
    end
    
    if not activePetId then
        Framework.Notify(source, "Você não tem nenhum pet ativo!", "error")
        return
    end

    TriggerClientEvent('keep-companion:client:start_grooming_process', source)
end)

RegisterNetEvent('keep-companion:server:grooming_process', function(item)
    local src = source
    local activePetId = nil
    local activePetData = nil
    if Pet.players[src] then
        for dbId, data in pairs(Pet.players[src]) do
            activePetId = dbId
            activePetData = data
            break
        end
    end

    if not activePetId then return end

    local pet_metadatarmation = nil
    for _, cfg in pairs(Config.pets) do
        if cfg.name == activePetData.name then
            pet_metadatarmation = cfg
            break
        end
    end
    if not pet_metadatarmation then return end

    local metadatarmation = {
        pet_variation_list = PetVariation:getPedVariationsNameList(pet_metadatarmation.model),
        pet_metadatarmation = pet_metadatarmation,
        disable = { rename = true },
        type = Config.core_items.groomingkit.item_name
    }

    TriggerClientEvent('keep-companion:client:initialization_process', src, {
        name = activePetData.name,
        slot = 0,
        metadata = {
            id = activePetId,
            name = activePetData.customName,
            variation = activePetData.variation
        }
    }, metadatarmation)
end)

-- ============================
--        K9 Search Functions
-- ============================

local function search_inventory(cid)
    local Player = QBCore.Functions.GetPlayer(cid)
    if not Player then return false end
    local src = Player.PlayerData.source
    
    for _, illegal_item in pairs(Config.k9.illegal_items) do
        local item = exports.ox_inventory:GetItem(src, illegal_item, nil, false)
        if item and item.count > 0 then
            return true
        end
    end
    return false
end

QBCore.Functions.CreateCallback('keep-companion:server:search_inventory', function(source, cb, cid)
    local res = search_inventory(cid)
    cb(res)
end)

local function search_vehicle(Type, plate)
    local illegal_items = Config.k9.illegal_items
    local items_list = nil

    if Type == 1 then
        items_list = exports[Config.inventory_name]:getGloveboxes(plate)
    elseif Type == 2 then
        items_list = exports[Config.inventory_name]:getTruck(plate)
    end

    if items_list then
        for _, item in pairs(items_list.items) do
            for _, i_name in pairs(illegal_items) do
                if item.name == i_name then
                    return true
                end
            end
        end
    end
    return false
end

QBCore.Functions.CreateCallback('keep-companion:server:search_vehicle', function(source, cb, data)
    local res = search_vehicle(data.key, data.plate)
    cb(res)
end)

-- Admin Spawn Command (inserts into DB)
QBCore.Commands.Add('givepet', 'Dá um pet a um jogador (Admin Only)', {{name='id', help='ID do Jogador'}, {name='model', help='Modelo do Pet (e.g. A_C_Westy)'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    local petModel = args[2]
    
    local Player = QBCore.Functions.GetPlayer(targetId)
    if not Player then
        Framework.Notify(source, "Jogador não online", "error")
        return
    end

    local petConfig = nil
    for _, cfg in pairs(Config.pets) do
        if cfg.model == petModel then
            petConfig = cfg
            break
        end
    end

    if not petConfig then
        Framework.Notify(source, "Modelo de pet inválido!", "error")
        return
    end

    local citizenid = Player.PlayerData.citizenid

    local id = MySQL.insert.await('INSERT INTO player_pets (citizenid, name, model, gender, variation, age, level, xp, health, hunger, thirst, happiness) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        citizenid,
        petConfig.name,
        petModel,
        'male',
        'dark',
        0,
        1,
        0,
        100,
        100,
        100,
        100
    })

    if id then
        Framework.Notify(targetId, "Você recebeu um novo pet! Abra o menu para personalizá-lo.", "success")
        TriggerClientEvent('keep-companion:client:updateNUI', targetId)
    end
end, 'admin')

-- Cancel pet initialization (delete DB entry)
RegisterNetEvent('keep-companion:server:cancelPetInitialization', function(petId)
    local src = source
    local citizenid = Framework.GetCitizenId(src)
    if not citizenid or not petId then return end

    MySQL.query.await('DELETE FROM player_pets WHERE id = ? AND citizenid = ?', {petId, citizenid})
    Framework.Notify(src, "Criação do pet cancelada.", "error")
    TriggerClientEvent('keep-companion:client:updateNUI', src)
end)

-- Buy Pet Event (triggered by ox_lib shop)
RegisterNetEvent('mri_Qpets:server:buyPet', function(petIndex)
    local src = source
    local petCfg = Config.pets[petIndex]
    if not petCfg then return end

    local price = petCfg.price or 5000
    local cash = Framework.GetPlayerMoney(src, 'cash')
    local bank = Framework.GetPlayerMoney(src, 'bank')
    local payMethod = nil

    if cash >= price then
        payMethod = 'cash'
    elseif bank >= price then
        payMethod = 'bank'
    end

    if not payMethod then
        Framework.Notify(src, "Você não tem dinheiro suficiente!", "error")
        return
    end

    if Framework.RemovePlayerMoney(src, price, payMethod) then
        local citizenid = Framework.GetCitizenId(src)
        
        -- Insert pet into DB with default values
        local id = MySQL.insert.await('INSERT INTO player_pets (citizenid, name, model, gender, variation, age, level, xp, health, hunger, thirst, happiness) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            citizenid,
            petCfg.name:gsub("keepcompanion", ""):gsub("^%l", string.upper),
            petCfg.model,
            'male',
            'dark',
            0,
            1,
            0,
            100,
            100,
            100,
            100
        })

        if id then
            Framework.Notify(src, string.format("Você comprou um %s por $%d!", petCfg.model, price), "success")
            
            -- Trigger immediate customization process!
            local metadatarmation = {
                pet_variation_list = PetVariation:getPedVariationsNameList(petCfg.model),
                pet_metadatarmation = petCfg,
                disable = { rename = false },
                type = 'init'
            }
            TriggerClientEvent('keep-companion:client:initialization_process', src, {
                name = petCfg.name,
                slot = 0,
                metadata = {
                    id = id,
                    name = petCfg.name:gsub("keepcompanion", ""):gsub("^%l", string.upper),
                    variation = 'dark'
                }
            }, metadatarmation)
        end
    end
end)
