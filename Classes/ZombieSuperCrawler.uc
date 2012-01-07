class ZombieSuperCrawler extends ZombieCrawler;

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
    if(bPouncing && KFHumanPawn(Other)!=none ) {
        KFHumanPawn(Other).TakeDamage(((MeleeDamage - (MeleeDamage * 0.05)) + (MeleeDamage * (FRand() * 0.1))), 
                self ,self.Location,self.velocity, Class'SuperZombieMut.DamTypeCrawlerPoison');
        if (KFHumanPawn(Other).Health <=0) {
            KFHumanPawn(Other).SpawnGibs(self.rotation, 1);
        }
        bPouncing=false;
    }
}

defaultproperties {
    MenuName="Super Crawler"
    GroundSpeed= 190.00000
    WaterSpeed= 175.00000
    ZombieDamType(0)=Class'SuperZombieMut.DamTypeCrawlerPoison'
    ZombieDamType(1)=Class'SuperZombieMut.DamTypeCrawlerPoison'
    ZombieDamType(2)=Class'SuperZombieMut.DamTypeCrawlerPoison'
}
