lastNth = 1
aMemorizedTargets = {}

function onInit()
    CombatManager.setCustomInitChange(handleEndTurn);
end

function handleEndTurn()
    lastNth = 1
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
    clearTargetsForNode(nSource)
    for _,nCT in pairs(CombatManager.getCombatantNodes()) do
        local friendFoe = nCT.getChild('friendfoe').getText()
        local bVisible = DB.getValue(nCT, "tokenvis", 0) == 1 or friendFoe == 'friend'
        if bVisible then -- Never auto-target a hidden token
            local tokenCT = CombatManager.getTokenFromCT(nCT)
            local distance = Token.getDistanceBetween(tokenSource, tokenCT)
            if distance <= radius then
                TargetingManager.addCTTarget(nSource, nCT)
            end
        end
    end
end

function targetFrom(targetFromNode, faction, count, nth)
    if not targetFromNode then
        VamChatBatUtil.sendLocalChat("No active creature")
        return
    end
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
    if targetFromToken == nil then
        VamChatBatUtil.sendLocalChat("Your token must be on a map before it can target")
        return
    end
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
            local distance = VamChatBatUtil.getDistance(targetFromToken, CombatManager.getTokenFromCT(targetNode))
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
        --Debug.chat('targeting', targetFromNode, targetNode)
        TargetingManager.addCTTarget(targetFromNode, targetNode)
    end
    if toTarget[1] == nil then
        VamChatBatUtil.sendLocalChat("No " .. faction .. " combatants found")
    end
    lastNth = nth
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
    return friendFoe == faction
end

function clearTargetsForNode(node)
    local t = CombatManager.getTokenFromCT(node)
    TargetingManager.clearCTTargets(node, t)
end

function clearTargets()
    local n = VamChatBatUtil.actionNode()
    if not n then
        VamChatBatUtil.sendLocalChat("There is no active creature for targeting")
        return
    end
    clearTargetsForNode(n)
    lastNth = 1
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
    for _,t in pairs(aMemorizedTargets) do
        local nTarget = DB.findNode(t['sCreatureNode'])
        TargetingManager.addCTTarget(nSource, nTarget)
    end
end
