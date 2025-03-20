ESX = exports["es_extended"]:getSharedObject()

-- Dữ liệu shop
local shopInventory = {
    { name = 'weaponrepairkit', label = 'Bộ Sửa Chữa Vũ Khí', price = 5000, limit = 1, stock = 1 },
    { name = 'drill', label = 'Máy Khoan', price = 500, limit = 1, stock = 2 },
    { name = 'WEAPON_BATLV3', label = 'GẬY BÓNG CHÀY 3', price = 50000, limit = 1, stock = 2 },
    { name = 'WEAPON_GOLFCLUBLV3', label = 'GẬY GOLF 3', price = 50000, limit = 1, stock = 2 },
    { name = 'WEAPON_HAMMERLV3', label = 'BÚA 3', price = 50000, limit = 1, stock = 2 },
    { name = 'WEAPON_POOLCUELV3', label = 'CƠ BIDA 3', price = 50000, limit = 1, stock = 2 },
}

local initialStock = {}
for _, item in ipairs(shopInventory) do
    initialStock[item.name] = item.stock
end

local discordWebhook = "https://discord.com/api/webhooks/1352102542665973800/7bpOS4BleNO3lLWjLrV99NNX_EHrgKFyhBkx8nnWlZ-LABL37dyc0X6LmLvkJAirPQgJ"

local function sendToDiscord(title, message, color, playerName)
    PerformHttpRequest(discordWebhook, nil, 'POST', json.encode({
        embeds = {{
            title = title,
            description = message,
            color = color,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = { text = "Merchant NPC Log" },
            author = { name = playerName or "Server" }
        }}
    }), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('merchant:resetStock')
AddEventHandler('merchant:resetStock', function()
    for _, item in ipairs(shopInventory) do
        item.stock = initialStock[item.name]
    end
    sendToDiscord("Kho đã reset", "Kho của Thương nhân đã được reset.", 65535)
end)

RegisterNetEvent('merchant:checkPurchase')
AddEventHandler('merchant:checkPurchase', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if xPlayer.getAccount('black_money').money <= 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lỗi giao dịch', description = 'Bạn không có tiền bẩn!', type = 'error', position = 'center-left' })
        return
    end

    local items = {}
    for _, item in ipairs(shopInventory) do
        if item.stock > 0 then
            items[#items + 1] = { name = item.name, label = item.label, price = item.price, count = item.stock }
        end
    end

    if #items == 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Hết hàng', description = 'Cửa hàng đã hết vật phẩm!', type = 'error', position = 'center-left' })
        return
    end

    TriggerClientEvent('merchant:openShop', src, items)
end)

RegisterNetEvent('merchant:buyItem')
AddEventHandler('merchant:buyItem', function(itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local playerName = xPlayer.getName() or GetPlayerName(src)

    local itemData
    for _, item in ipairs(shopInventory) do
        if item.name == itemName then
            itemData = item
            break
        end
    end
    if not itemData then return end

    if itemData.stock < amount then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lỗi giao dịch', description = 'Không đủ ' .. itemData.label .. ' trong kho!', type = 'error', position = 'center-left' })
        sendToDiscord("Giao dịch thất bại", "Người chơi " .. identifier .. " cố mua " .. amount .. " " .. itemData.label .. " nhưng kho không đủ (Còn: " .. itemData.stock .. ")", 16711680, playerName)
        return
    end

    local totalCost = itemData.price * amount
    local blackMoney = xPlayer.getAccount('black_money').money
    if blackMoney < totalCost then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lỗi giao dịch', description = 'Bạn không đủ tiền bẩn!', type = 'error', position = 'center-left' })
        sendToDiscord("Giao dịch thất bại", "Người chơi " .. identifier .. " không đủ black_money (" .. blackMoney .. "/" .. totalCost .. ") để mua " .. amount .. " " .. itemData.label, 16711680, playerName)
        return
    end

    xPlayer.removeAccountMoney('black_money', totalCost)
    xPlayer.addInventoryItem(itemName, amount)
    itemData.stock = itemData.stock - amount

    TriggerClientEvent('ox_lib:notify', src, { title = 'Thành công', description = 'Bạn đã mua ' .. amount .. ' ' .. itemData.label .. '!', type = 'success', position = 'center-left' })
    sendToDiscord("Giao dịch thành công", "Người chơi " .. identifier .. " đã mua " .. amount .. " " .. itemData.label .. " với " .. totalCost .. " black_money. Kho còn: " .. itemData.stock, 65280, playerName)
end)