class SZHumanPawn extends KFHumanPawn;

var float maxSpeedPenaltyTime;
var float speedPenaltyStartTime;
var float prevSpeed;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    speedPenaltyStartTime= Level.TimeSeconds - maxSpeedPenaltyTime;
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
    local string speedMsg;

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
        if (prevSpeed != GroundSpeed) {
            speedMsg= chr(27)$chr(1)$chr(200)$chr(26)$"Ground speed: "$GroundSpeed;
            KFPC.ClientMessage(speedMsg);
            prevSpeed= GroundSpeed;
        }
    }
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, 
        class<DamageType> damageType, optional int HitIdx ) {
    if (damageType == class'SuperZombieMut.DamTypeCrawlerPoison') {
        speedPenaltyStartTime= Level.TimeSeconds;
    }
    super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType, HitIdx);
}

defaultproperties {
    maxSpeedPenaltyTime= 10
}
