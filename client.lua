local ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local hasRentedScooter = false
local currentScooter = nil
local currentDeliveryBlip = nil
local currentDeliveryCoords = nil
local pizzaInHand = false
local isDelivering = false
local isPizzaTaken = false

local playerXP = 0
local playerLevel = 1
local nextLevelXP = 100

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

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    FetchPlayerXP()
    CreatePizzaShopBlip()
    SetupPizzaShop()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

CreateThread(function()
    while ESX == nil do
        Wait(10)
    end
    
    while ESX.GetPlayerData().job == nil do
        Wait(10)
    end
    
    PlayerData = ESX.GetPlayerData()
    FetchPlayerXP()
    CreatePizzaShopBlip()
    SetupPizzaShop()
end)

function FetchPlayerXP()
    ESX.TriggerServerCallback(Config.JobName..':getPlayerXP', function(xp, level)
        playerXP = xp
        playerLevel = level
        
        for i, levelData in ipairs(Config.Levels) do
            if levelData.level > playerLevel then
                nextLevelXP = levelData.xp_required
                break
            end
        end
    end)
end

function CreatePizzaShopBlip()
    local blipInfo = Config.PizzaShop.blip
    local blip = AddBlipForCoord(blipInfo.coords)
    
    SetBlipSprite(blip, blipInfo.sprite)
    SetBlipDisplay(blip, blipInfo.display)
    SetBlipScale(blip, blipInfo.scale)
    SetBlipColour(blip, blipInfo.color)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(_(blipInfo.name))
    EndTextCommandSetBlipName(blip)
end

function SetupPizzaShop()
    local npcInfo = Config.PizzaShop.bossNPC
    RequestModel(GetHashKey(npcInfo.model))
    
    while not HasModelLoaded(GetHashKey(npcInfo.model)) do
        Wait(1)
    end
    
    local ped = CreatePed(4, GetHashKey(npcInfo.model), npcInfo.coords.x, npcInfo.coords.y, npcInfo.coords.z - 1.0, npcInfo.coords.w, false, true)
    SetEntityHeading(ped, npcInfo.coords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'pizza_talk_boss',
            icon = 'fas fa-pizza-slice',
            label = _('talk_to_boss'),
            onSelect = function()
                OpenPizzaMenu()
            end,
            canInteract = function()
                return PlayerData.job and PlayerData.job.name == Config.JobName
            end
        }
    })

    exports.ox_target:addSphereZone({
        coords = Config.PizzaShop.scooterReturnPoint,
        radius = 2.0,
        debug = false,
        options = {
            {
                name = 'pizza_return_scooter',
                icon = 'fas fa-motorcycle',
                label = _('return_scooter'),
                onSelect = function()
                    ReturnScooter()
                end,
                canInteract = function()
                    return hasRentedScooter
                end
            }
        }
    })
end

function OpenPizzaMenu()
    local xpNeeded = nextLevelXP - playerXP
    
    lib.registerContext({
        id = 'pizza_shop_menu',
        title = _('menu_title'),
        options = {
            {
                title = string.format(_('menu_progress'), playerLevel, playerXP, nextLevelXP),
                description = string.format(_('xp_needed'), xpNeeded),
                icon = 'fas fa-star',
                readOnly = true,
            },
            {
                title = string.format(_('menu_rent_scooter'), Config.PizzaShop.bailAmount),
                description = _('menu_rent_scooter_desc'),
                icon = 'fas fa-motorcycle',
                onSelect = function()
                    RentScooter()
                end,
                disabled = hasRentedScooter
            },
            {
                title = _('menu_sell_receipts'),
                description = _('menu_sell_receipts_desc'),
                icon = 'fas fa-receipt',
                onSelect = function()
                    SellReceipts()
                end
            },
            {
                title = _('menu_close'),
                icon = 'fas fa-times',
                onSelect = function()
                end
            }
        }
    })
    
    lib.showContext('pizza_shop_menu')
end

function RentScooter()
    if hasRentedScooter then
        lib.notify({
            title = _('job_title'),
            description = _('no_scooter_rented'),
            type = 'error'
        })
        return
    end
    
    ESX.TriggerServerCallback(Config.JobName..':canPayBail', function(canPay)
        if canPay then
            local spawnPoint = Config.PizzaShop.scooterSpawnPoint
            
            ESX.Game.SpawnVehicle(Config.PizzaShop.scooterModel, vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z), spawnPoint.w, function(vehicle)
                currentScooter = vehicle
                
                SetVehicleNumberPlateText(vehicle, "PIZZA"..math.random(100, 999))
                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                
                exports.ox_target:addLocalEntity(vehicle, {
                    {
                        name = 'pizza_take_from_scooter',
                        icon = 'fas fa-pizza-slice',
                        label = _('take_pizza'),
                        onSelect = function()
                            if currentDeliveryCoords and not isPizzaTaken then
                                TakePizzaFromScooter()
                            else
                                lib.notify({
                                    title = _('job_title'),
                                    description = _('no_active_delivery'),
                                    type = 'error'
                                })
                            end
                        end,
                        canInteract = function()
                            return currentDeliveryCoords ~= nil and not isPizzaTaken
                        end
                    }
                })
                
                hasRentedScooter = true
                lib.notify({
                    title = _('job_title'),
                    description = string.format(_('scooter_rented'), Config.PizzaShop.bailAmount),
                    type = 'success'
                })
                
                GenerateDelivery()
            end)
        else
            lib.notify({
                title = _('job_title'),
                description = _('not_enough_money'),
                type = 'error'
            })
        end
    end)
end

function TakePizzaFromScooter()
    if not isPizzaTaken and currentDeliveryCoords then
        isPizzaTaken = true
        
        lib.progressBar({
            duration = 3000,
            label = _('preparing_pizza'),
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
            },
            anim = {
                dict = 'anim@heists@box_carry@',
                clip = 'idle'
            },
            prop = {
                model = prop_pizza_box_01,
                pos = vector3(0.0, -0.05, -0.18),
                rot = vector3(0.0, 0.0, 0.0)
            },
        })
        
        pizzaInHand = true
        CreateThread(function()
            local playerPed = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(playerPed))
            local pizzaBox = CreateObject(GetHashKey("prop_pizza_box_01"), x, y, z + 0.2, true, true, true)
            AttachEntityToEntity(pizzaBox, playerPed, GetPedBoneIndex(playerPed, 60309), 0.0, -0.05, -0.18, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            
            while pizzaInHand do
                Wait(100)
            end
            
            DetachEntity(pizzaBox, true, true)
            DeleteObject(pizzaBox)
        end)
    end
end

function AddDeliveryTargetZone()
    if currentDeliveryCoords then
        exports.ox_target:addSphereZone({
            coords = currentDeliveryCoords,
            radius = 1.5,
            debug = false,
            options = {
                {
                    name = 'pizza_deliver',
                    icon = 'fas fa-hand-holding',
                    label = _('deliver_pizza'),
                    onSelect = function()
                        if pizzaInHand and not isDelivering then
                            DeliverPizza()
                        else
                            lib.notify({
                                title = _('job_title'),
                                description = _('no_pizza_in_hand'),
                                type = 'error'
                            })
                        end
                    end,
                    canInteract = function()
                        return pizzaInHand and not isDelivering
                    end
                }
            }
        })
    end
end

function DeliverPizza()
    if pizzaInHand and currentDeliveryCoords and not isDelivering then
        isDelivering = true
        
        lib.progressBar({
            duration = 20000,
            label = _('delivering_pizza'),
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
                movement = true,
                combat = true,
            },
            anim = {
                dict = 'timetable@jimmy@doorknock@',
                clip = 'knockdoor_idle'
            },
        })
        
        pizzaInHand = false
        isPizzaTaken = false
        isDelivering = false
        
        TriggerServerEvent(Config.JobName..':deliveryComplete')
        
        if currentDeliveryBlip ~= nil then
            RemoveBlip(currentDeliveryBlip)
            currentDeliveryBlip = nil
        end
        
        exports.ox_target:removeZone('pizza_deliver')
        
        Wait(2000)
        GenerateDelivery()
    end
end

function GenerateDelivery()
    if not hasRentedScooter then return end
    
    local randomIndex = math.random(1, #Config.Deliveries)
    currentDeliveryCoords = Config.Deliveries[randomIndex]
    
    if currentDeliveryBlip ~= nil then
        RemoveBlip(currentDeliveryBlip)
    end
    
    currentDeliveryBlip = AddBlipForCoord(currentDeliveryCoords)
    SetBlipSprite(currentDeliveryBlip, 1)
    SetBlipColour(currentDeliveryBlip, 2)
    SetBlipRoute(currentDeliveryBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(_('blip_delivery'))
    EndTextCommandSetBlipName(currentDeliveryBlip)
    
    AddDeliveryTargetZone()
    
    lib.notify({
        title = _('job_title'),
        description = _('new_delivery'),
        type = 'info'
    })
end

function ReturnScooter()
    if hasRentedScooter and currentScooter ~= nil then
        local playerCoords = GetEntityCoords(PlayerPedId())
        local returnPoint = Config.PizzaShop.scooterReturnPoint
        local distance = #(playerCoords - returnPoint)
        
        if distance > 5.0 then
            lib.notify({
                title = _('job_title'),
                description = _('player_not_close'),
                type = 'error'
            })
            return
        end
        
        local scooterCoords = GetEntityCoords(currentScooter)
        local scooterDistance = #(scooterCoords - returnPoint)
        
        if scooterDistance > 5.0 then
            lib.notify({
                title = _('job_title'),
                description = _('scooter_not_close'),
                type = 'error'
            })
            return
        end
        
        ESX.Game.DeleteVehicle(currentScooter)
        
        if currentDeliveryBlip ~= nil then
            RemoveBlip(currentDeliveryBlip)
            currentDeliveryBlip = nil
        end
        
        TriggerServerEvent(Config.JobName..':returnBail')
        
        hasRentedScooter = false
        currentScooter = nil
        currentDeliveryCoords = nil
        pizzaInHand = false
        isPizzaTaken = false
        
        lib.notify({
            title = _('job_title'),
            description = string.format(_('scooter_returned'), Config.PizzaShop.bailAmount),
            type = 'success'
        })
    else
        lib.notify({
            title = _('job_title'),
            description = _('no_scooter_rented'),
            type = 'error'
        })
    end
end

function SellReceipts()
    ESX.TriggerServerCallback(Config.JobName..':getReceiptCount', function(count)
        if count > 0 then
            TriggerServerEvent(Config.JobName..':sellReceipts')
        else
            lib.notify({
                title = _('job_title'),
                description = _('no_receipts'),
                type = 'error'
            })
        end
    end)
end

RegisterNetEvent(Config.JobName..':updateXP')
AddEventHandler(Config.JobName..':updateXP', function(xp, level, newXP)
    local oldLevel = playerLevel
    
    playerXP = xp
    playerLevel = level
    
    for i, levelData in ipairs(Config.Levels) do
        if levelData.level > playerLevel then
            nextLevelXP = levelData.xp_required
            break
        end
    end
    
    if playerLevel > oldLevel then
        lib.notify({
            title = _('level_up_title'),
            description = string.format(_('level_up'), playerLevel),
            type = 'success'
        })
    end

end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if currentScooter ~= nil then
            ESX.Game.DeleteVehicle(currentScooter)
        end
        
        if currentDeliveryBlip ~= nil then
            RemoveBlip(currentDeliveryBlip)
        end
    end
end)