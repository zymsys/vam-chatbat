OOB_TYPE_VAM_SET_TARGETS = "vam_set_targets";
OOB_TYPE_VAM_RESUME_PROCESSING = "vam_resume_processing";

function onInit()
    OOBManager.registerOOBMsgHandler(OOB_TYPE_VAM_SET_TARGETS, handleSetTargets)
    OOBManager.registerOOBMsgHandler(OOB_TYPE_VAM_RESUME_PROCESSING, handleResumeProcessing)
end

-- Call only as a player. GM can take these actions locally.
function notifySetTargets(nSourceCT, aTargetCTNodes)
    local aTargets = {}
    for _, nTarget in pairs(aTargetCTNodes) do
        table.insert(aTargets, nTarget.getNodeName())
    end
    local msgOOB = {
        type = OOB_TYPE_VAM_SET_TARGETS,
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
    notifyResumeProcessing(msgOOB.user)
end

function notifyResumeProcessing(sUsername)
    Comm.deliverOOBMessage({
        type = OOB_TYPE_VAM_RESUME_PROCESSING,
        user=sUsername,
        identity = User.getIdentityLabel(),
    }, sUsername)
end

function handleResumeProcessing()
    VamChatBat.processCommandStack()
end
