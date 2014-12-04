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
var float bleedPeriod, poisonStartTime;

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

    if (isPoisoned) {
        speedBonusScale= fmin((Level.TimeSeconds - poisonStartTime)/maxSpeedPenaltyTime, 1.0);
        if (ownerCtrllr.Pawn == None || Owner.Pawn.Health <= 0 || speedBonusScale >= 1) {
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
    bleedState.bleedCount= maxBleedCount;

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
}
