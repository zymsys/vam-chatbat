-- Add a way to reset the combat tracker after an encounter

-- How do I find the best actor to target from as a player?
-- From effect.lua:
--if User.isHost() then
--    rTarget = ActorManager.getActorFromCT(CombatManager.getActiveCT());
--else
--    rTarget = ActorManager.getActor("pc", CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity()));
--end
lastNth = 1

function onInit()
    Comm.registerSlashHandler("chatbat", processCommand);
    Comm.registerSlashHandler("cb", processCommand);
    CombatManager.setCustomInitChange(handleEndTurn);
end

function handleEndTurn()
    lastNth = 1
end

function showHelp()
    Comm.addChatMessage({text = "/cb t {faction} {count}  ## Auto-target"});
    Comm.addChatMessage({text = "/cb c  ## Clear targets"});
end

function clearTargetsForNode(node)
    local t = CombatManager.getTokenFromCT(node)
    TargetingManager.clearCTTargets(node, t)
end

function clearTargetsCurrentCT()
    local node = CombatManager.getActiveCT()
    if node then
        clearTargetsForNode(node)
    else
        Comm.addChatMessage({text = "There is no active item in the combat tracker to target from."})
    end
end

function clearTargetsForUser()
    local node = CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity())
    if node then
        clearTargetsForNode(node)
    else
        Comm.addChatMessage({text = "There is no active character to target from"})
    end
end

function clearTargets()
    if User.isHost() then
        clearTargetsCurrentCT()
    else
        clearTargetsForUser()
    end
    lastNth = 1
end

function shouldTarget(node, faction)
    local factionNameMap = {
        friend = 'friend',
        f = 'friend',
        foe = 'foe',
        hostile = 'foe',
        h = 'foe',
        neutral = 'neutral',
        n = 'neutral',
    }
    faction = factionNameMap[faction] or 'foe'
    local friendFoe = node.getChild('friendfoe').getText()
    if (friendFoe ~= 'friend') and (DB.getValue(node, "tokenvis", 0) == 0) then
        return false -- Never auto-target a hidden token
    end
    --Debug.chat(friendFoe, faction)
    return friendFoe == faction
end

function targetFrom(targetFromNode, faction, count, nth)
    count = count or 1
    nth = nth or lastNth
    if faction == nil then
        -- Foes target friendlies. Friendlies and neutrals target foes.
        local targetFromFaction = targetFromNode.getChild('friendfoe').getText()
        if targetFromFaction == 'foe' then
            faction = 'friend'
        else
            faction = 'hostile'
        end
        --Debug.chat('Setting target faction to', faction, 'for', targetFromFaction)
    end
    local targetFromToken = CombatManager.getTokenFromCT(targetFromNode)
    if User.isHost() and targetFromToken and targetFromToken.isActivable() then
        -- This never activates a target. Why?
        --Debug.chat("Why you no activate?")
        targetFromToken.setActive(true);
    end
    local fromX, fromY = targetFromToken.getPosition()
    local targets = {}
    local targetCount = 0
    for _, targetNode in pairs(CombatManager.getCombatantNodes()) do
        if shouldTarget(targetNode, faction) then
            local targetToken = CombatManager.getTokenFromCT(targetNode)
            local targetX, targetY = targetToken.getPosition()
            local rise = fromY - targetY
            local run = fromX - targetX
            local distance = math.floor(math.sqrt(rise^2 + run^2)+0.5)
            targets[distance] = targetNode
            targetCount = targetCount + 1
        end
    end
    local distances = {}
    for distance in pairs(targets) do table.insert(distances, distance) end
    table.sort(distances)
    local toTarget = {}
    while count > 0 do
        if nth > targetCount then
            nth = 1
        end
        table.insert(toTarget, targets[distances[nth]])
        count = count - 1
        nth = nth + 1
    end
    clearTargetsForNode(targetFromNode)
    for _,targetNode in pairs(toTarget) do
        TargetingManager.addCTTarget(targetFromNode, targetNode)
    end
    if toTarget[1] == nil then
        Comm.addChatMessage({text = "No " .. faction .. " combatants found"});
    end
    lastNth = nth
end

function autoTargetCurrentCT(faction, count)
    local node = CombatManager.getActiveCT();
    if node then
        targetFrom(node, faction, count)
    else
        Comm.addChatMessage({text = "There is no active item in the combat tracker to target from"});
    end
end

function autoTargetCurrentUser(faction, count)
    local node = CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity())
    if node then
        targetFrom(node, faction, count)
    else
        Comm.addChatMessage({text = "There is no active character to target from."});
    end
end

function autoTarget(faction, count)
    if User.isHost() then
        autoTargetCurrentCT(faction, count)
    else
        autoTargetCurrentUser(faction, count)
    end
end

function processCommand(sCommand, sParams)
    local aWords = StringManager.parseWords(sParams);
    if aWords.getn == 0 then
        showHelp()
    end
    if aWords[1] == 't' then
        autoTarget(aWords[2], tonumber(aWords[3]))
        return;
    end
    if aWords[1] == 'c' then
        clearTargets()
        return;
    end
    showHelp()
end