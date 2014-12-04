class SZReplicationInfo extends ReplicationInfo;

struct BleedingState {
    var float nextBleedTime;
    var Pawn instigator;
    var int bleedCount;
};

var PlayerReplicationInfo ownerPRI;
var bool isBleeding, isPoisoned;
var int numClotsAttached, maxBleedCount;
var BleedingState bleedState;
var float bleedPeriod;

replication {
    reliable if (bNetDirty && Role == ROLE_Authority)
        isBleeding, isPoisoned, ownerPRI;
}

function tick(float DeltaTime) {
    local PlayerController ownerCtrllr;
    local KFPawn ownerPawn;

    ownerCtrllr= PlayerController(Owner);
    if (Owner.Pawn != none && Owner.Pawn.Health > 0 && bleedCount > 0) {
        if (bleedState.nextBleedTime < Level.TimeSeconds) {
            bleedState.bleedCount--;
            bleedState.nextBleedTime+= bleedPeriod;
            Owner.Pawn.TakeDamage(2 + rand(1), pawns[i].instigator, pawns[i].P.Location, 
                    vect(0, 0, 0), class'DamTypeStalkerBleed');
            if (Owner.Pawn.isA('KFPawn')) {
                KFPawn(Owner.Pawn).HealthToGive-= 5;
            }
        }
    } else {
        isBleeding= false;
    }

    ownerPawn= KFPawn(PlayerController(Owner).Pawn);
    
}

function setBleeding(Pawn instigator) {
    bleedState.instigator= instigator;
    bleedState.bleedCount= maxBleedCount;

    if (!isBleeding) {
        bleedState.nextBleedTime= Level.TimeSeconds;
        isBleeding= true;
    }
    
}

function setPoison() {
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

defaultproperties {
    maxBleedCount= 7;
    bleedPeriod= 1.5;
}
