class SZReplicationInfo extends LinkedReplicationInfo;

struct BleedingState {
    var float nextBleedTime;
    var Pawn instigator;
    var int count;
};

var PlayerReplicationInfo ownerPRI;
var bool isBleeding, isPoisoned;
var int numClotsAttached, maxBleedCount;
var BleedingState bleedState;
var float bleedPeriod, poisonStartTime, maxSpeedPenaltyTime;
var Inventory poisonItem;

replication {
    reliable if (bNetDirty && Role == ROLE_Authority)
        isBleeding, isPoisoned, ownerPRI;
}

function PostBeginPlay() {
    if (Level.Game.GameDifficulty >= 5.0) {
        maxBleedCount= 7;
    } else if (Level.Game.GameDifficulty >= 2.0) {
        maxBleedCount= 5;
    } else {
        maxBleedCount= 3;
    }
}

function tick(float DeltaTime) {
    local PlayerController ownerCtrllr;
    local bool amAlive;

    ownerCtrllr= PlayerController(Owner);
    amAlive= ownerCtrllr != None && ownerCtrllr.Pawn != none && ownerCtrllr.Pawn.Health > 0;
    if (amAlive && bleedState.count > 0) {
        if (bleedState.nextBleedTime < Level.TimeSeconds) {
            bleedState.count--;
            bleedState.nextBleedTime+= bleedPeriod;
            ownerCtrllr.Pawn.TakeDamage(2, bleedState.instigator, ownerCtrllr.Pawn.Location, 
                    vect(0, 0, 0), class'DamTypeStalkerBleed');
            if (ownerCtrllr.Pawn.isA('KFPawn')) {
                KFPawn(ownerCtrllr.Pawn).HealthToGive-= 5;
            }
        }
    } else {
        bleedState.count= 0;
        isBleeding= false;
    }

    if (isPoisoned) {
        if (!amAlive || Level.TimeSeconds - poisonStartTime > maxSpeedPenaltyTime) {
            isPoisoned= false;
            ownerCtrllr.Pawn.DeleteInventory(poisonItem);
        }
    }
}

function setBleeding(Pawn instigator) {
    bleedState.instigator= instigator;
    bleedState.count= maxBleedCount;

    if (!isBleeding) {
        bleedState.nextBleedTime= Level.TimeSeconds;
        isBleeding= true;
    }
    
}

function setPoison() {
    if (!isPoisoned) {
        if (poisonItem == None) {
            poisonItem= Spawn(class'IronBall', Owner);
        }
        
        poisonItem.GiveTo(PlayerController(Owner).Pawn);
    }
    poisonStartTime= Level.TimeSeconds;
    isPoisoned= true;
}

static function SZReplicationInfo findSZri(PlayerReplicationInfo pri) {
    local LinkedReplicationInfo lriIt;
    local SZReplicationInfo repInfo;

    if (pri == none)
        return none;
    
    lriIt= pri.CustomReplicationInfo;
    while(lriIt != None && lriIt.class != class'SZReplicationInfo') {
        lriIt= lriIt.NextReplicationInfo;
    }

    if (lriIt == None) {
        foreach pri.DynamicActors(Class'SZReplicationInfo', repInfo)
            if (repInfo.ownerPRI == pri)
                return repInfo;
        return None;
    }
 
    return SZReplicationInfo(lriIt);
}

defaultproperties {
    bleedPeriod= 1.5;
    maxSpeedPenaltyTime= 10
}
