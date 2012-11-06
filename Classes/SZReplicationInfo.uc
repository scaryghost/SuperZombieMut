class SZReplicationInfo extends ReplicationInfo;

var PlayerReplicationInfo ownerPRI;
var bool isBleeding, isPoisoned;

replication {
    reliable if (bNetDirty && Role == ROLE_Authority)
        isBleeding, isPoisoned, ownerPRI;
}

static function SZReplicationInfo findSZri(PlayerReplicationInfo pri) {
    local SZReplicationInfo repInfo;

    if (pri == none)
        return none;

    foreach pri.DynamicActors(Class'SZReplicationInfo', repInfo)
        if (repInfo.ownerPRI == pri)
            return repInfo;
 
    return none;
}
