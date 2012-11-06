class BleedingPawns extends Info;

struct BleedingPawn {
    var KFHumanPawn P;
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
    local SZReplicationInfo szRI;

    end= pawns.Length;
    while(i < end) {
        if (pawns[i].P != none && pawns[i].bleedCount > 0) {
            if (pawns[i].nextBleedTime < Level.TimeSeconds) {
                pawns[i].bleedCount--;
                pawns[i].nextBleedTime+= bleedPeriod;
                pawns[i].P.TakeDamage(2 + rand(1), pawns[i].instigator, pawns[i].P.Location, vect(0, 0, 0), class'DamTypeSlashingAttack');
                pawns[i].P.healthToGive-= 5;
            }
            i++;
        } else {
            szRI= class'SZReplicationInfo'.static.findSZri(pawns[i].P.PlayerReplicationInfo);
            if (szRI != none) {
                szRI.isBleeding= false;
            }
            pawns.remove(i, 1);
            end--;
        }
    }
}

function addPawn(KFHumanPawn P, Pawn instigator) {
    local int i;
    local SZReplicationInfo szRI;
    
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

    szRI= class'SZReplicationInfo'.static.findSZri(P.PlayerReplicationInfo);
    if (szRI != none) {
        szRI.isBleeding= true;
    }
}

defaultproperties {
    maxBleedCount= 7;
    bleedPeriod= 1.5;
}
