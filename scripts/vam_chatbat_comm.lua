OOB_MSGTYPE_VAM_SETTARGETS = "vam_settargets";
OOB_MSGTYPE_VAM_CLEARTARGETS = "vam_cleartargets";

function onInit()
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_VAM_SETTARGETS, handleSetTargets);
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_VAM_CLEARTARGETS, handleClearTargets);
end

-- Call only as a player. GM can take these actions locally.
function notifySetTargets(nSourceCT, aTargetCTNodes)
    local aTargets = {}
    for _, nTarget in pairs(aTargetCTNodes) do
        table.insert(aTargets, nTarget.getNodeName())
    end
    local msgOOB = {
        type = OOB_MSGTYPE_VAM_SETTARGETS,
        user = User.getUsername(),
        identity = User.getIdentityLabel(),
        sSource = nSourceCT.getNodeName(),
        sTargets = table.concat(aTargets, ' '),
    };

    Comm.deliverOOBMessage(msgOOB, "")
end

function handleSetTargets(msgOOB)
    if not User.isHost() then
        return
    end
    local nSourceCT = DB.findNode(msgOOB.sSource)
    local aTargetCTNodes = {}
    for _, sTargetNodeName in pairs(StringManager.split(msgOOB.sTargets, ' ')) do
        table.insert(aTargetCTNodes, DB.findNode(sTargetNodeName))
    end
    VamChatBatTargeting.setTargetsForNode(nSourceCT, aTargetCTNodes)
end

-- Call only as a player. GM can take these actions locally.
function notifyClearTargets(nCT)
    local msgOOB = {
        type = OOB_MSGTYPE_VAM_CLEARTARGETS,
        user = User.getUsername(),
        identity = User.getIdentityLabel(),
        sNode = nCT.getNodeName(),
    };

    Comm.deliverOOBMessage(msgOOB, "")
end

function handleClearTargets(msgOOB)
    if not User.isHost() then
        return
    end
    local nCT = DB.findNode(msgOOB.sNode)
    VamChatBatTargeting.clearTargetsForNode(nCT)
end
