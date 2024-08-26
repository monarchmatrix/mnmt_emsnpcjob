local QBCore = exports['qb-core']:GetCoreObject()
local pedLocation = Config.PedLocation
local pedModel = Config.PedModel
local injuredPedLocations = Config.InjuredPedLocations
local randomMalePeds = Config.RandomMalePeds

local playerData = {}
local loopActive = false
local currentTaskActive = false
local spawnedInjuredPed = nil
local spawnedBlip = nil
local taskCounter = 0

-- Function to check if the player is on duty
local function isPlayerOnDuty()
    local playerData = QBCore.Functions.GetPlayerData()
    return playerData.job.name == "ambulance" and playerData.job.onduty
end

-- Function to spawn the task-starting ped
function SpawnPed()
    local pedHash = GetHashKey(pedModel)

    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do
        Wait(1)
    end

    local ped = CreatePed(4, pedHash, pedLocation.x, pedLocation.y, pedLocation.z, pedLocation.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- Add qb-target interaction with job check
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = "mnmt-emsjob:client:startHelpLoop",
                icon = "fas fa-hand-paper",
                label = "Start Helping",
            },
            {
                type = "client",
                event = "mnmt-emsjob:client:stopHelpLoop",
                icon = "fas fa-hand-paper",
                label = "Stop Helping",
            },
        },
        distance = 2.5
    })
end

-- Event to spawn the ped when the resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SpawnPed()
    end
end)

-- Event to spawn the ped when the player spawns
AddEventHandler('playerSpawned', function()
    SpawnPed()
end)

-- Event handler to start the NPC help loop
RegisterNetEvent('mnmt-emsjob:client:startHelpLoop', function()
    if isPlayerOnDuty() then
        loopActive = true
        taskCounter = 0
        QBCore.Functions.Notify("You have started helping locals now.", "success")
        SpawnNextInjuredPed()
    else
        QBCore.Functions.Notify("You must be on duty with the ambulance job to help locals.", "error")
    end
end)

-- Event handler to stop the NPC help loop
RegisterNetEvent('mnmt-emsjob:client:stopHelpLoop', function()
    loopActive = false
    currentTaskActive = false
    taskCounter = 0
    if spawnedInjuredPed then
        DeleteEntity(spawnedInjuredPed)
        spawnedInjuredPed = nil
    end
    if spawnedBlip then
        RemoveBlip(spawnedBlip)
        spawnedBlip = nil
    end
    QBCore.Functions.Notify("You have stopped helping locals.", "error")
end)

-- Function to spawn the next injured ped
function SpawnNextInjuredPed()
    if not loopActive or currentTaskActive then return end

    if taskCounter >= 6 then
        TriggerEvent('mnmt-emsjob:client:stopHelpLoop')
        QBCore.Functions.Notify("You have completed the tasks, now head back to hospital.", "success")
        return
    end

    local injuredLocation = injuredPedLocations[math.random(1, #injuredPedLocations)]
    local randomPedModel = randomMalePeds[math.random(1, #randomMalePeds)]
    local injuredPedModel = GetHashKey(randomPedModel)

    RequestModel(injuredPedModel)
    while not HasModelLoaded(injuredPedModel) do
        Wait(1)
    end

    local injuredPed = CreatePed(4, injuredPedModel, injuredLocation.x, injuredLocation.y, injuredLocation.z, injuredLocation.w, false, true)
    SetEntityAsMissionEntity(injuredPed, true, true)
    SetEntityInvincible(injuredPed, true)
    SetBlockingOfNonTemporaryEvents(injuredPed, true)

    -- Switch NPC animation to lying on the floor
    local animDict = "amb@world_human_bum_slumped@male@laying_on_left_side@base"
    local animName = "base"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    TaskPlayAnim(injuredPed, animDict, animName, 8.0, -8.0, -1, 2, 0, false, false, false)

    spawnedInjuredPed = injuredPed
    currentTaskActive = true

    -- Add qb-target interaction to the injured ped
    exports['qb-target']:AddTargetEntity(injuredPed, {
        options = {
            {
                type = "client",
                event = "mnmt-emsjob:client:helpInjured",
                icon = "fas fa-hand-paper",
                label = "Help",
            },
        },
        distance = 1.5
    })

    -- Notify the user that there is a new person who needs help
    QBCore.Functions.Notify("A new injured person needs help. Check your GPS for the location.", "success")

    -- Add a blip with a radius around the spawned NPC location
    if spawnedBlip then
        RemoveBlip(spawnedBlip)
    end
    spawnedBlip = AddBlipForRadius(injuredLocation.x, injuredLocation.y, injuredLocation.z, 50.0)
    SetBlipColour(spawnedBlip, 1) -- Red color
    SetBlipAlpha(spawnedBlip, 128) -- Transparency

    -- Set the waypoint on the map
    SetNewWaypoint(injuredLocation.x, injuredLocation.y)
end

-- Event handler to help the injured NPC
RegisterNetEvent('mnmt-emsjob:client:helpInjured', function()
    if isPlayerOnDuty() then
        TriggerServerEvent('mnmt-emsjob:server:checkFirstAid', GetPlayerServerId(PlayerId()))
    else
        QBCore.Functions.Notify("You must be on duty to help the injured person.", "error")
    end
end)

-- Function to start CPR animation
function StartCPRAnimation()
    local playerPed = PlayerPedId()
    local animDict = "mini@cpr@char_a@cpr_str"
    local animName = "cpr_pumpchest"

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end

    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
end

-- Function to stop CPR animation
function StopCPRAnimation()
    local playerPed = PlayerPedId()
    ClearPedTasksImmediately(playerPed)
end

-- Event handler to reset ped animation and make it disappear
RegisterNetEvent('mnmt-emsjob:client:resetPedAnimation', function()
    if spawnedInjuredPed then
        StartCPRAnimation()
        QBCore.Functions.Progressbar("helping_injured", "Helping the injured person...", 10000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            StopCPRAnimation()
            ClearPedTasksImmediately(spawnedInjuredPed)
            TaskWanderStandard(spawnedInjuredPed, 10.0, 10)

            Citizen.CreateThread(function()
                Wait(10000)
                DeleteEntity(spawnedInjuredPed)
                spawnedInjuredPed = nil

                currentTaskActive = false
                taskCounter = taskCounter + 1

                if loopActive then
                    SpawnNextInjuredPed()
                end
            end)

            QBCore.Functions.Notify("You have helped the injured person.", "success")
            -- Trigger server event to remove firstaid and give payment
            TriggerServerEvent('mnmt-emsjob:server:removeFirstAidAndGivePayment', GetPlayerServerId(PlayerId()))
        end, function() -- Cancel
            StopCPRAnimation()
            QBCore.Functions.Notify("You cancelled the helping process.", "error")
        end)
    end
end)