OOB_MSGTYPE_VAM_SETTARGET = "vam_settargets";

function onInit()
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_VAM_SETTARGET, handleSetTargets);
end

-- Call only as a player. GM can take these actions locally.
function notifySetTargets(nSourceCT, aTargetCTNodes)
    local aTargets = {}
    for _, nTarget in pairs(aTargetCTNodes) do
        table.insert(aTargets, nTarget.getNodeName())
    end
    local msgOOB = {
        type = OOB_MSGTYPE_VAM_SETTARGET,
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
