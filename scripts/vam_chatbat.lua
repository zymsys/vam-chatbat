-- Add a way to reset the combat tracker after an encounter
-- Undo damage?
-- Different attack and cast commands
-- Check use of chat and whisper as much as possible

-- How do I find the best actor to target from as a player?
-- From effect.lua:
--if User.isHost() then
--    rTarget = ActorManager.getActorFromCT(CombatManager.getActiveCT());
--else
--    rTarget = ActorManager.getActor("pc", CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity()));
--end

-- Another distance calculator:
-- https://www.fantasygrounds.com/forums/showthread.php?65246-Experimental-APIs-for-FGU&p=574167&viewfull=1#post574167

function onInit()
    Comm.registerSlashHandler("chatbat", processCommand);
    Comm.registerSlashHandler("cb", processCommand);
end

function showHelp()
    VamChatBatUtil.sendLocalChat("/cb a {action}  ## List actions, or take the specified action")
    VamChatBatUtil.sendLocalChat("/cb c  ## Clear targets")
    VamChatBatUtil.sendLocalChat("/cb d  ## Roll damage for last ChatBat attack")
    VamChatBatUtil.sendLocalChat("/cb m  ## Memorize targets")
    VamChatBatUtil.sendLocalChat("/cb r  ## Restore targets")
    VamChatBatUtil.sendLocalChat("/cb t {faction} {count}  ## Auto-target")
    VamChatBatUtil.sendLocalChat("/cb {action}, {action}, {etc}  ## Multiple actions are separated by a comma")
end

function processCommand(_, sParams)
    local aCommands = StringManager.split(sParams, ',', true)
    if #aCommands == 0 then
        showHelp()
    end
    for _, sCommand in pairs(aCommands) do
        processChatBatCommand(sCommand)
    end
end

function processChatBatCommand(sCommand)
    local aWords = StringManager.split(sCommand, ' ', true)
    if aWords[1] == 'a' then
        VamChatBatAction.takeAction(aWords)
    elseif aWords[1] == 'd' then
        VamChatBatAction.followUpDamage()
    elseif aWords[1] == 'm' then
        VamChatBatTargeting.memorizeTargets()
    elseif aWords[1] == 'r' then
        VamChatBatTargeting.restoreTargets()
    elseif aWords[1] == 'c' then
        VamChatBatTargeting.clearTargets()
    elseif aWords[1] == 't' then
        VamChatBatTargeting.autoTarget(aWords[2], aWords[3])
    else
        VamChatBatUtil.sendLocalChat("Unknown command: " .. aWords[1])
        showHelp()
    end
end