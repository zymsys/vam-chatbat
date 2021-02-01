selectedAction = nil

function takeAction(aWords)
    local nCreature = VamChatBatUtil.actionNode()
    if nCreature then
        attackFrom(VamChatBatUtil.actionNode(), aWords)
    else
        VamChatBatUtil.sendLocalChat("No active creature")
    end
end

function performWeaponAttack(nWeapon)
    local nChar = nWeapon.getChild("...")
    local rAction = CharWeaponManager.buildAttackAction(nChar, nWeapon);
    CharWeaponManager.decrementAmmo(nChar, nWeapon);
    local rActor = ActorManager.getActor("pc", nChar);
    ActionAttack.performRoll(nil, rActor, rAction);
end

function actionSetFromPower(rPower)
    local rActionSet = {
        sName = rPower.name.getValue(),
    }
    local aActionNodes = DB.getChildren(rPower['actions'])
    for _,v in pairs(aActionNodes) do
        local rAction, rActor = PowerManager.getPCPowerAction(v)
        rActionNodes = DB.getChildren(v)
        if rAction['type'] == 'cast' then
            rActionSet['rAttackRoll'] = ActionAttack.getRoll(rActor, rAction)
        elseif rAction['type'] == 'damage' then
            rActionSet['rDamageRoll'] = ActionDamage.getRoll(rActor, rAction)
        else
            Debug.chat("Need to add action handler for", rAction)
        end
    end
    return rActionSet
end


-- Might need to do something like this when the user takes the action...
--CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);
function actionSetFromWeapon(nCreature, nWeapon)
    local rActor = ActorManager.resolveActor(nCreature)
    local rAttackAction = CharWeaponManager.buildAttackAction(nCreature, nWeapon);
    local rDamageAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon);
    return {
        sName = rAttackAction['label'] .. ' (' .. rAttackAction['range'] .. ')',
        rAttackRoll = ActionAttack.getRoll(rActor, rAttackAction),
        rDamageRoll = ActionDamage.getRoll(rActor, rDamageAction),
    }
end

function powerActionsForCreature(aPowers)
    local aAvailableActions = {}
    for _, nPower in pairs(aPowers) do
        local rPower = DB.getChildren(nPower)
        local rAction = actionSetFromPower(rPower)
        table.insert(aAvailableActions, rAction)
    end
    return aAvailableActions
end

function weaponActionsForCreature(aWeapons)
    local aAvailableActions = {}
    for _, nWeapon in pairs(aWeapons) do
        local rAction = actionSetFromWeapon(nCreature, nWeapon)
        table.insert(aAvailableActions, rAction)
    end
    return aAvailableActions
end

function actionSetFromAttackLine(rAttack)
    local rActionSet = {}
    local aAbilities = rAttack['aAbilities']
    for _, rAbility in pairs(aAbilities) do
        rActionSet['sName'] = rAbility.label .. ' (' .. rAbility.range .. ')'
        if rAbility['sType'] == 'attack' then
            rActionSet['rAttackRoll'] = ActionAttack.getRoll(rActor, rAbility)
        elseif rAbility['sType'] == 'damage' then
            rActionSet['rDamageRoll'] = ActionDamage.getRoll(rActor, rAbility)
        else
            Debug.chat("Need to add NPC action handler for", rAbility)
        end
    end
    return rActionSet
end

function npcActionsForCreature(aActions)
    local aAvailableActions = {}
    for _, action in pairs(aActions) do
        local sAttack = DB.getValue(action, "value", "")
        local rAttack = CombatManager2.parseAttackLine(sAttack)
        table.insert(aAvailableActions, actionSetFromAttackLine(rAttack))
    end
    return aAvailableActions
end

function summarizeActions(rActor, aActions)
    VamChatBatUtil.sendLocalChat("Actions for " .. rActor['sName'])
    for index, rAction in pairs(aActions) do
        VamChatBatUtil.sendLocalChat(index .. ': ' .. rAction['sName'])
    end
end

function findActionByName(aWords, aActions)
    table.remove(aWords, 1)
    local sName = table.concat(aWords, ' ')
    for _,v in pairs(aActions) do
        if sName == v.sName then
            return v
        end
    end
    return nil
end

function findAction(aWords, aActions)
    if StringManager.isNumberString(aWords[2]) then
        return aActions[tonumber(aWords[2])]
    else
        return findActionByName(aWords, aActions)
    end
end

function attackFrom(nCT, aWords)
    local rActor = ActorManager.resolveActor(nCT)
    local nCreature = DB.findNode(rActor['sCreatureNode'])
    local rCreatureNodes = DB.getChildren(nCreature)

    -- Find different types of actions and normalize them into a consistent structure
    local aPowerActions = powerActionsForCreature(DB.getChildren(rCreatureNodes['powers']))
    local aWeaponActions = weaponActionsForCreature(DB.getChildren(rCreatureNodes['weaponlist']))
    local aNPCActions = npcActionsForCreature(DB.getChildren(nCT, 'actions'))

    -- Merge them into one list
    local aAvailableActions = VamChatBatUtil.tableConcat(VamChatBatUtil.tableConcat(aPowerActions, aWeaponActions), aNPCActions)

    if #aWords == 1 then
        summarizeActions(rActor, aAvailableActions)
    else
        selectedAction = findAction(aWords, aAvailableActions)
        if selectedAction ~= nil then
            ActionsManager.performAction(nil, rActor, selectedAction['rAttackRoll'])
        else
            VamChatBatUtil.sendLocalChat("No active creature, or no such action")
        end
    end
end

function followUpDamage()
    if selectedAction and selectedAction.rDamageRoll then
        local rActor = ActorManager.resolveActor(nCT)
        ActionsManager.performAction(nil, rActor, selectedAction['rDamageRoll'])
    else
        VamChatBatUtil.sendLocalChat("Attack with ChatBat before damage")
    end
end