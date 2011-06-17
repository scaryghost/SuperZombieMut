class ZombieSuperFP extends ZombieFleshPound;

var float rageDamage, rageDamageLimit, rageShield, rageShieldLimit;
var int totalDamageRageThreshold,totalRageAccumulator;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    rageDamageLimit= Max(35.0*1.75*DifficultyDamageModifer(),1.0);
    rageShieldLimit= Max(45.0*DifficultyDamageModifer(),1.0);
    rageDamage= 0.0;
    rageShield= 0.0;
}

simulated function Tick(float DeltaTime) {
    super.Tick(DeltaTime);
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex) {
    local int oldHealth;

    oldHealth= Health;
    super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, damageType, HitIndex);
    totalRageAccumulator+= (oldHealth - Health);

	if (!isInState('BeginRaging') && !bDecapitated && 
        totalRageAccumulator >= totalDamageRageThreshold && 
        !bChargingPlayer && (!(bCrispified && bBurnified) || bFrustrated) ) {
        totalRageAccumulator= 0;
        StartCharging();
    }
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
    local bool didIHit;
    
    didIHit= super.MeleeDamageTarget(hitdamage, pushdir);
    SuperFPZombieController(Controller).bMissTarget= 
        SuperFPZombieController(Controller).bMissTarget || !didIHit;
    return didIHit;
}

simulated event SetAnimAction(name NewAction) {
    super.SetAnimAction(newAction);
    SuperFPZombieController(Controller).bAttackedTarget= 
        (NewAction == 'Claw') || (NewAction == 'DoorBash');
}

state RageCharging {
//Not sure why we are Ignoring StartCharging()
//but best leave the code as is
Ignores StartCharging;

    function PlayDirectionalHit(Vector HitLoc) {
        super.PlayDirectionalHit(HitLoc);
    }

    function bool CanGetOutOfWay() {
        return super.CanGetOutOfWay();
    }

    // Don't override speed in this state
    function bool CanSpeedAdjust() {
        return super.CanSpeedAdjust();
    }

    function BeginState() {
        super.BeginState();
    }

    function EndState() {
        super.EndState();
    }

    function Tick( float Delta ) {
        super.Tick(Delta);
    }

    function Bump( Actor Other ) {
        super.Bump(Other);
    }

    // If fleshie hits his target on a charge, then he should settle down for abit.
    function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
        local bool RetVal,bWasEnemy;
        local float oldEnemyHealth, oldEnemyShield;
        local bool bAttackingHuman;

        bAttackingHuman= (KFHumanPawn(Controller.Target) != none);

        if (bAttackingHuman) {
            oldEnemyHealth= KFHumanPawn(Controller.Target).Health;
            oldEnemyShield= KFHumanPawn(Controller.Target).ShieldStrength;
        }

        bWasEnemy = (Controller.Target==Controller.Enemy);
        RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage*1.75, pushdir*3);

        if (bAttackingHuman) {
            rageDamage+= oldEnemyHealth - KFHumanPawn(Controller.Target).Health;
            rageShield+= oldEnemyShield - KFHumanPawn(Controller.Target).ShieldStrength;
        }

       
        if(RetVal && bWasEnemy) {
            if(bAttackingHuman && (oldEnemyShield <= 0.0 && rageDamage < rageDamageLimit || 
                (rageShield < rageShieldLimit && rageDamage < rageDamageLimit * 0.175))) {
                GotoState('RageAgain');
            } else {
                rageDamage= 0.0;
                rageShield= 0.0;
                GoToState('');
            }
        }

        return RetVal;
    }
}


//Had to add this temporary state because on local hosts, enraged fp attacks call
//MeleeDamageTarget twice.
state RageAgain {
    function BeginState() {
    }

    function EndState() {
    }

    function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
        local bool RetVal,bWasEnemy;
        local float oldEnemyHealth, oldEnemyShield;
        local bool bAttackingHuman;

        bAttackingHuman= (KFHumanPawn(Controller.Target) != none);

        if (bAttackingHuman) {
            oldEnemyHealth= KFHumanPawn(Controller.Target).Health;
            oldEnemyShield= KFHumanPawn(Controller.Target).ShieldStrength;
        }

        bWasEnemy = (Controller.Target==Controller.Enemy);
        RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage, pushdir*3);

        if (bAttackingHuman) {
            rageDamage+= oldEnemyHealth - KFHumanPawn(Controller.Target).Health;
            rageShield+= oldEnemyShield - KFHumanPawn(Controller.Target).ShieldStrength;
        }
       
        if(RetVal && bWasEnemy) {
            if(bAttackingHuman && (oldEnemyShield <= 0.0 && rageDamage < rageDamageLimit || 
                (rageShield < rageShieldLimit && rageDamage < rageDamageLimit * 0.175))) {
                StartCharging();
            } else {
                rageDamage= 0.0;
                rageShield= 0.0;
                GoToState('');
            }
        }

        return RetVal;
    }

Begin:
    if( Level.NetMode ==NM_DedicatedServer ) {
        StartCharging();
    }
}

defaultproperties {
    MenuName="Super FleshPound"
    ControllerClass=Class'SuperZombie.SuperFPZombieController'
    totalDamageRageThreshold= 1080
}

