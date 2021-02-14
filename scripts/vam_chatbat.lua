-- Another distance calculator:
-- https://www.fantasygrounds.com/forums/showthread.php?65246-Experimental-APIs-for-FGU&p=574167&viewfull=1#post574167

local aCommandStack = {}
local bIsProcessing = false
local bIsWaitingForAsync = false

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
    VamChatBatUtil.sendLocalChat("/cb t r {radius}  ## Target by radius, ignoring faction")
    VamChatBatUtil.sendLocalChat("/cb {action}, {action}, {etc}  ## Multiple actions are separated by a comma")
end

function processCommandStack()
    bIsProcessing = true
    bIsWaitingForAsync = false
    while not bIsWaitingForAsync and #aCommandStack > 0 do
        processNextChatBatCommand()
    end
    bIsProcessing = false
end

function processCommand(_, sParams)
    local aCommands = StringManager.split(sParams, ',', true)
    if #aCommands == 0 then
        showHelp()
    end
    for _, sCommand in pairs(aCommands) do
        pushChatBatCommand(sCommand)
    end
    if not bIsProcessing then
        processCommandStack()
    end
end

-- This is a secret command that is used during development to just hold some code
-- and execute it to see what it does. It is not intended for end user consumption.
function bobo()
    -- Building a function that gets a sorted list of combatants that starts with the active
    -- and loops back around.
    local a = VamChatBatUtil.getSortedCombatantListStartingFromActive()
    for _,v in pairs(a) do
        local rActor = ActorManager.resolveActor(v)
        Debug.chat('name', rActor.sName)
    end
end

function who()
    local aCTNodes = VamChatBatUtil.getSortedCombatantListStartingFromActive()
    for _, nCT in pairs(aCTNodes) do
        local rActor = ActorManager.resolveActor(nCT)
        local aDescription = { rActor.sName, rActor.sCTNode, rActor.sCreatureNode }
        VamChatBatUtil.sendLocalChat(table.concat(aDescription, ', '))
    end
end

function pushChatBatCommand(sCommand)
    table.insert(aCommandStack, sCommand)
end

function processNextChatBatCommand()
    local sCommand = aCommandStack[1]
    if sCommand then
        aCommandStack = {unpack(aCommandStack, 2)}
        bIsWaitingForAsync = processChatBatCommand(sCommand)
    end
end

-- Return true if the command requires us to wait on an async action. False (or nil) otherwise.
-- Processing can be resumed by calling processCommandStack()
function processChatBatCommand(sCommand)
    local aWords = StringManager.split(sCommand, ' ', true)
    if aWords[1] == 'a' then
        return VamChatBatAction.takeAction(aWords)
    elseif aWords[1] == 'd' then
        return VamChatBatAction.followUpDamage()
    elseif aWords[1] == 'm' then
        return VamChatBatTargeting.memorizeTargets()
    elseif aWords[1] == 'r' then
        return VamChatBatTargeting.restoreTargets()
    elseif aWords[1] == 'c' then
        return VamChatBatTargeting.clearTargets()
    elseif aWords[1] == 't' then
        return VamChatBatTargeting.autoTarget(aWords[2], aWords[3])
    -- Start Undocumented Commands
    elseif aWords[1] == 'dump' then
        return VamChatBatAction.dumpAction(aWords)
    elseif aWords[1] == 'who' then
        return who()
    elseif aWords[1] == 'bobo' then
        return bobo()
    -- End Undocumented Commands
    else
        VamChatBatUtil.sendLocalChat("Unknown command: " .. aWords[1])
        showHelp()
        return false
    end
end