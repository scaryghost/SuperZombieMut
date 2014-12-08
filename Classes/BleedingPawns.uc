/**
 * @deprecated As of v2.3.2, bleeding code moved to SZReplicationInfo
 */
class BleedingPawns extends Info;

struct BleedingPawn {
    var KFHumanPawn P;
    var SZReplicationInfo szRI;
    var float nextBleedTime;
    var Pawn instigator;
    var int bleedCount;
};

var float bleedPeriod;
var int maxBleedCount;
var array<BleedingPawn> pawns;

function Tick(float DeltaTime) {
    local int i;
    local int end;

    end= pawns.Length;
    while(i < end) {
        if (pawns[i].P != none && pawns[i].P.Health > 0 && pawns[i].bleedCount > 0) {
            if (pawns[i].nextBleedTime < Level.TimeSeconds) {
                pawns[i].bleedCount--;
                pawns[i].nextBleedTime+= bleedPeriod;
                pawns[i].P.TakeDamage(2 + rand(1), pawns[i].instigator, pawns[i].P.Location, vect(0, 0, 0), class'DamTypeStalkerBleed');
                pawns[i].P.healthToGive-= 5;
            }
            i++;
        } else {
            if (pawns[i].szRI != none) {
                pawns[i].szRI.isBleeding= false;
            }
            pawns.remove(i, 1);
            end--;
        }
    }
}

function addPawn(KFHumanPawn P, Pawn instigator) {
    local int i;
    
    for(i= 0; i < pawns.Length; i++) {
        if (pawns[i].P == P) {
            pawns[i].bleedCount= maxBleedCount;
            pawns[i].instigator= instigator;
            return;
        }
    }

    pawns.Length= pawns.Length + 1;
    pawns[pawns.Length - 1].P= P;
    pawns[pawns.Length - 1].nextBleedTime= Level.TimeSeconds;
    pawns[pawns.Length - 1].instigator= instigator;
    pawns[pawns.Length - 1].bleedCount= maxBleedCount;
    pawns[pawns.Length - 1].szRI= class'SZReplicationInfo'.static.findSZri(P.PlayerReplicationInfo);
    if (pawns[pawns.Length - 1].szRI != none) {
        pawns[pawns.Length - 1].szRI.isBleeding= true;
    }
}

defaultproperties {
    maxBleedCount= 7;
    bleedPeriod= 1.5;
}
