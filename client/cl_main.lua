local QBCore = exports['qb-core']:GetCoreObject()

local Timer, HasAlreadyEnteredMarker, ChoppingInProgress, LastZone, PedIsTryingToChopVehicle, MenuOpen, ProgressBarOpen = 0, false, false, nil, false, false
local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}

-- Functions --

function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function IsDriver()
    return GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()
end

function MaxSeats(vehicle)
    local vehpas = GetVehicleNumberOfPassengers(vehicle)
    return vehpas
end

function CreateBlipCircle(coords, text, radius, color, sprite)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
end



function ChopVehicle()
    local ped = PlayerPedId()
    if IsPedOnAnyBike(ped) then
        QBCore.Functions.Notify(Lang:t('no_bikes'), 'error')
    else
        local seats = MaxSeats(vehicle)
        if seats ~= 0 then
            QBCore.Functions.Notify(Lang:t('cannot_chop_passengers'), 'error')
        elseif GetGameTimer() - Timer > Config.CooldownMinutes * 60000 then
            Timer = GetGameTimer()
            QBCore.Functions.TriggerCallback('nwrp_vehicletief:anycops', function(anycops)
                if anycops >= Config.CopsRequired then
                    local randomReport = math.random(1, 100)
                    if randomReport <= 10 then
                        local data = exports['cd_dispatch']:GetPlayerInfo()
                        TriggerServerEvent('cd_dispatch:AddNotification', {
                            job_table = {'police', 'sheriff'}, 
                            coords = data.coords,
                            title = '10-15 - Rozebírání Vozidla',
                            message = 'A '..data.sex..' rozebírá zřejmě kradené vozidlo. '..data.street, 
                            flash = 0,
                            unique_id = data.unique_id,
                            sound = 1,
                            blip = {
                                sprite = 431, 
                                scale = 1.2, 
                                colour = 3,
                                flashes = false, 
                                text = '911 - Rozebírání Vozidla',
                                time = 5,
                                radius = 0,
                            }
                        })
                        PedIsTryingToChopVehicle = true
                    end
                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    TriggerServerEvent('scrap:log')
                    TriggerServerEvent('nwrp_vehicletief:ChopRewards')
                    ChoppingInProgress = true
                    VehiclePartsRemoval()
                    if not HasAlreadyEnteredMarker then
                        HasAlreadyEnteredMarker = true
                        ChoppingInProgress = false
                        QBCore.Functions.Notify(Lang:t('zoneleft'), 'error')
                        SetVehicleAlarmTimeLeft(vehicle, 60000)
                    end
                else
                    QBCore.Functions.Notify(Lang:t('not_enough_cops'), 'error')
                end
            end)
        else
            local timerNewChop = Config.CooldownMinutes * 60000 - (GetGameTimer() - Timer)
            local TotalTime = math.floor(timerNewChop / 60000)
            if TotalTime > 0 then
                QBCore.Functions.Notify(Lang:t('come_back_in', { minutes = TotalTime }), 'error')
            elseif TotalTime <= 0 then
                QBCore.Functions.Notify(Lang:t('minute'), 'error')
            end
        end
    end
end

function TriggerPartsRemovalProgressBar(message, action, doorIndex)
    local ped = PlayerPedId()
    while ProgressBarOpen do
        Citizen.Wait(250)
    end
    ProgressBarOpen = true
    QBCore.Functions.Progressbar('remove_parts', message, Config.RemovePart * 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        -- Done
        if action == 'opening' then
            SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), doorIndex, false, false)
        elseif action == 'removing' then
            SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false), doorIndex, true)
        else
            QBCore.Functions.Notify(Lang:t('invalid_action'), 'error')
        end
        Citizen.Wait(500)
        ClearPedTasks(ped)
        ClearPedSecondaryTask(ped)
        FreezeEntityPosition(ped, false)
        ProgressBarOpen = false
    end, function()
        -- Cancel
        ClearPedTasks(ped)
        ClearPedSecondaryTask(ped)
        FreezeEntityPosition(ped, false)
        ProgressBarOpen = false
    end)
end

function VehiclePartsRemoval()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local rearLeftDoor = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'door_dside_r')
    local bonnet = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'bonnet')
    local boot = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1), false), 'boot')
    SetVehicleEngineOn(vehicle, false, false, true)
    SetVehicleUndriveable(vehicle, false)
    if ChoppingInProgress == true then
        TriggerPartsRemovalProgressBar(Lang:t('opening_front_left'), 'opening', 0)
    end
    if ChoppingInProgress == true then
        TriggerPartsRemovalProgressBar(Lang:t('removing_front_left'), 'removing', 0)
    end
    if ChoppingInProgress == true then
        TriggerPartsRemovalProgressBar(Lang:t('opening_front_right'), 'opening', 1)
    end
    if ChoppingInProgress == true then
        TriggerPartsRemovalProgressBar(Lang:t('removing_front_right'), 'removing', 1)
    end
    if rearLeftDoor ~= -1 then
        if ChoppingInProgress == true then
            TriggerPartsRemovalProgressBar(Lang:t('opening_rear_left'), 'opening', 2)
        end
        if ChoppingInProgress == true then
            TriggerPartsRemovalProgressBar(Lang:t('removing_rear_left'), 'removing', 2)
        end
        if ChoppingInProgress == true then
            TriggerPartsRemovalProgressBar(Lang:t('opening_rear_right'), 'opening', 3)
        end
        if ChoppingInProgress == true then
            TriggerPartsRemovalProgressBar(Lang:t('removing_rear_right'), 'removing', 3)
        end
    end
    if bonnet ~= -1 then
        if ChoppingInProgress == true then
            TriggerPartsRemovalProgressBar(Lang:t('opening_hood'), 'opening', 4)
        end
        if ChoppingInProgress == true then
            TriggerPartsRemovalProgressBar(Lang:t('removing_hood'), 'removing', 4)
        end
    end
    if boot ~= -1 then
        if ChoppingInProgress == true then
            TriggerPartsRemovalProgressBar(Lang:t('opening_trunk'), 'opening', 5)
        end
        if ChoppingInProgress == true then
            TriggerPartsRemovalProgressBar(Lang:t('removing_trunk'), 'removing', 5)
        end
    end
    Citizen.Wait(Config.RemovePart * 1000 + 1000)
    if ChoppingInProgress == true then
                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteVehicle(vehicle)
                    Citizen.Wait(250)
                    if IsPedInAnyVehicle(ped) then
                        DeleteVehicle(vehicle)
                        TriggerServerEvent('nwrp_vehicletief:ChopRewards')
                    end
                end
end


RegisterNetEvent('nwrp_vehicletief:NotifPosProgress')
AddEventHandler('nwrp_vehicletief:NotifPosProgress', function(targetCoords)
    QBCore.Functions.TriggerCallback('nwrp_vehicletief:server:isWhitelisted', function(isWhitelisted)
        if isWhitelisted then
            local alpha = 250
            local ChopBlip = AddBlipForRadius(targetCoords.x, targetCoords.y, targetCoords.z, 50.0)
            SetBlipHighDetail(ChopBlip, true)
            SetBlipColour(ChopBlip, 17)
            SetBlipAlpha(ChopBlip, alpha)
            SetBlipAsShortRange(ChopBlip, true)
            while alpha ~= 0 do
                Citizen.Wait(5 * 4)
                alpha = alpha - 1
                SetBlipAlpha(ChopBlip, alpha)
                if alpha == 0 then
                    RemoveBlip(ChopBlip)
                    PedIsTryingToChopVehicle = false
                    return
                end
            end
        end
    end)
end)

AddEventHandler('nwrp_vehicletief:hasEnteredMarker', function(zone)
    if zone == 'Chopshop' and IsDriver() then
        CurrentAction = 'Chopshop'
        CurrentActionMsg = Lang:t('press_to_chop')
        CurrentActionData = {}
    elseif zone == 'Screw' then
        CurrentAction = 'Chopshop'
        CurrentActionMsg = Lang:t('press_to_chop')
        CurrentActionData = {}
    end
end)




-- Threads --

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        if DecorGetInt(PlayerPedId(), 'Chopping') == 2 then
            Citizen.Wait(Timing)
            DecorSetInt(PlayerPedId(), 'Chopping', 1)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        if NetworkIsSessionStarted() then
            DecorRegister('Chopping', 3)
            DecorSetInt(PlayerPedId(), 'Chopping', 1)
            return
        end
    end
end)

Citizen.CreateThread(function()
    for k, zone in pairs(Config.Zones) do
        if zone.blipEnabled then
            CreateBlipCircle(zone.coords, zone.name, zone.radius, zone.color, zone.sprite)
        end
    end
end)

-- Display Marker
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local letSleep = true
        for k, v in pairs(Config.Zones) do
            local distance = GetDistanceBetweenCoords(playerCoords, v.Pos.x, v.Pos.y, v.Pos.z, true)
            if v.markerEnabled and Config.MarkerType ~= -1 and distance < Config.DrawDistance then
                DrawMarker(Config.MarkerType, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)
                letSleep = false
            end
        end
        if letSleep then
            Citizen.Wait(500)
        end
    end
end)


-- Enter / Exit marker events
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local isInMarker = false
        local currentZone = nil
        for k, v in pairs(Config.Zones) do
            local distance = GetDistanceBetweenCoords(playerCoords, v.Pos.x, v.Pos.y, v.Pos.z, true)
            if distance < v.Size.x then
                isInMarker = true
                currentZone = k
            end
        end
        if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
            HasAlreadyEnteredMarker = true
            if IsControlJustReleased(0, 38) then
                local vehicle = GetVehiclePedIsUsing(ped)
                if vehicle then
                    local plate = GetVehicleNumberPlateText(GetVehiclePedIsUsing(PlayerPedId()))
                    QBCore.Functions.TriggerCallback('nwrp_vehicletief:OwnedCar', function(plate)
                        if owner then
                        --    QBCore.Functions.Notify('tohle auto nekomu patri', 'success')
                        wait(0)
                        else
                            QBCore.Functions.Notify(Lang:t('call'), 'success')
                            ChopVehicle()
                         --   TriggerServerEvent('nwrp_vehicletief:ChopRewards')
                            CurrentAction = nil
                            if IsPedInAnyVehicle(ped) then
                                QBCore.Functions.Notify(Lang:t('call'), 'success')
                                ChopVehicle()
                                --TriggerServerEvent('nwrp_vehicletief:ChopRewards')
                                CurrentAction = nil
                            end
                        end
                    end, plate)
                end
            if not isInMarker and HasAlreadyEnteredMarker then
                HasAlreadyEnteredMarker = false
                TriggerServerEvent('scrap:logac')
            end
        end
    end
end 
end)


--[[ Key controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if CurrentAction ~= nil then
            if IsDriver() then
                if CurrentAction == 'Chopshop' then
                    DrawText3Ds(Config.Zones['Chopshop'].coords.x, Config.Zones['Chopshop'].coords.y, Config.Zones['Chopshop'].coords.z + 0.9, CurrentActionMsg)
                    if IsControlJustReleased(0, 38) then
                        ChopVehicle()
                        CurrentAction = nil
                    end
                end
            elseif CurrentAction == 'Screw' then
                DrawText3Ds(Config.Zones['Screw'].coords.x, Config.Zones['Screw'].coords.y, Config.Zones['Screw'].coords.z + 0.9, CurrentActionMsg)
                if IsControlJustReleased(0, 38) then
                    ChopVehicle()
                    CurrentAction = nil
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)]]

