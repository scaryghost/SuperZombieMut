class SZReplicationInfo extends ReplicationInfo;

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

replication {
    reliable if (bNetDirty && Role == ROLE_Authority)
        isBleeding, isPoisoned, ownerPRI;
}

function tick(float DeltaTime) {
    local float EncumbrancePercentage, speedBonusScale, WeightMod, HealthMod;
    local PlayerController ownerCtrllr;
    local KFPlayerReplicationInfo kfpri;
    local KFHumanPawn ownerPawn;

    ownerCtrllr= PlayerController(Owner);
    if (ownerCtrllr.Pawn != none && ownerCtrllr.Pawn.Health > 0 && bleedState.count > 0) {
        if (bleedState.nextBleedTime < Level.TimeSeconds) {
            bleedState.count--;
            bleedState.nextBleedTime+= bleedPeriod;
            ownerCtrllr.Pawn.TakeDamage(2 + rand(1), bleedState.instigator, ownerCtrllr.Pawn.Location, 
                    vect(0, 0, 0), class'DamTypeStalkerBleed');
            if (ownerCtrllr.Pawn.isA('KFPawn')) {
                KFPawn(ownerCtrllr.Pawn).HealthToGive-= 5;
            }
        }
    } else {
        isBleeding= false;
    }

    if (isPoisoned) {
        speedBonusScale= fmin((Level.TimeSeconds - poisonStartTime) / maxSpeedPenaltyTime, 1.0);
        if (ownerCtrllr.Pawn == None || ownerCtrllr.Pawn.Health <= 0 || speedBonusScale >= 1) {
            isPoisoned= false;
        } else {
            ownerPawn= KFHumanPawn(ownerCtrllr.Pawn);

            EncumbrancePercentage= (FMin(ownerPawn.CurrentWeight, ownerPawn.MaxCarryWeight)/ownerPawn.MaxCarryWeight);
            WeightMod= (1.0 - (EncumbrancePercentage * ownerPawn.WeightSpeedModifier));
            HealthMod= ((ownerPawn.Health/ownerPawn.HealthMax) * ownerPawn.HealthSpeedModifier) + (1.0 - ownerPawn.HealthSpeedModifier);

            // Apply all the modifiers
            ownerPawn.GroundSpeed = class'KFHumanPawn'.default.GroundSpeed * HealthMod;
            ownerPawn.GroundSpeed *= WeightMod;
            ownerPawn.GroundSpeed += ownerPawn.InventorySpeedModifier * speedBonusScale;

            kfpri= KFPlayerReplicationInfo(ownerPRI);
            if (kfpri != none && kfpri.ClientVeteranSkill != none ) {
                // GetMovementSpeedModifier returns a multiplier >= 1.0
                ownerPawn.GroundSpeed*= (kfpri.ClientVeteranSkill.static.GetMovementSpeedModifier(kfpri, 
                        KFGameReplicationInfo(Level.GRI)) - 1 ) * speedBonusScale + 1;
            }
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
    poisonStartTime= Level.TimeSeconds;
    isPoisoned= true;
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
    maxSpeedPenaltyTime= 10
}
