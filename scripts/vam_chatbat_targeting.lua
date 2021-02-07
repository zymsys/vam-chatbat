-- This is a table of combat tracker nodes to numbers.
-- The number defaults to 1, meaning the nearest target.
-- When the auto target request is completed the number is incremented.
-- The next auto-targeting starts from that number, so you can cycle through opponents.
lastNth = {}

-- /cb m populates this with the current targets, and /cb r restores them.
aMemorizedTargets = {}

function onInit()
    CombatManager.setCustomInitChange(handleEndTurn);
end

function handleEndTurn()
    --Maybe not needed if we track by source node name?
    --lastNth = 1
end

function autoTarget(faction, count)
    if StringManager.isNumberString(faction) then
        count = faction
        faction = nil
    end
    if faction == 'r' then
        targetRadius(count or 5) -- Not targeting a count, targeting a radius. Default it to 5'.
        return
    end
    targetFrom(VamChatBatUtil.actionNode(), faction, tonumber(count))
end

function targetRadius(radius)
    if not Token.getDistanceBetween then
        VamChatBatUtil.sendLocalChat("Upgrade to FGU 4.0.7 or newer to target by radius.")
    end
    radius = tonumber(radius)
    local nSource = VamChatBatUtil.actionNode()
    local tokenSource = CombatManager.getTokenFromCT(nSource)
    local aTargetCTNodes
    clearTargetsForNode(nSource)
    for _,nCT in pairs(CombatManager.getCombatantNodes()) do
        local friendFoe = nCT.getChild('friendfoe').getText()
        local bVisible = DB.getValue(nCT, "tokenvis", 0) == 1 or friendFoe == 'friend'
        if bVisible then -- Never auto-target a hidden token
            local tokenCT = CombatManager.getTokenFromCT(nCT)
            local distance = Token.getDistanceBetween(tokenSource, tokenCT)
            if distance <= radius then
                table.insert(aTargetCTNodes, nCT)
            end
        end
    end
    setTargetsForNode(nSource, aTargetCTNodes)
end

function targetFrom(nSourceCT, sFaction, count, nth)
    if not nSourceCT then
        VamChatBatUtil.sendLocalChat("No active creature")
        return
    end
    count = count or 1
    local sSourceNodeName = nSourceCT.getNodeName()
    nth = nth or lastNth[sSourceNodeName] or 1
    if sFaction == nil then
        -- Foes target friendlies. Friendlies and neutrals target foes.
        local targetFromFaction = nSourceCT.getChild('friendfoe').getText()
        if targetFromFaction == 'foe' then
            sFaction = 'friend'
        else
            sFaction = 'hostile'
        end
        --Debug.chat('Setting target faction to', faction, 'for', targetFromFaction)
    end
    local targetFromToken = CombatManager.getTokenFromCT(nSourceCT)
    if targetFromToken == nil then
        VamChatBatUtil.sendLocalChat("Your token must be on a map before it can target")
        return
    end
    if User.isHost() and targetFromToken and targetFromToken.isActivable() then
        -- This never activates a target. Why?
        --Debug.chat("Why you no activate?")
        targetFromToken.setActive(true);
    end
    local aTargets = {}
    local nTargetCount = 0
    for _, targetNode in pairs(CombatManager.getCombatantNodes()) do
        if shouldTarget(targetNode, sFaction) then
            local nDistance = VamChatBatUtil.getDistance(targetFromToken, CombatManager.getTokenFromCT(targetNode))
            if not aTargets[nDistance] then
                aTargets[nDistance] = {}
            end
            table.insert(aTargets[nDistance], targetNode)
            nTargetCount = nTargetCount + 1
        end
    end
    local aDistances = {}
    for distance in pairs(aTargets) do table.insert(aDistances, distance) end
    table.sort(aDistances)
    local aFlattened = {}
    for _, distance in pairs(aDistances) do
        local aTargetsForDistance = aTargets[distance]
        for _, targetNode in pairs(aTargetsForDistance) do
            table.insert(aFlattened, targetNode)
        end
    end
    local toTarget = {}
    while count > 0 do
        if nth > nTargetCount then
            nth = 1
        end
        table.insert(toTarget, aFlattened[nth])
        count = count - 1
        nth = nth + 1
    end
    if toTarget[1] == nil then
        VamChatBatUtil.sendLocalChat("No " .. sFaction .. " combatants found")
    else
        clearTargetsForNode(nSourceCT)
        setTargetsForNode(nSourceCT, toTarget)
    end
    lastNth[sSourceNodeName] = nth
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
    --Debug.chat('Should target?', node, friendFoe, faction)
    return friendFoe == faction
end

function clearTargetsForNode(node)
    local t = CombatManager.getTokenFromCT(node)
    TargetingManager.clearCTTargets(node, t)
end

function setTargetsForNode(nSource, aTargetCTNodes)
    if User.isHost() then
        for _,targetNode in pairs(aTargetCTNodes) do
            --Debug.chat('targeting', targetFromNode, targetNode)
            TargetingManager.addCTTarget(nSource, targetNode)
        end
    else
        VamChatBatComm.notifySetTargets(nSource, aTargetCTNodes)
    end
end

function clearTargets()
    local nCT = VamChatBatUtil.actionNode()
    if not nCT then
        VamChatBatUtil.sendLocalChat("There is no active creature for targeting")
        return
    end
    clearTargetsForNode(nCT)
    lastNth[nCT.getNodeName()] = 1
end

function memorizeTargets()
    local n = VamChatBatUtil.actionNode()
    if not n then
        VamChatBatUtil.sendLocalChat("There is no active creature for targeting")
        return
    end
    local rActor = ActorManager.resolveActor(n)
    aMemorizedTargets = TargetingManager.getFullTargets(rActor)
    aMemorizedNames = {}
    for _,t in pairs(aMemorizedTargets) do
        table.insert(aMemorizedNames, t['sName'])
    end
    VamChatBatUtil.sendLocalChat("Memorized targets: " .. table.concat(aMemorizedNames, ', '))
end

function restoreTargets()
    local nSource = VamChatBatUtil.actionNode()
    if not nSource then
        VamChatBatUtil.sendLocalChat("There is no active creature for targeting")
        return
    end
    clearTargetsForNode(nSource)
    aTargets = {}
    for _,t in pairs(aMemorizedTargets) do
        local nTarget = DB.findNode(t['sCreatureNode'])
        table.insert(aTargets, nTarget)
    end
    setTargetsForNode(nSource, aTargets)
end
