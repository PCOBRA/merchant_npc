local lib = exports.ox_lib
local merchantPed = nil

local function spawnMerchant(coords)
    if merchantPed then DeleteEntity(merchantPed) end
    local model = "g_m_m_chicold_01"
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(500) end
    merchantPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, true, true)
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
end

local function removeMerchant()
    if merchantPed then DeleteEntity(merchantPed) end
end

RegisterNetEvent('merchant:spawnMerchant', function(coords)
    spawnMerchant(coords)
    lib:notify({ title = 'Thương nhân đã xuất hiện!', description = 'Hãy tìm thương nhân để mua hàng. Bạn có 30 phút!', type = 'inform', position = 'center-left', duration = Config.NotifyDuration })
end)

RegisterNetEvent('merchant:removeMerchant', function()
    removeMerchant()
    lib:hideContext('merchant_shop')
    lib:notify({ title = 'Thương nhân đã rời đi!', description = 'Bạn đã bỏ lỡ cơ hội giao dịch.', type = 'error', position = 'center-left', duration = Config.NotifyDuration })
end)

RegisterNetEvent('merchant:openShop', function(items)
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
