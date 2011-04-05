class ZombieSuperBoss extends ZombieBoss;

var int logLevel;
var int ChargeDamageThreshold;
var int minEnemiesClose;
var float pipebombDamageMult;
var bool bJustSpawned;
var float spawnTimer, attackPipeCoolDown;
var float minPipeDistance;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    logToPlayer(1,"What have you done to my experiments?! Rawr!");
    ChargeDamageThreshold= 1000;
    bJustSpawned= true;
    spawnTimer= 0.0;
}

simulated function Tick(float DeltaTime) {
    local Projectile CheckProjectile;
    local Projectile LastProjectile;
    local int count;

    super.Tick(DeltaTime);

    if(!bJustSpawned && attackPipeCoolDown <= 0.0 && isInState('ZombieSuperBoss')) {
        count= 0;
        foreach VisibleCollidingActors( class 'Projectile', CheckProjectile, minPipeDistance, Location ) {
            if( PipeBombProjectile(CheckProjectile) != none ) {
                count++;
            }
            LastProjectile= CheckProjectile;
        }
        if(count >= 2) {
            Controller.Target= LastProjectile;
            Controller.Focus= LastProjectile;
            GotoState('AttackPipes');
            attackPipeCoolDown= minPipeDistance/(class'BossLAWProj'.default.MaxSpeed)+GetAnimDuration('PreFireMissile');
        }
        LogToPlayer(2,"Num of pipebombs: "$count);
    }
    spawnTimer+= DeltaTime;
    attackPipeCoolDown= FMax(0,attackPipeCoolDown-DeltaTime);
    bJustSpawned= (spawnTimer <= GetAnimDuration('Entrance')+3.0);
}


function int numEnemiesAround(float minDist) {
    local Controller C;
    local int count;

    count= 0;
    For( C=Level.ControllerList; C!=None; C=C.NextController ) {
        if( C.bIsPlayer && C.Pawn!=None && VSize(C.Pawn.Location-Location)<=minDist && 
            FastTrace(C.Pawn.Location,Location) && C.Pawn.Weapon != None && C.Pawn.Weapon.bMeleeWeapon) {
            count++;
        }
    }
    return count;
}

function logToPlayer(int level, string msg) {
    isItMyLogLevel(level) && outputToChat(msg);
}

function bool outputToChat(string msg) {
    local Controller C;

    for (C = Level.ControllerList; C != None; C = C.NextController) {
        if (PlayerController(C) != None) {
            PlayerController(C).ClientMessage(msg);
        }
    }

    return true;
}

function bool isItMyLogLevel(int level) {
    return (logLevel >= level);
}

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

State Escaping { // Got hurt and running away...
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
            logToPlayer(2,"Not stopping to bust a door down");
        }
    }

    function BeginHealing() {
        super.BeginHealing();
    }

    function RangedAttack(Actor A) {
        super.RangedAttack(A);
    }

    function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
        return super.MeleeDamageTarget(hitdamage, pushdir);
    }

    function Tick( float Delta ) {
        // Keep the flesh pound moving toward its target when attacking
        if( Role == ROLE_Authority && bShotAnim) {
            if( bChargingPlayer ) {
                bChargingPlayer = false;
                if( Level.NetMode!=NM_DedicatedServer )
                    PostNetReceive();
            }
            GroundSpeed = OriginalGroundSpeed * 1.25;
            if( ChargeDamage > ChargeDamageThreshold && LookTarget!=None ) {
                Acceleration = AccelRate * Normal(LookTarget.Location - Location);
            }
        }
        else {
            if( !bChargingPlayer ) {
                bChargingPlayer = true;
                if( Level.NetMode!=NM_DedicatedServer )
                    PostNetReceive();
            }

            GroundSpeed = OriginalGroundSpeed * 2.5;
        }
        Global.Tick(Delta);
    }

    function BeginState() {
        super.BeginState();
    }

    function EndState() {
        super.EndState();
    }

Begin:
    While( true ) {
        Sleep(0.5);
        if( !bCloaked && !bShotAnim )
            CloakBoss();
        if( !Controller.IsInState('SyrRetreat') && !Controller.IsInState('WaitForAnim'))
            Controller.GoToState('SyrRetreat');
    }
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex) {  
    local float DamagerDistSq;
    local float UsedPipeBombDamScale;
    local int numEnemies, oldHealth; 
    local vector Start;
    local Rotator R;

    if(ZombieSuperBoss(InstigatedBy) != none || InstigatedBy == none) {
        LogToPlayer(2,"I hurt myself!");
        return;
    }

    logToPlayer(3,"InstigatedBy: "$InstigatedBy);

    if ( class<DamTypeCrossbow>(damageType) == none && class<DamTypeCrossbowHeadShot>(damageType) == none ) {
        bOnlyDamagedByCrossbow = false;
    }

    // Scale damage from the pipebomb down a bit if lots of pipe bomb damage happens
    // at around the same times. Prevent players from putting all thier pipe bombs
    // in one place and owning the patriarch in one blow.
    if ( class<DamTypePipeBomb>(damageType) != none ) {
       UsedPipeBombDamScale = FMax(0,(1.0 - PipeBombDamageScale));

       PipeBombDamageScale += pipebombDamageMult;

       if( PipeBombDamageScale > 1.0 ) {
           PipeBombDamageScale = 1.0;
       }

       Damage *= UsedPipeBombDamScale;
    }

    OldHealth= Health;
    Super(KFMonster).TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);

    if( LastDamageTime != 0.0 && Level.TimeSeconds - LastDamageTime > 10 ) {
        ChargeDamage = 0;
    }
     
    ChargeDamage += (OldHealth-Health);

    LastDamageTime = Level.TimeSeconds;
    LogToPlayer(3,"Charge Damage: "$ChargeDamage);
    LogToPlayer(3,"Last Damage Time: "$LastDamageTime);
    LogToPlayer(3,"Level.TimeSeconds: "$Level.TimeSeconds);
    if( ShouldChargeFromDamage() && ChargeDamage > ChargeDamageThreshold ) {
        // If someone close up is shooting us, just charge them
        if( InstigatedBy != none ) {
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);

            if( DamagerDistSq < (700 * 700) ) {
                SetAnimAction('transition');
                ChargeDamage=0;
                LastForceChargeTime = Level.TimeSeconds;
                GoToState('Charging');
                return;
            }
        }
    }

    if( Health<=0 || SyringeCount==3 || IsInState('Escaping') || IsInState('KnockDown') /*|| bShotAnim*/ )
        Return;

    if( (SyringeCount==0 && Health<HealingLevels[0]) || (SyringeCount==1 && Health<HealingLevels[1]) || (SyringeCount==2 && Health<HealingLevels[2]) ) {

            bShotAnim = true;
            Acceleration = vect(0,0,0);
            SetAnimAction('KnockDown');
            HandleWaitForAnim('KnockDown');
            KFMonsterController(Controller).bUseFreezeHack = True;
            numEnemies= numEnemiesAround(150);

            if(numEnemies >= minEnemiesClose) {
                Start = GetBoneCoords('tip').Origin;
                R.Pitch= -16384;
                Spawn(Class'BossLAWProj',,,Start,R);
            }
            GoToState('KnockDown');
    }
} 

defaultproperties {
    logLevel= 0;
    MenuName= "Super Patriarch"
    minEnemiesClose= 3
    pipebombDamageMult= 0.075;
    minPipeDistance= 1500.0;
}
