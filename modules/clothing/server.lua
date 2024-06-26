local clothing = {}

local Inventory

CreateThread(function()
    Inventory = require 'modules.inventory.server'
end)

local slotItems = {
    [1] = "clothes_torsos",
    [2] = "clothes_bags",
    [3] = "clothes_armors",
    [4] = "clothes_pants",
    [5] = "clothes_shoes",
    [6] = "clothes_decals",

    [8] = "clothes_hats",
    [9] = "clothes_masks",
    [10] = "clothes_glasses",
    [11] = "clothes_ears",
    [12] = "clothes_chains",
    [13] = "clothes_watches",
    [14] = "clothes_bracelets",
}

local idToSlot = {
    [1] = 9,
    [4] = 4,
    [5] = 2,
    [6] = 5,
    [7] = 12,
    [9] = 3,
    [10] = 6,
    [13] = 8,
    [14] = 10,
    [15] = 11,
    [16] = 13,
    [17] = 14,
}

function clothing.imageExists(image)
    local path = GetResourcePath(GetCurrentResourceName())

    local name = ("%s/web/images/%s.png"):format(path, image)

    local f = io.open(name, "r")

    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function clothing.getClothesInv(source)
    local license = GetPlayerIdentifierByType(source, 'license')
    license = license and license:gsub('license:', '')
    return Inventory('clothing' .. license, source) --[[@as OxInventory]]
end

RegisterNetEvent('ox_inventory:syncPlayerClothes', function()
    local src = source

    local clothes = clothing.getClothesInv(src)
    if not clothes then return end

    local playerSex, playerTop, playerClothes = lib.callback.await('ox_inventory:getPlayerClothes', source)
    Inventory.Clear(clothes, 'clothes_outfits')

    local top = false

    for i = 1, #playerTop do
        local component = playerTop[i]
        if component then
            top[#top + 1] = {
                type = 'component',
                component = component.component,
                drawable = component.drawable,
                texture = component.texture,
            }
        end
    end

    if top then
        Inventory.AddItem(clothes, "clothes_torsos", 1, top, 1)
    end

    for id, slot in pairs(idToSlot) do
        local cloth = playerClothes[id]

        if cloth and next(cloth) then
            if cloth.type == 'component' then
                cloth.image = ('clothes/%s/%s_%s_%s'):format(playerSex, playerSex, cloth.component, cloth.drawable) ..
                (cloth.texture ~= 0 and ('_%s'):format(cloth.texture) or '')
            else
                cloth.image = ('clothes/%s/%s_prop_%s_%s'):format(playerSex, playerSex, cloth.prop, cloth.drawable) ..
                (cloth.texture ~= 0 and ('_%s'):format(cloth.texture) or '')
            end
            Inventory.AddItem(clothes, slotItems[slot], 1, cloth, slot)
        end
    end

    for i = 1, 16 do
        clothes:syncSlotsWithClients({
            slots = { item = { slot = i } },
            inventory = clothes.id,
        }, true)
    end
end)

---@param source number
lib.callback.register('ox_inventory:getInventoryClothes', function(source)
    local src = source
    local clothes = clothing.getClothesInv(src)

    return clothes and {
        id = clothes.id,
        label = clothes.label,
        type = clothes.type,
        slots = clothes.slots,
        weight = 0,
        maxWeight = 10000,
        items = clothes.items or {}
    } or false
end)

function clothing.addTop(payload)
    return lib.callback.await('ox_inventory:addTop', payload.source, payload.fromSlot.metadata)
end

function clothing.removeTop(payload)
    return lib.callback.await('ox_inventory:removeTop', payload.source, payload.fromSlot.metadata)
end

function clothing.addClothing(payload)
    return lib.callback.await('ox_inventory:addClothing', payload.source, payload.fromSlot.metadata)
end

function clothing.removeClothing(payload)
    return lib.callback.await('ox_inventory:removeClothing', payload.source, payload.fromSlot.metadata)
end

function clothing.addOutfit(payload)
    return true
end

function clothing.removeOutfit(payload)
    return true
end

function clothing.swapOutfit(payload)
    return false
end

return clothing
