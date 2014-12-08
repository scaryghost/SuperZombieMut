/**
 * @deprecated As of v2.3.2, poison code moved to SZReplicationInfo
 */
class PoisonedPawns extends Info;

struct PoisonedPawn {
    var KFHumanPawn P;
    var SZReplicationInfo szRI;
    var float startTime;
};

var float maxSpeedPenaltyTime;
var array<PoisonedPawn> pawns;

function tick(float DeltaTime) {
    local KFPlayerReplicationInfo kfpri;
    local float EncumbrancePercentage, speedBonusScale, WeightMod, HealthMod;
    local int i, end;

    end= pawns.Length;
    while(i < end) {
        speedBonusScale= fmin((Level.TimeSeconds - pawns[i].startTime)/maxSpeedPenaltyTime, 1.0);
        if (pawns[i].P == none || pawns[i].P.Health <= 0 || speedBonusScale >= 1) {
            if (pawns[i].szRI != none) {
                pawns[i].szRI.isPoisoned= false;
            }
            pawns.remove(i, 1);
            end--;
        } else {
            EncumbrancePercentage = (FMin(pawns[i].P.CurrentWeight, pawns[i].P.MaxCarryWeight)/pawns[i].P.MaxCarryWeight);
            WeightMod = (1.0 - (EncumbrancePercentage * pawns[i].P.WeightSpeedModifier));
            HealthMod = ((pawns[i].P.Health/pawns[i].P.HealthMax) * pawns[i].P.HealthSpeedModifier) + (1.0 - pawns[i].P.HealthSpeedModifier);

            // Apply all the modifiers
            pawns[i].P.GroundSpeed = class'KFHumanPawn'.default.GroundSpeed * HealthMod;
            pawns[i].P.GroundSpeed *= WeightMod;
            pawns[i].P.GroundSpeed += pawns[i].P.InventorySpeedModifier * speedBonusScale;

            kfpri= KFPlayerReplicationInfo(pawns[i].P.PlayerReplicationInfo);
            if (kfpri != none && kfpri.ClientVeteranSkill != none ) {
                // GetMovementSpeedModifier returns a multiplier >= 1.0
                pawns[i].P.GroundSpeed*= (kfpri.ClientVeteranSkill.static.GetMovementSpeedModifier(kfpri, 
                        KFGameReplicationInfo(Level.GRI)) - 1 ) * speedBonusScale + 1;
            }
            i++;
        }
    }
}

function addPawn(KFHumanPawn P) {
    local int i;
    
    for(i= 0; i < pawns.Length; i++) {
        if (pawns[i].P == P) {
            pawns[i].startTime= Level.TimeSeconds;
            return;
        }
    }
    pawns.Length= pawns.Length + 1;
    pawns[pawns.Length - 1].P= P;
    pawns[pawns.Length - 1].startTime= Level.TimeSeconds;
    pawns[pawns.Length - 1].szRI= class'SZReplicationInfo'.static.findSZri(P.PlayerReplicationInfo);
    if (pawns[pawns.Length - 1].szRI != none) {
        pawns[pawns.Length - 1].szRI.isPoisoned= true;
    }
}

defaultproperties {
    maxSpeedPenaltyTime= 10
}
