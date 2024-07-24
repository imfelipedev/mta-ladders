--// Custom events

addEvent("ladders:sync", true)
addEventHandler("ladders:sync", resourceRoot, function(player, bool, rotation)
    if bool then 
        setTimer(function()
            if isTimer(sourceTimer) then 
                killTimer(sourceTimer)
            end
            
            setPedAnimation(player, "ladder", "ladder_up_a", -1, true, false, false, false)
            setElementRotation(player, 0, 0, rotation)
        end, 50, 1)
        return true
    end
    
    setPedAnimation(player, nil, nil)
end)

--// Mta events

addEventHandler("onClientResourceStart", resourceRoot, function()
    setTimer(function()
        engineLoadIFP("assets/animations/ladders.ifp", "ladder")
    end, 1000, 1)
end)