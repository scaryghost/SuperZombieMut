class ZombieSuperHusk extends ZombieHusk_STANDARD;

/**
 *  consecutiveShots            How many consecutive shots the Super Husk has taken
 *  maxConsecutiveShots         Max consecutive shots the Super Husk can take before the cool down timer kicks in
 */
var int consecutiveShots, maxConsecutiveShots;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    maxConsecutiveShots= Rand(5)+1;
}

function SpawnTwoShots() {
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;
    local KFMonsterController KFMonstControl;

    if( Controller!=None && KFDoorMover(Controller.Target)!=None ) {
        Controller.Target.TakeDamage(22,Self,Location,vect(0,0,0),Class'DamTypeVomit');
        return;
    }

    GetAxes(Rotation,X,Y,Z);
    FireStart = GetBoneCoords('Barrel').Origin;
    if ( !SavedFireProperties.bInitialized ) {
        SavedFireProperties.AmmoClass = Class'SkaarjAmmo';
        SavedFireProperties.ProjectileClass = Class'HuskFireProjectile_SZ';
        SavedFireProperties.WarnTargetPct = 1;
        SavedFireProperties.MaxRange = 65535;
        SavedFireProperties.bTossed = False;
        SavedFireProperties.bTrySplash = true;
        SavedFireProperties.bLeadTarget = True;
        SavedFireProperties.bInstantHit = False;
        SavedFireProperties.bInitialized = True;
    }

    // Turn off extra collision before spawning vomit, otherwise spawn fails
    ToggleAuxCollision(false);

    FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,600);

    foreach DynamicActors(class'KFMonsterController', KFMonstControl) {
        if( KFMonstControl != Controller ) {
            if( PointDistToLine(KFMonstControl.Pawn.Location, vector(FireRotation), FireStart) < 75 ) {
                KFMonstControl.GetOutOfTheWayOfShot(vector(FireRotation),FireStart);
            }
        }
    }

    Spawn(Class'HuskFireProjectile_SZ',Self,,FireStart,FireRotation);

    // Turn extra collision back on
    ToggleAuxCollision(true);
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
    ControllerClass=Class'SuperHuskZombieController'
    MenuName= "Super Husk"
}
