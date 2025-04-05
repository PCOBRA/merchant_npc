ESX = exports["es_extended"]:getSharedObject()

local initialStock = {}
for _, item in ipairs(Config.ShopInventory) do initialStock[item.name] = item.stock end

local lastUsedCoord = nil

local function shuffleTable(t)
    local n = #t
    for i = n, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function sendToDiscord(title, message, color)
    PerformHttpRequest(Config.DiscordWebhook, nil, 'POST', json.encode({
        embeds = {{ title = title, description = message, color = color, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"), footer = { text = "Merchant NPC Log" } }}
    }), { ['Content-Type'] = 'application/json' })
end

local function spawnMerchant()
    local availableCoords = { table.unpack(Config.MerchantCoords) }
    if lastUsedCoord and #availableCoords > 1 then
        for i, coord in ipairs(availableCoords) do
            if coord.x == lastUsedCoord.x and coord.y == lastUsedCoord.y and coord.z == lastUsedCoord.z then
                table.remove(availableCoords, i)
                break
            end
        end
    end
    local shuffledCoords = shuffleTable(availableCoords)
    local coords = shuffledCoords[1]
    lastUsedCoord = coords
    
    sendToDiscord("Thương nhân xuất hiện", "Vị trí: (" .. coords.x .. ", " .. coords.y .. ", " .. coords.z .. ")\nThời gian: " .. os.date("%H:%M:%S", os.time()), 65280)
    
    TriggerClientEvent('merchant:spawnMerchant', -1, coords)
    TriggerEvent('merchant:resetStock')
    Wait(Config.MerchantDuration * 1000)
    TriggerClientEvent('merchant:removeMerchant', -1)
end

CreateThread(function()
    while true do
        local currentTime = os.date("*t", os.time())
        for _, time in ipairs(Config.MerchantSpawnTimes) do
            if currentTime.hour == time.hour and currentTime.min == time.min and currentTime.sec <= 5 then
                spawnMerchant()
                Wait(60 * 1000)
                break
            end
        end
        Wait(1000)
    end
end)

RegisterNetEvent('merchant:resetStock', function()
    for _, item in ipairs(Config.ShopInventory) do item.stock = 0 end
    local tempInventory = { table.unpack(Config.ShopInventory) }
    for i = 1, 2 do
        if #tempInventory > 0 then
            local randomIndex = math.random(#tempInventory)
            local selectedItem = table.remove(tempInventory, randomIndex)
            selectedItem.stock = initialStock[selectedItem.name]
        end
    end
end)

RegisterNetEvent('merchant:checkPurchase', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local items = {}
    for _, item in ipairs(Config.ShopInventory) do
        if item.stock > 0 then items[#items + 1] = { name = item.name, label = item.label, price = item.price, count = item.stock } end
    end
    if #items == 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Hết hàng', description = 'Cửa hàng đã hết vật phẩm!', type = 'error', position = 'center-left', duration = Config.NotifyDuration })
        return
    end
    TriggerClientEvent('merchant:openShop', src, items)
end)

RegisterNetEvent('merchant:buyItem', function(itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local itemData
    for _, item in ipairs(Config.ShopInventory) do
        if item.name == itemName then itemData = item break end
    end
    if not itemData then return end
    if itemData.stock < amount then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lỗi giao dịch', description = 'Không đủ ' .. itemData.label .. ' trong kho!', type = 'error', position = 'center-left', duration = Config.NotifyDuration })
        return
    end
    local totalCost = itemData.price * amount
    local money = itemData.currency == 'money' and xPlayer.getMoney() or xPlayer.getAccount('black_money').money
    if money < totalCost then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lỗi giao dịch', description = 'Bạn không đủ ' .. (itemData.currency == 'money' and 'tiền' or 'tiền bẩn') .. '!', type = 'error', position = 'center-left', duration = Config.NotifyDuration })
        return
    end
    if itemData.currency == 'money' then xPlayer.removeMoney(totalCost) else xPlayer.removeAccountMoney('black_money', totalCost) end
    xPlayer.addInventoryItem(itemName, amount)
    itemData.stock = itemData.stock - amount
    TriggerClientEvent('ox_lib:notify', src, { title = 'Thành công', description = 'Bạn đã mua ' .. amount .. ' ' .. itemData.label .. '!', type = 'success', position = 'center-left', duration = Config.NotifyDuration })
    sendToDiscord("Giao dịch thành công", "Người chơi: " .. (xPlayer.getName() or GetPlayerName(src)) .. "\nVật phẩm: " .. itemData.label .. " x" .. amount .. "\nTổng tiền: $" .. totalCost .. " (" .. itemData.currency .. ")", 65280)
end)
