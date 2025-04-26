local ESX = exports['es_extended']:getSharedObject()

local PlayerXP = {}
local PlayerLevels = {}
local PlayerRentedScooters = {}

CreateThread(function()
    local useDatabase = false
    
    if MySQL then
        MySQL.ready(function()
            useDatabase = true
            
            MySQL.Async.execute('CREATE TABLE IF NOT EXISTS pizza_players (identifier VARCHAR(64) PRIMARY KEY, xp INT, level INT)', {}, function()
                
                MySQL.Async.fetchAll('SELECT * FROM pizza_players', {}, function(result)
                    if result and #result > 0 then
                        for _, playerData in ipairs(result) do
                            PlayerXP[playerData.identifier] = playerData.xp
                            PlayerLevels[playerData.identifier] = playerData.level
                        end
                    end
                end)
            end)
        end)
    end
    
    if not useDatabase then
    end
end)

function _(str, ...)
    if Config.Locales[Config.Locale] and Config.Locales[Config.Locale][str] then
        local args = {...}
        if #args > 0 then
            return string.format(Config.Locales[Config.Locale][str], ...)
        else
            return Config.Locales[Config.Locale][str]
        end
    end
    return 'Translation error: ' .. str
end

function GetPlayerLevel(xp)
    local level = 1
    
    for i, levelData in ipairs(Config.Levels) do
        if xp >= levelData.xp_required then
            level = levelData.level
        else
            break
        end
    end
    
    return level
end

ESX.RegisterServerCallback(Config.JobName..':getPlayerXP', function(source, cb)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if not xPlayer then
        cb(0, 1)
        return
    end
    
    local identifier = xPlayer.identifier
    
    if not PlayerXP[identifier] then
        PlayerXP[identifier] = 0
    end
    
    local level = GetPlayerLevel(PlayerXP[identifier])
    PlayerLevels[identifier] = level
    
    cb(PlayerXP[identifier], level)
end)

ESX.RegisterServerCallback(Config.JobName..':canPayBail', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false)
        return
    end
    
    local canPay = xPlayer.getMoney() >= Config.PizzaShop.bailAmount
    
    if canPay then
        xPlayer.removeMoney(Config.PizzaShop.bailAmount)
        PlayerRentedScooters[xPlayer.identifier] = true
    end
    
    cb(canPay)
end)

RegisterServerEvent(Config.JobName..':returnBail')
AddEventHandler(Config.JobName..':returnBail', function()
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if not xPlayer then return end
    
    if PlayerRentedScooters[xPlayer.identifier] then
        xPlayer.addMoney(Config.PizzaShop.bailAmount)
        PlayerRentedScooters[xPlayer.identifier] = nil
    end
end)

ESX.RegisterServerCallback(Config.JobName..':getReceiptCount', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(0)
        return
    end
    
    local receiptItem = xPlayer.getInventoryItem('pizza_factuur')
    local count = 0
    
    if receiptItem then
        count = receiptItem.count
    end
    
    cb(count)
end)

RegisterServerEvent(Config.JobName..':sellReceipts')
AddEventHandler(Config.JobName..':sellReceipts', function()
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if not xPlayer then return end
    
    local receiptItem = xPlayer.getInventoryItem('pizza_factuur')
    
    if not receiptItem or receiptItem.count <= 0 then
        TriggerClientEvent('ox_lib:notify', playerId, {
            title = _('job_title'),
            description = _('no_receipts'),
            type = 'error'
        })
        return
    end
    
    local count = receiptItem.count
    local reward = count * Config.RewardPerFactuur
    
    xPlayer.removeInventoryItem('pizza_factuur', count)
    xPlayer.addMoney(reward)
    
    TriggerClientEvent('ox_lib:notify', playerId, {
        title = _('job_title'),
        description = string.format(_('receipts_sold'), count, reward),
        type = 'success'
    })
end)

RegisterServerEvent(Config.JobName..':deliveryComplete')
AddEventHandler(Config.JobName..':deliveryComplete', function()
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if not xPlayer then return end
    
    xPlayer.addInventoryItem('pizza_factuur', 1)
    
    local identifier = xPlayer.identifier
    local xpGain = Config.XPPerDelivery
    
    if not PlayerXP[identifier] then
        PlayerXP[identifier] = 0
    end
    
    local oldLevel = GetPlayerLevel(PlayerXP[identifier])
    PlayerXP[identifier] = PlayerXP[identifier] + xpGain
    local newLevel = GetPlayerLevel(PlayerXP[identifier])
    
    SavePlayerXP(identifier)
    
    TriggerClientEvent(Config.JobName..':updateXP', playerId, PlayerXP[identifier], newLevel, xpGain)
    
    TriggerClientEvent('ox_lib:notify', playerId, {
        title = _('job_title'),
        description = string.format(_('delivery_complete'), Config.XPPerDelivery, xpGain),
        type = 'success'
    })
end)

function SavePlayerXP(identifier)
    if not PlayerXP[identifier] then return end
    
    local level = GetPlayerLevel(PlayerXP[identifier])
    
    if MySQL then
        MySQL.Async.execute('INSERT INTO pizza_players (identifier, xp, level) VALUES (@identifier, @xp, @level) ON DUPLICATE KEY UPDATE xp = @xp, level = @level', {
            ['@identifier'] = identifier,
            ['@xp'] = PlayerXP[identifier],
            ['@level'] = level
        })
    end
end

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if not xPlayer then return end
    
    local identifier = xPlayer.identifier

    if PlayerRentedScooters[identifier] then
        xPlayer.addMoney(Config.PizzaShop.bailAmount)
        PlayerRentedScooters[identifier] = nil
    end
    
    SavePlayerXP(identifier)
end)

Citizen.CreateThread(function()
    ESX.RegisterUsableItem('pizza_factuur', function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.showNotification(_('receipt_info'))
    end)
end)