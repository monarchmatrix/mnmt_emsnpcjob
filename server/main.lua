local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('mnmt-emsjob:server:checkFirstAid', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        local hasFirstAid = player.Functions.GetItemByName('firstaid')
        if hasFirstAid then
            TriggerClientEvent('mnmt-emsjob:client:resetPedAnimation', source)
        else
            TriggerClientEvent('QBCore:Notify', source, "You need a first aid kit to help the injured person.", "error")
        end
    end
end)

RegisterNetEvent('mnmt-emsjob:server:removeFirstAidAndGivePayment', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        local removed = player.Functions.RemoveItem('firstaid', 1)
        if removed then
            TriggerClientEvent('QBCore:Notify', source, "Your first aid kit has been used to help the injured person.", "success")
            local payment = math.random(660, 969)
            player.Functions.AddMoney('cash', payment, 'Helped injured person')
        else
            TriggerClientEvent('QBCore:Notify', source, "Failed to remove first aid kit from inventory.", "error")
        end
    end
end)