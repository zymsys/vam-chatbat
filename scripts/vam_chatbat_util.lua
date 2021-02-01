function getDistance(tSource, tTarget)
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

-- Determine which node to act upon
function actionNode()
    if User.isHost() then
        return CombatManager.getActiveCT()
    else
        return CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity())
    end
end

function sendLocalChat(msg)
    Comm.addChatMessage({text = msg})
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
