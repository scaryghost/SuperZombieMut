class SZHumanPawn extends KFHumanPawn;

var float maxSpeedPenaltyTime;
var float speedPenaltyStartTime;
var int bleedCount, nextBleedTime, bleedPeriod, maxBleedCount;
var Pawn bleedInstigator;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    speedPenaltyStartTime= Level.TimeSeconds - maxSpeedPenaltyTime;
}

simulated function Tick(float DeltaTime) {
    super.Tick(DeltaTime);

    if (bleedCount > 0 && nextBleedTime < Level.TimeSeconds) {
        nextBleedTime+= bleedPeriod;
        TakeDamage(2+Rand(3), bleedInstigator, Location, vect(0,0,0), class'DamTypeBleed');
        bleedCount--;
    }
}

/**
 * Copied from KFHumanPawn.ModifyVelocity() and added
 * extra code to scale the InvenetorySpeedModifier and 
 * GetMovementSpeedModifier between 0 and 1
 */
simulated event ModifyVelocity(float DeltaTime, vector OldVelocity) {
    local float WeightMod, HealthMod;
    local float EncumbrancePercentage;
    local KFPlayerReplicationInfo kfpri;
    local float speedBonusScale;

    super(KFPawn).ModifyVelocity(DeltaTime, OldVelocity);

    if (Controller != none) {
        speedBonusScale= fmin((Level.TimeSeconds - speedPenaltyStartTime)/maxSpeedPenaltyTime, 1.0);
        EncumbrancePercentage = (FMin(CurrentWeight, MaxCarryWeight)/MaxCarryWeight);
        WeightMod = (1.0 - (EncumbrancePercentage * WeightSpeedModifier));
        HealthMod = ((Health/HealthMax) * HealthSpeedModifier) + (1.0 - HealthSpeedModifier);

        // Apply all the modifiers
        GroundSpeed = default.GroundSpeed * HealthMod;
        GroundSpeed *= WeightMod;
        GroundSpeed += InventorySpeedModifier * speedBonusScale;

        kfpri= KFPlayerReplicationInfo(PlayerReplicationInfo);
        if (kfpri != none && kfpri.ClientVeteranSkill != none ) {
            // GetMovementSpeedModifier returns a multiplier >= 1.0
            GroundSpeed*= (kfpri.ClientVeteranSkill.static.GetMovementSpeedModifier(kfpri, 
                    KFGameReplicationInfo(Level.GRI)) - 1 ) * speedBonusScale + 1;
        }
    }
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, 
        class<DamageType> damageType, optional int HitIdx ) {
    if (class<DamTypeCrawlerPoison>(damageType) != none) {
        speedPenaltyStartTime= Level.TimeSeconds;
    } else if (bleedCount <= 0 && class<DamTypeBleed>(damageType) != none) {
        nextBleedTime= Level.TimeSeconds + bleedPeriod;
        bleedInstigator= instigatedBy;
        bleedCount= maxBleedCount;
    }
    super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType, HitIdx);
}

defaultproperties {
    maxSpeedPenaltyTime= 10
    maxBleedCount= 5;
    bleedPeriod= 2;
}
