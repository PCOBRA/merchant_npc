local lib = exports.ox_lib
local merchantPed = nil
local merchantCoords = {
    -----vi tri random------
}

local function spawnMerchant()
    if merchantPed then
        DeleteEntity(merchantPed)
        merchantPed = nil
    end
    
    local coords = merchantCoords[math.random(#merchantCoords)]
    local model = "g_m_m_chicold_01"
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end
    
    merchantPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityInvincible(merchantPed, true)
    SetBlockingOfNonTemporaryEvents(merchantPed, true)
    FreezeEntityPosition(merchantPed, true)
    
    exports.ox_target:addLocalEntity(merchantPed, {
        {
            name = 'merchant_npc',
            icon = 'fa-solid fa-store',
            label = 'Mua hàng',
            onSelect = function()
                TriggerServerEvent('merchant:checkPurchase')
            end
        }
    })
    
    TriggerServerEvent('merchant:resetStock')
    lib:notify({ title = 'Thương nhân đã xuất hiện!', description = 'Hãy tìm thương nhân để mua hàng. Bạn có 10 phút để tìm ra anh ấy!', type = 'inform', position = 'center-left', duration = 15000 })
    
    Wait(600000) -- 10 phút (600 giây = 600000 ms)
    
    if merchantPed then
        DeleteEntity(merchantPed)
        merchantPed = nil
        lib:hideContext('merchant_shop')
        exports.ox_inventory:closeInventory()
        lib:notify({ title = 'Thương nhân đã rời đi!', description = 'Bạn đã bỏ lỡ cơ hội giao dịch.', type = 'error', position = 'center-left', duration = 15000 })
    end
end

CreateThread(function()
    while true do
        Wait(7200000) -- 120 phút (7200 giây = 7200000 ms)
        spawnMerchant()
    end
end)

RegisterNetEvent('merchant:openShop')
AddEventHandler('merchant:openShop', function(items)
    local options = {}
    for _, item in ipairs(items) do
        options[#options + 1] = {
            title = item.label .. ' - $' .. item.price,
            description = 'Còn lại: ' .. item.count,
            icon = 'fa-solid fa-shopping-bag',
            onSelect = function()
                TriggerServerEvent('merchant:buyItem', item.name, 1)
            end
        }
    end

    lib:registerContext({ id = 'merchant_shop', title = 'Thương nhân chợ đen', options = options })
    lib:showContext('merchant_shop')
end)