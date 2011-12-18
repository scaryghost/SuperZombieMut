class ZombieSuperBoss extends ZombieBoss;

/**
 *  Struct to store how many times each player hit the patriarch
 */
struct damHitTracker {
    var Pawn instigator;
    var array<float> deltaTimes;
    var float firstTimeHit;
};

/**
 *  ChargeDamageThreshold       minimum damage the patriarch will take before charging any players within 700uu
 *  minEnemiesClose             minimum number of enemies close to the patriarch that will trigger the AOE kneel
 */
var int ChargeDamageThreshold, minEnemiesClose;

/**
 *  bJustSpawned                true if the pariarch just spawned.  The flag will prevent the patriarch from destroying 
 *                              pipe bombs during his introduction scene
 */
var bool bJustSpawned;

/**
 *  spawnTimer                  track how long the patriarch has spawned
 *  attackPipeCoolDown          cool down timer so the patriarch will not shoot another 
 *                              pile of pipes until his first rocket as exploded
 *  pipebombDamageMult          the pipe bomb scaling used to reduce pipe damage to the patriarch
 *  minPipeDistance             minimum distance that will trigger the patriarch's anti-pipebomb attack
 */
var float spawnTimer, attackPipeCoolDown, pipebombDamageMult, minPipeDistance, LastDamageTime2, ChargeDamage2;

/**
 *  hsDamHistList               stores everyone who attacked the patriarch with hunting shotguns
 */
var array<damHitTracker> hsDamHitList;


/**
 *  Give the patriarch more to do during each tick
 */
simulated function Tick(float DeltaTime) {
    local PipeBombProjectile CheckProjectile;
    local PipeBombProjectile LastProjectile;
    local SZHumanPawn CheckHP;
    local int pipeCount,playerCount;
    local bool bBaseState;

    bBaseState= isInState('ZombieSuperBoss');

    super.Tick(DeltaTime);

    /**
     *  If the patriarch has finished his introduction, the pipe bomb cooldown timer has expire 
     *  and is in the base state, checking if a pipe bomb pile is visible
     */
    if(!bJustSpawned && attackPipeCoolDown <= 0.0 && bBaseState) {
        pipeCount= 0;
        playerCount= 0;
        /**
         *  Count how many pipe bombs are visible within a radius
         */
        foreach VisibleCollidingActors( class 'PipeBombProjectile', CheckProjectile, minPipeDistance, Location ) {
            pipeCount++;
            LastProjectile= CheckProjectile;
        }
        if(pipeCount >= 2) {
            /**
             *  Count how many players are visible within twice the radius
             */
            foreach VisibleCollidingActors( class 'SZHumanPawn', CheckHP, minPipeDistance*2, Location ) {
                playerCount++;
            }
        }

        /**
         *  If the visible number of pipes is <= 2 and there are visible players near it, 
         *  charge through the pipes.  Otherwise, if the pipe count is >=2, just shoot it
         */
        if(pipeCount <= 2 && PlayerCount != 0) {
            SetAnimAction('transition');
            LastForceChargeTime = Level.TimeSeconds;
            GoToState('ChargePipes');
        } else if(pipeCount >= 2) {
            Controller.Target= LastProjectile;
            Controller.Focus= LastProjectile;
            GotoState('AttackPipes');
            //Calculate how long the LAW rocket will travel so the patriarch doesn't fire another one 
            //at the samep pile until the first one detonates
            attackPipeCoolDown= minPipeDistance/(class'BossLAWProj'.default.MaxSpeed)+GetAnimDuration('PreFireMissile');
        }
    }
    spawnTimer+= DeltaTime;
    attackPipeCoolDown= FMax(0,attackPipeCoolDown-DeltaTime);
    bJustSpawned= (spawnTimer <= GetAnimDuration('Entrance'));
}

/**
 *  Output a message to all players
 */
function bool outputToChat(string msg) {
    local Controller C;

    for (C = Level.ControllerList; C != None; C = C.NextController) {
        if (PlayerController(C) != None) {
            PlayerController(C).ClientMessage(msg);
        }
    }

    return true;
}

/**
 *  Calculates how many enemies are within a certain distance of the patriarch.
 *  Distance is given in the function parameter.
 */
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

/**
 *  Temp state for when the Patriarch attacks a pipe pile
 */ 
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
        /**
         * Make the patriarch charge more often if there are more players
         */
        NumChargeAttacks = Rand(Level.Game.NumPlayers)+1;
    }
}

/**
 * Moved the AOE kneel to the extended KnockDown state
 */
state KnockDown {
    function BeginState() {
        local int numEnemies;
        local vector Start;
        local Rotator R;

        super.BeginState();

        numEnemies= numEnemiesAround(150);

        /**
         *  If the patriarch is surrounded by enemies with melee weapons, do the AOE kneel to hurt them
         */
        if(numEnemies >= minEnemiesClose) {
            outputToChat("Learn how to do something other than lumberjack gang-bang you noobs.");
            Start = GetBoneCoords('tip').Origin;
            R.Pitch= -16384;
            Spawn(Class'BossLAWProj',,,Start,R);
        }

    }
}

/**
 *  State to have the patriarch charge right through the pipe bombs.
 */
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

/**
 *  Allow the patriarch to automatically destroy any welded door in his path
 */
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

/**
 *  Give the patriarch new responses when he takes damage
 */
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex) {  
    local float DamagerDistSq;
    local float oldHealth;

    //If the patriarch was hit with the hunting shotgun, update the list and see if anyone was cheating
    if(class<DamTypeDBShotgun>(damageType) != none && updateHsDamHitList(InstigatedBy)) {
        Controller.Target= InstigatedBy;
        Controller.Focus= InstigatedBy;
        GotoState('KillCheater');
        return;
    }


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
    if( ShouldChargeFromDamage() && ChargeDamage2 > ChargeDamageThreshold ) {
        if( InstigatedBy != none ) {
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
            if( DamagerDistSq < (700 * 700) ) {
                SetAnimAction('transition');
                ChargeDamage2=0;
                LastForceChargeTime = Level.TimeSeconds;
                GoToState('Charging');
                return;
            }
        }
    }
} 

/**
 *  Update the list of people who have hit the patriarch with the hunting shotgun
 */
function bool updateHsDamHitList(pawn Instigator) {
    local int i;
    local bool bFound;
    local float deltaTime;
    local int len;

    bFound= false;
    for(i=0; i< hsDamHitList.length; i++) {
        len= hsDamHitList[i].deltaTimes.length;
        if(hsDamHitList[i].instigator == Instigator) {
            deltaTime= Level.TimeSeconds - hsDamHitList[i].firstTimeHit;
            if(deltaTime >= 1.0) {
                if(hsDamHitList[i].deltaTimes.length >= 3) {
                    return true;
                }
                hsDamHitList[i].deltaTimes.length= 1;
                hsDamHitList[i].deltaTimes[0]= Level.TimeSeconds;
                hsDamHitList[i].firstTimeHit= Level.TimeSeconds;
            } else if(Level.TimeSeconds-hsDamHitList[i].deltaTimes[len-1] >= 0.25) {
                hsDamHitList[i].deltaTimes[len]= Level.TimeSeconds;
            }
            bFound= true;
            break;
        }
    }
    if(!bFound) {
        hsDamHitList.length= hsDamHitList.length+1;
        hsDamHitList[hsDamHitList.length-1].instigator= Instigator;
        hsDamHitList[hsDamHitList.length-1].deltaTimes[0]= Level.TimeSeconds;
        hsDamHitList[hsDamHitList.length-1].firstTimeHit= Level.TimeSeconds;
    }
    return false;
}

/**
 *  If the super Patriarch has detected someone using the auto HSG glitch,
 *  run over to him and 1 shot him.
 */
state KillCheater extends ChargePipes {
Ignores TakeDamage;   
    function BeginState() {
        super.BeginState();
        outputToChat("I shall smite those who use the hunting shotgun glitch");
    } 

    function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
        pushdir = Normal(Controller.Target.Location-Location)*1000000; // Fly bitch!
        if(Super.MeleeDamageTarget(100000, pushdir)) {
            GotoState('');
            return true;
        }
        return false;
    }

    function RangedAttack(Actor A) {
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
        }
    }

    function EndState() {
       super.EndState(); 
       outputToChat("ProTip: Get some skill you noob.");
    }
}

defaultproperties {
    MenuName= "Super Patriarch"
    minEnemiesClose= 3
    pipebombDamageMult= 0.075;
    minPipeDistance= 1250.0;
    ChargeDamageThreshold= 1000;
    bJustSpawned= true;
    spawnTimer= 0.0;
}
