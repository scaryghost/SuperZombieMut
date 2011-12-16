class ZombieSuperHusk extends ZombieHusk;

/**
 *  consecutiveShots            How many consecutive shots the Super Husk has taken
 *  maxConsecutiveShots         Max consecutive shots the Super Husk can take before the cool down timer kicks in
 */
var int consecutiveShots, maxConsecutiveShots;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    consecutiveShots= 0;
    maxConsecutiveShots= Rand(5)+1;
}

function RangedAttack(Actor A) {
    local int LastFireTime;

    if ( bShotAnim )
        return;

    if ( Physics == PHYS_Swimming ) {
        SetAnimAction('Claw');
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
    }
    else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius ) {
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
        SetAnimAction('Claw');
        //PlaySound(sound'Claw2s', SLOT_Interact); KFTODO: Replace this
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }
    else if ( (KFDoorMover(A) != none ||
        (!Region.Zone.bDistanceFog && VSize(A.Location-Location) <= 65535) ||
        (Region.Zone.bDistanceFog && VSizeSquared(A.Location-Location) < (Square(Region.Zone.DistanceFogEnd) * 0.8)))  // Make him come out of the fog a bit
        && !bDecapitated ) {
        bShotAnim = true;

        SetAnimAction('ShootBurns');
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);

        //Increment the number of consecutive shtos taken and apply the cool down if needed
        consecutiveShots++;
        if(consecutiveShots < maxConsecutiveShots) {
            NextFireProjectileTime= Level.TimeSeconds;
        } else {
            NextFireProjectileTime = Level.TimeSeconds + ProjectileFireInterval + (FRand() * 2.0);
            consecutiveShots= 0;
        }
    }
}

defaultproperties {
    ControllerClass=Class'SuperZombieMut.SuperHuskZombieController'
    MenuName= "Super Husk"
}
