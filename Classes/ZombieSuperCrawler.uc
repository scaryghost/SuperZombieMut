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

defaultproperties {
    MenuName="Super Crawler"
    GroundSpeed= 190.00000
    WaterSpeed= 175.00000
    ZombieDamType(0)=Class'SuperZombieMut.DamTypeCrawlerPoison'
    ZombieDamType(1)=Class'SuperZombieMut.DamTypeCrawlerPoison'
    ZombieDamType(2)=Class'SuperZombieMut.DamTypeCrawlerPoison'
}
