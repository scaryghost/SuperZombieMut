class ZombieSuperBoss extends ZombieBoss_STANDARD;

/** Minimum damage the patriarch will take before charging any players within 700uu */
var int ChargeDamageThreshold;

/** True if the pariarch just spawned.  The flag will prevent the patriarch from attacking pipe bombs during the intro scene  */
var bool bJustSpawned;

/**
 *  spawnTimer                  track how long the patriarch has spawned
 *  attackPipeCoolDown          cool down timer so the patriarch will not shoot another 
 *                              pile of pipes until his first rocket as exploded
 *  LastDamageTime2             Serves the same function as LastDamageTime.  Old usage was flawed and would never work
 *  ChargeDamage2               Serves the same function as ChargeDamage.  Old usage was flawed and never work
 */
var float spawnTimer, attackPipeCoolDown, LastDamageTime2, ChargeDamage2;

/**
 *  Give the patriarch more to do during each tick
 */
simulated function Tick(float DeltaTime) {
    local PipeBombProjectile checkProjectile;
    local PipeBombProjectile lastProjectile;
    local KFHumanPawn checkHP, lastHP;
    local int pipeCount,playerCount;
    local bool bBaseState;

    bBaseState= isInState('ZombieSuperBoss');

    super.Tick(DeltaTime);

    /**
     *  If the patriarch has finished his introduction, the pipe bomb cooldown timer has expire 
     *  and is in the base state, checking if a pipe bomb pile is visible
     */
    if(!bJustSpawned && attackPipeCoolDown <= 0.0 && bBaseState) {
        //Count how many pipe bombs are visible
        foreach VisibleActors(class'PipeBombProjectile', checkProjectile) {
            pipeCount++;
            lastProjectile= checkProjectile;
        }
        if(pipeCount >= 2) {
            //Count how many players are visible within its blast radius
            foreach lastProjectile.VisibleActors(class'KFHumanPawn', checkHP) {
                playerCount++;
                lastHP= checkHP;
            }
            if (playerCount == 0 || VSize(lastHP.Location - lastProjectile.Location) <= class'BossLAWProj'.default.DamageRadius) {
                Controller.Target= lastProjectile;
                Controller.Focus= lastProjectile;
                GotoState('AttackPipes');
                /**
                 *  Calculate how long the LAW rocket will travel so the patriarch doesn't fire another one 
                 *  at the same pile until the first one detonates
                 */
                attackPipeCoolDown= VSize(Location - lastProjectile.Location)/(class'BossLAWProj'.default.MaxSpeed)+GetAnimDuration('PreFireMissile');
            } else {
                SetAnimAction('transition');
                LastForceChargeTime = Level.TimeSeconds;
                GoToState('ChargePipes');
            }
        }
    }
    spawnTimer+= DeltaTime;
    attackPipeCoolDown= FMax(0,attackPipeCoolDown-DeltaTime);
    bJustSpawned= (spawnTimer <= GetAnimDuration('Entrance'));
}

/** Temp state for when the Patriarch attacks a pipe pile */ 
state AttackPipes {
Ignores RangedAttack;

    function BeginState() {
        bShotAnim = true;
        Acceleration = vect(0,0,0);
        SetAnimAction('PreFireMissile');
        HandleWaitForAnim('PreFireMissile');
        GoToState('FireMissile');
    }
}

state Charging {
    function BeginState() {
        super.BeginState();
        //Randomly make the patriach want to land 2 consecutive melee strikes
        NumChargeAttacks= 1 + round(FRand());
    }

    function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
        local bool RetVal;
        RetVal= Global.MeleeDamageTarget(hitdamage, pushdir*1.5);

        //only subtract is the target was hit
        if (RetVal)
            NumChargeAttacks--;
        return RetVal;
    }
}

/** State to have the patriarch charge right through the pipe bombs. */
state ChargePipes extends Charging {
    function RangedAttack(Actor A) {
        if( VSize(A.Location-Location)>700 && Level.TimeSeconds - LastForceChargeTime > 3.0 )
            GoToState('');
        if ( bShotAnim )
            return;
        else if ( IsCloseEnuf(A) )
        {
            if( bCloaked )
                UnCloakBoss();
            bShotAnim = true;
            Acceleration = vect(0,0,0);
            Acceleration = (A.Location-Location);
            SetAnimAction('MeleeClaw');
            //PlaySound(sound'Claw2s', SLOT_None); Claw2s
        }
    }
}

/** Allow the patriarch to automatically destroy any welded door in his path */
State Escaping { 
    function DoorAttack(Actor A) {
        local vector hitLocation;
        local vector momentum;

        if ( bShotAnim )
            return;
        else if ( KFDoorMover(A)!=None ) {
            hitLocation= vect(0.0,0.0,0.0);
            momentum= vect(0.0,0.0,0.0);
            KFDoorMover(A).Health= 0;
            KFDoorMover(A).GoBang(self,hitLocation,momentum,Class'BossLAWProj'.default.MyDamageType);
        }
    }
}

/** Slightly change the conditions for charging from damage */
function bool ShouldChargeFromDamage() {
    // If we don;t want to heal, charge whoever damaged us!!!
    if( (SyringeCount==0 && Health<HealingLevels[0]) || (SyringeCount==1 && Health<HealingLevels[1]) || (SyringeCount==2 && Health<HealingLevels[2])) {
        return false;
    }
    return !bChargingPlayer;
}

/** Give the patriarch new responses when he takes damage */
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex) {  
    local float DamagerDistSq;
    local float oldHealth;

    OldHealth= Health;
    Super.TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);

    /**
     *  Reset the charge accumulator if 10 seconds have passed since the patriarch last took damage.  
     *  Old Patriarch code had this wrong and never incremented the accumulator
     */
    if( LastDamageTime2 != 0.0 && Level.TimeSeconds - LastDamageTime2 > 10 ) {
        ChargeDamage2 = 0;
    }
     
    ChargeDamage2 += (OldHealth-Health);
    LastDamageTime2 = Level.TimeSeconds;
    if (ShouldChargeFromDamage() && ChargeDamage2 > ChargeDamageThreshold ) {
        if (InstigatedBy != none) {
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
            if (DamagerDistSq < (700 * 700)) {
                ChargeDamage2= 0;
                LastForceChargeTime = Level.TimeSeconds;
                GoToState('Charging');
                return;
            }
        }
    }
}

function RangedAttack(Actor A) {
    local float D;
    local bool bOnlyE;
    local bool bDesireChainGun;

    // Randomly make him want to chaingun more
    if (Controller.LineOfSightTo(A) && FRand() < 0.15 && LastChainGunTime<Level.TimeSeconds) {
        bDesireChainGun = true;
    }

    if ( bShotAnim )
        return;
    D = VSize(A.Location-Location);
    bOnlyE = (Pawn(A)!=None && OnlyEnemyAround(Pawn(A)));
    if (IsCloseEnuf(A)) {
        bShotAnim = true;
        if (Health > 1500 && Pawn(A) != None && FRand() < 0.5) {
            SetAnimAction('MeleeImpale');
        }
        else {
            SetAnimAction('MeleeClaw');
            //PlaySound(sound'Claw2s', SLOT_None); KFTODO: Replace this
        }
    }
    else if (Level.TimeSeconds - LastSneakedTime > 15.0) {  //SZ: Reduce min sneak time interval to 15s
        if (FRand() < 0.3) {
            // Wait another 20 to try this again
            LastSneakedTime = Level.TimeSeconds;//+FRand()*120;
            Return;
        }
        SetAnimAction('transition');
        GoToState('SneakAround');
    }
    else if (bChargingPlayer && (bOnlyE || D<200))
        Return;
    else if (!bDesireChainGun && !bChargingPlayer && (D<300 || (D<700 && bOnlyE)) &&
        (Level.TimeSeconds - LastChargeTime > (5.0 + 2.0 * FRand())) ) {    //SZ: Reduce min charge interval to [5,7] seconds
        SetAnimAction('transition');
        GoToState('Charging');
    }
    else if (LastMissileTime < Level.TimeSeconds && D > 500) {
        if (!Controller.LineOfSightTo(A) || FRand() > 0.75) {
            LastMissileTime = Level.TimeSeconds+FRand() * 5;
            Return;
        }

        LastMissileTime = Level.TimeSeconds + 10 + FRand() * 5; //SZ: Reduce min missile interval to [10,15] seconds

        bShotAnim = true;
        Acceleration = vect(0,0,0);
        SetAnimAction('PreFireMissile');

        HandleWaitForAnim('PreFireMissile');

        GoToState('FireMissile');
    }
    else if (!bWaitForAnim && !bShotAnim && LastChainGunTime<Level.TimeSeconds) {
        if (!Controller.LineOfSightTo(A) || FRand()> 0.85) {
            LastChainGunTime = Level.TimeSeconds+FRand()*4;
            Return;
        }

        LastChainGunTime = Level.TimeSeconds + 5 + FRand() * 5; //SZ: Reduce min chaingun interval to [5,10] seconds

        bShotAnim = true;
        Acceleration = vect(0,0,0);
        SetAnimAction('PreFireMG');

        HandleWaitForAnim('PreFireMG');
        MGFireCounter =  Rand(60) + 35;

        GoToState('FireChaingun');
    }
} 

defaultproperties {
    MenuName= "Super Patriarch"
    ChargeDamageThreshold= 1000;
    bJustSpawned= true;
    ControllerClass=class'ZombieSuperBossController'
    ImpaleMeleeDamageRange= 75;
}
