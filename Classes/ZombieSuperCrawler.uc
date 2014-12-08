class ZombieSuperCrawler extends ZombieCrawler_STANDARD;

/** @deprecated as of v2.3.2 */
var SuperZombieMut mut;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    PounceSpeed= Rand(221)+330;
    MeleeRange= Rand(41)+50;
}

/**
 * Copied from ZombieCrawler.Bump() but changed damage type
 * to be the new poison damage type
 */
event Bump(actor Other) {
    if (bPouncing && KFHumanPawn(Other) != none) {
        class'SZReplicationInfo'.static
                .findSZri(KFHumanPawn(Other).PlayerReplicationInfo)
                .setPoison();
    }
    super.Bump(Other);
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
    local bool result;

    result= super.MeleeDamageTarget(hitdamage, pushdir);
    if (result && KFHumanPawn(Controller.Target) != none) {
        class'SZReplicationInfo'.static
                .findSZri(KFHumanPawn(Controller.Target).PlayerReplicationInfo)
                .setPoison();
    }
    return result;
}
defaultproperties {
    MenuName="Super Crawler"
    GroundSpeed= 190.00000
    WaterSpeed= 175.00000
}
