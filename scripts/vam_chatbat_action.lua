selectedAction = nil
selectedActionActor = nil

function takeAction(aWords)
    local nCreature = VamChatBatUtil.actionNode()
    if nCreature then
        attackFrom(VamChatBatUtil.actionNode(), aWords)
    else
        VamChatBatUtil.sendLocalChat("No active creature")
    end
end

-- Mage Hand for example has a name but no actual actions.
-- Let's filter things that don't contain actions out of the list.

function dumpAction(aWords)
    Debug.chat(findAction(aWords, getAvailableActions(VamChatBatUtil.actionNode())))
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
        local type = rAction['type']
        rActionNodes = DB.getChildren(v)
        if type == 'cast' then
            rActionSet['rAttackAction'] = rAction
        elseif type == 'damage' then
            rActionSet['rDamageAction'] = rAction
        elseif type == 'effect' then
            rActionSet['rEffectAction'] = rAction
        elseif type == 'heal' then
            rActionSet['rHealAction'] = rAction
        else
            Debug.chat("Need to add action handler for", rAction)
        end
    end
    return rActionSet
end


-- Might need to do something like this when the user takes the action...
--CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);
function actionSetFromWeapon(nCreature, nWeapon)
    local rAttackAction = CharWeaponManager.buildAttackAction(nCreature, nWeapon)
    return {
        sName = rAttackAction['label'] .. ' (' .. rAttackAction['range'] .. ')',
        rAttackAction = rAttackAction,
        rDamageAction = CharWeaponManager.buildDamageAction(nodeChar, nWeapon),
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
    local rActionSet = { sName = rAttack.name }
    local aAbilities = rAttack['aAbilities']
    for _, rAction in pairs(aAbilities) do
        local type = rAction.sType
        rActionSet.sName = rActionSet.sName or rAction.label or rAction.sName or rAction.sType
        if type == 'attack' then
            if rAction.range then
                rActionSet.sName = rActionSet.sName .. ' (' .. rAction.range .. ')'
            end
            rActionSet['rAttackAction'] = rAction
        elseif type == 'damage' then
            rActionSet['rDamageAction'] = rAction
        elseif type == 'effect' then
            rActionSet['rEffectAction'] = rAction
        elseif type == 'powersave' then
            rActionSet['rSaveAction'] = rAction
        elseif type == 'heal' then
            rActionSet['rHealAction'] = rAction
        else
            Debug.chat("Need to add NPC action handler for", rAction)
        end
    end
    return rActionSet
end

function npcActionsForCreature(aActions)
    local aAvailableActions = { sName = 'action' }
    for _, action in pairs(aActions) do
        local sAttack = DB.getValue(action, "value", "")
        local rAttack = CombatManager2.parseAttackLine(sAttack)
        table.insert(aAvailableActions, actionSetFromAttackLine(rAttack))
    end
    return aAvailableActions
end

function npcSpellsForCreature(aSpells)
    local aAvailableActions = {}
    for _, action in pairs(aSpells) do
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

function getAvailableActions(nCT)
    local rActor = ActorManager.resolveActor(nCT)
    local nCreature = DB.findNode(rActor['sCreatureNode'])
    local rCreatureNodes = DB.getChildren(nCreature)

    -- Find different types of actions and normalize them into a consistent structure
    local aPowerActions = powerActionsForCreature(DB.getChildren(rCreatureNodes['powers']))
    local aWeaponActions = weaponActionsForCreature(DB.getChildren(rCreatureNodes['weaponlist']))
    local aNPCActions = npcActionsForCreature(DB.getChildren(nCT, 'actions'))
    local aNPCSpells = npcSpellsForCreature(DB.getChildren(nCT, 'spells'))

    -- Merge them into one list
    local aAllActions = VamChatBatUtil.tableConcat(
        VamChatBatUtil.tableConcat(aPowerActions, aWeaponActions),
        VamChatBatUtil.tableConcat(aNPCActions, aNPCSpells)
    )

    -- Filter out actions that have a name only, but no actionable items
    return VamChatBatUtil.arrayFilter(aAllActions, function (v)
        return VamChatBatUtil.tableLength(v) > 1
    end)
end

function attackFrom(nCT, aWords)
    local rActor = ActorManager.resolveActor(nCT)
    local aAvailableActions = getAvailableActions(nCT)

    if #aWords == 1 then
        summarizeActions(rActor, aAvailableActions)
    else
        selectedAction = findAction(aWords, aAvailableActions)
        selectedActionActor = rActor
        if selectedAction ~= nil then
            VamChatBatUtil.sendPublicChat(selectedAction.sName, rActor.sName)
            local bDidNothing = true
            if selectedAction.rSaveAction then
                ActionPower.performSaveVsRoll(nil, rActor, selectedAction.rSaveAction)
                bDidNothing = false
            end
            if selectedAction.rEffectAction then
                ActionEffect.performRoll(nil, rActor, selectedAction.rEffectAction)
                bDidNothing = false
            end
            if selectedAction.rAttackAction then
                ActionAttack.performRoll(nil, rActor, selectedAction.rAttackAction)
                bDidNothing = false
            end
            if selectedAction.rHealAction then
                ActionHeal.performRoll(nil, rActor, selectedAction.rHealAction)
                bDidNothing = false
            end
            if selectedAction.rDamageAction and bDidNothing then
                -- If all we had to do was deal damage, then go for it
                ActionDamage.performRoll(nil, selectedActionActor, selectedAction.rDamageAction)
                -- But don't then allow additional follow up damage
                selectedAction = nil
            end
        else
            VamChatBatUtil.sendLocalChat("No active creature, or no such action")
        end
    end
end

function followUpDamage()
    if selectedAction and selectedAction.rDamageAction then
        ActionDamage.performRoll(nil, selectedActionActor, selectedAction.rDamageAction)
    else
        VamChatBatUtil.sendLocalChat("Attack with ChatBat before damage")
    end
end