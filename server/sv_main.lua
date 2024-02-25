local QBCore = exports['qb-core']:GetCoreObject()

-- Functions --

function rewardItems(source, items)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    for k, v in pairs(items) do
            player.Functions.AddItem(v.name, v.amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[v.name], 'add', v.amount)
        end
    end

-- Events --

RegisterServerEvent('nwrp_vehicletief:NotifPos')
AddEventHandler('nwrp_vehicletief:NotifPos', function(targetCoords)
    TriggerClientEvent('nwrp_vehicletief:NotifPosProgress', -1, targetCoords)
end)

RegisterServerEvent('nwrp_vehicletief:ChopRewards')
AddEventHandler('nwrp_vehicletief:ChopRewards', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    player.Functions.AddItem('clutch', 1)
    player.Functions.AddItem('tuner', 1)
    player.Functions.AddItem('spoiler', 1)
    player.Functions.AddItem('llanta', 4)
    player.Functions.AddItem('car-battery', 1)
    player.Functions.AddItem('front-bumper', 1)
    player.Functions.AddItem('rear-bumper', 2)
    player.Functions.AddItem('side-skirts', 1)

end)



-- Callbacks --

QBCore.Functions.CreateCallback('nwrp_vehicletief:anycops', function(source, cb)
    local policeCount = 0
    for _, v in pairs(QBCore.Functions.GetQBPlayers()) do
        if v.PlayerData.job.name == 'police' and v.PlayerData.job.onduty then
            policeCount = policeCount + 1
        end
    end
    cb(policeCount)
end)

QBCore.Functions.CreateCallback('nwrp_vehicletief:OwnedCar', function(source, cb, plate)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, player.PlayerData.citizenid })
    if result ~= nil and result[1] ~= nil and Config.Config.OwnedCarsNo == true then
        Citizen.Wait(5)
        MySQL.query('DELETE FROM player_vehicles WHERE plate = ?', { plate })
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('nwrp_vehicletief:server:getSellableItems', function(source, cb)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local items = {}
    for k, v in pairs(Config.Items) do
        local hasItem = player.Functions.GetItemByName(v.name)
        if hasItem and hasItem.amount > 0 then
            local item = {}
            local rewardItems = {}
            item.name = v.name
            item.label = QBCore.Shared.Items[v.name]['label']
            item.price = v.price
            item.amount = hasItem.amount
            item.totalPrice = hasItem.amount * v.price
            if Config.EnableItemRewards then
                for k2, v2 in pairs(v.item_sale_rewards) do
                    if v2 > 0 then
                        local rewardItem = {}
                        rewardItem.name = k2
                        rewardItem.amount = v2
                        rewardItem.totalAmount = v2 * item.amount
                        table.insert(rewardItems, rewardItem)
                    end
                end
            end
            item.rewardItems = rewardItems
            table.insert(items, item)
        end
    end
    cb(items)
end)



QBCore.Functions.CreateCallback('nwrp_vehicletief:OwnedCar', function(source, cb, plate)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local result = MySQL.query.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    --print(plate)
    if result[1] == nil then
cb(true)
    else
    --   print('tady bude stop hrače');
        TriggerClientEvent('QBCore:Notify', src, 'tohle auto nekomu patri', 'error', 3000)
      --  cb(false)
    end
end)

QBCore.Functions.CreateCallback('nwrp_vehicletief:server:isWhitelisted', function(source, cb)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local playerData = player.PlayerData
    if not playerData or not playerData.job then
        cb(false)
    end
    for k, v in ipairs(Config.WhitelistedCops) do
        if v == playerData.job.name then
            cb(true)
        end
    end
    cb(false)
end)




RegisterServerEvent('scrap:log')
AddEventHandler('scrap:log' ,function()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    local ped = GetPlayerPed(_source)
    local playerpos = GetEntityCoords(ped)
    local identif = exports['nwrp_core']:GetIdentifiers(_source)

        local Bname = 'Hráč Začal rozebírat auto'
        local Adminmessage

        Adminmessage = '**Hráč:** '..GetPlayerName(_source)..' || job: '..xPlayer.PlayerData.job.name..' ||'
        Adminmessage = Adminmessage..'\n\n**Pozice hráče:** '..playerpos


        Adminmessage = Adminmessage..'\n\n**Hex-ID:** '..identif.steam
        Adminmessage = Adminmessage..'\n**License:** '..identif.license
        Adminmessage = Adminmessage..'\n**Discord ID:** '..identif.discord
        Adminmessage = Adminmessage..'\n**IP:** '..identif.ip
        Adminmessage = Adminmessage..'\n\n*Testovací verze*'

        TriggerEvent('nwrp_core:boxLog', Bname, Adminmessage, 'https://discord.com/api/webhooks/1125562852854472755/ncDk2ho_z6NI4Y7u7j_WQiaZNk8a_BEj4jjwww2NQ8p2gjII8UYctNtOgo9i0y6WyOq_', '3158326')
    

    end)


RegisterServerEvent('scrap:logac')
    AddEventHandler('crap:logac' ,function()
        local _source = source
        local xPlayer = QBCore.Functions.GetPlayer(_source)
        local ped = GetPlayerPed(_source)
        local playerpos = GetEntityCoords(ped)
        local identif = exports['nwrp_core']:GetIdentifiers(_source)
        local Bname = 'Hráč se použil rozebrat auto na velkou vzdálenost'
        local Adminmessage

        Adminmessage = '**Hráč:** '..GetPlayerName(_source)..' || job: '..xPlayer.PlayerData.job.name..' ||'
        Adminmessage = Adminmessage..'\n\n**Pozice hráče:** '..playerpos


        Adminmessage = Adminmessage..'\n\n**Hex-ID:** '..identif.steam
        Adminmessage = Adminmessage..'\n**License:** '..identif.license
        Adminmessage = Adminmessage..'\n**Discord ID:** '..identif.discord
        Adminmessage = Adminmessage..'\n**IP:** '..identif.ip
        Adminmessage = Adminmessage..'\n\n*Testovací verze*'

        TriggerEvent('nwrp_core:boxLog', Bname, Adminmessage, 'https://discord.com/api/webhooks/1125562923801116672/paTU_k5x8qBIp1rBXRYkd4sylRuxdIg6RVAxwWGym8kMDQD7fbVp7I6wXPezOFcIlI8T', '3158326')
        
        DropPlayer(_source, 'Exploiting '..GetCurrentResourceName()..' - (too far): '..distance)
    end)

