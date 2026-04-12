-- ============================
--    NUI Customization Integration
-- ============================
-- This file handles pet customization using React UI instead of ox_lib menus

QBCore = exports['qb-core']:GetCoreObject()

-- Register callback for customization confirmation
RegisterNUICallback('confirmCustomization', function(data, cb)
    local item = data.item
    local customizationType = data.type
    
    if not item or not item.metadata then
        cb({ success = false })
        return
    end
    
    print('[NUI Customization] Confirming customization:', json.encode({
        type = customizationType,
        name = item.metadata.name,
        variation = item.metadata.variation
    }))
    
    -- Complete initialization or grooming process
    TriggerServerEvent('keep-companion:server:compelete_initialization_process', item, customizationType)
    
    -- Close NUI
    SetNuiFocus(false, false)
    
    cb({ success = true })
end)

-- PRIMARY EVENT HANDLER - Trigger customization UI when player uses pet item
RegisterNetEvent('keep-companion:client:initialization_process', function(item, pet_metadatarmation)
    if type(item) ~= "table" then
        QBCore.Functions.Notify(Lang:t('error.failed_to_start_procces'), 'error', 5000)
        return
    end
    
    print('[NUI Customization] Opening customization for:', item.name, 'Type:', pet_metadatarmation.type)
    
    -- Check if grooming and validate grooming kit
    if pet_metadatarmation.type == 'grooming' then
        local hasitem = QBCore.Functions.HasItem(Config.core_items.groomingkit.item_name)
        if not hasitem then 
            QBCore.Functions.Notify('Você precisa de um kit de limpeza', 'error', 5000) 
            return 
        end
    end
    
    -- Open React NUI customization modal
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'openCustomization',
        data = {
            item = item,
            pet_metadatarmation = pet_metadatarmation.pet_metadatarmation,
            pet_variation_list = pet_metadatarmation.pet_variation_list,
            type = pet_metadatarmation.type
        }
    })
end)

-- Handle NUI close (ESC key or Cancel button) - Delete item since user cancelled
RegisterNUICallback('closeCustomization', function(data, cb)
    print('[NUI Customization] User cancelled customization')
    
    -- FIRST: Close NUI focus immediately
    SetNuiFocus(false, false)
    
    -- THEN: Trigger server to delete the item
    if data.item and data.item.slot then
        print('[NUI Customization] Deleting item from slot:', data.item.slot)
        TriggerServerEvent('keep-companion:server:cancelPetInitialization', data.item.slot)
    end
    
    -- Respond to callback
    cb('ok')
end)



