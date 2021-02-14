function getDistance(tSource, tTarget)
    if not tTarget then -- The target creature is on the combat tracker but not on the map.
        return nil
    end
    if Token.getDistanceBetween then
        return Token.getDistanceBetween(tSource, tTarget)
    end
    local nSourceX, nSourceY = tSource.getPosition()
    local nTargetX, nTargetY = tTarget.getPosition()
    local nRise = nSourceY - nTargetY
    local nRun = nSourceX - nTargetX
    local nDistance = math.floor(math.sqrt(nRise ^2 + nRun ^2)+0.5)
    --local nodeAttackerContainer = tSource.getContainerNode();
    --local nDU = GameSystem.getDistanceUnitsPerGrid()
    --local nGrid = nodeAttackerContainer.getGridSize()
    --Debug.chat('nDU,nGrid,nDistance',nDU,nGrid,nDistance)
    return nDistance
end

-- From https://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
function tableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]  --corrected bug. if t1[#t1+i] is used, indices will be skipped
    end
    return t1
end

function tableLength(t)
    local c = 0
    for _ in pairs(t) do
        c = c + 1
    end
    return c
end

function arrayFilter(t,fn)
    local r = {}
    local i = 1
    for _,v in pairs(t) do
        if fn(v) then
            r[i] = v
            i = i + 1
        end
    end
    return r
end

function getSortedCombatantListStartingFromActive()
    local aCombatants = CombatManager.getSortedCombatantList()
    local nActiveCT = CombatManager.getActiveCT()
    if not nActiveCT then
        return aCombatants
    end
    local sActiveCTNodeName = nActiveCT.getNodeName()
    local aCombatantsFromActive = {}
    local bActiveFound = false
    for _, nCT in pairs(aCombatants) do
        if nCT.getNodeName() == sActiveCTNodeName then
            bActiveFound = true
        end
        if bActiveFound then
            table.insert(aCombatantsFromActive, nCT)
        end
    end
    for _, nCT in pairs(aCombatants) do
        if nCT.getNodeName() == sActiveCTNodeName then
            return aCombatantsFromActive
        end
        table.insert(aCombatantsFromActive, nCT)
    end
    -- If we reach here it means that the active node in the combat tracker is not
    -- in the combat tracker. Should never happen, but ¯\_(ツ)_/¯
    return aCombatants
end

-- Determine which node to act upon
function actionNode()
    if User.isHost() then
        return CombatManager.getActiveCT()
    end
    local aIdentityStrings = User.getActiveIdentities()
    local aCombatants = getSortedCombatantListStartingFromActive()
    for _, nCT in pairs(aCombatants) do
        local rActor = ActorManager.resolveActor(nCT)
        for _, sCharacterId in pairs(aIdentityStrings) do
            local sCharSheetNodeName = 'charsheet.' .. sCharacterId
            if sCharSheetNodeName == rActor.sCreatureNode then
                return nCT
            end
        end
    end
    -- If we don't own anything on the combat tracker, return nil
    return nil
end

function sendLocalChat(msg)
    Comm.addChatMessage({text = msg})
end

function sendPublicChat(msg, who)
    local chat = {text = msg}
    if who then
        chat.sender = who
    end
    Comm.deliverChatMessage(chat)
end

-- For debugging
function mapNodesToText(rChildNodes)
    local rMappedToText = {}
    for k,v in pairs(rChildNodes) do
        local type = v.getType()
        if type == 'string' or type == 'formattedtext' then
            rMappedToText[k] = v.getText()
        elseif type == 'number' then
            rMappedToText[k] = tonumber(v.getText())
        else
            rMappedToText[k] = type
        end
    end
    return rMappedToText
end

function getChildrenAsText(n)
    return mapNodesToText(DB.getChildren(n))
end
