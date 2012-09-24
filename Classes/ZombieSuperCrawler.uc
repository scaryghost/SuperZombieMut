class ZombieSuperCrawler extends ZombieCrawler;

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
        mut.PP.addPawn(KFHumanPawn(Other));
    }
    super.Bump(Other);
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
    local bool result;

    result= super.MeleeDamageTarget(hitdamage, pushdir);
    if (result && KFHumanPawn(Controller.Target) != none) {
        mut.PP.addPawn(KFHumanPawn(Controller.Target));
    }
    return result;
}
defaultproperties {
    MenuName="Super Crawler"
    GroundSpeed= 190.00000
    WaterSpeed= 175.00000
}
