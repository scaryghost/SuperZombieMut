class ZombieSuperBoss extends ZombieBoss;

/** Minimum damage the patriarch will take before charging any players within 700uu */
var int ChargeDamageThreshold;

/** True if the pariarch just spawned.  The flag will prevent the patriarch from attacking pipe bombs during the intro scene  */
var bool bJustSpawned;

/**
 *  spawnTimer                  track how long the patriarch has spawned
 *  attackPipeCoolDown          cool down timer so the patriarch will not shoot another 
 *                              pile of pipes until his first rocket as exploded
 *  minPipeDistance             minimum distance that will trigger the patriarch's anti-pipebomb attack
 *  LastDamageTime2             Serves the same function as LastDamageTime.  Old usage was flawed and would never work
 *  ChargeDamage2               Serves the same function as ChargeDamage.  Old usage was flawed and never work
 */
var float spawnTimer, attackPipeCoolDown, minPipeDistance, LastDamageTime2, ChargeDamage2;

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
            /**
             *  Calculate how long the LAW rocket will travel so the patriarch doesn't fire another one 
             *  at the same pile until the first one detonates
             */
            attackPipeCoolDown= minPipeDistance/(class'BossLAWProj'.default.MaxSpeed)+GetAnimDuration('PreFireMissile');
        }
    }
    spawnTimer+= DeltaTime;
    attackPipeCoolDown= FMax(0,attackPipeCoolDown-DeltaTime);
    bJustSpawned= (spawnTimer <= GetAnimDuration('Entrance'));
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
        // Make the patriarch charge more often if there are more players
        NumChargeAttacks = Rand(Level.Game.NumPlayers)+1;
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

defaultproperties {
    MenuName= "Super Patriarch"
    minPipeDistance= 1250.0;
    ChargeDamageThreshold= 1000;
    bJustSpawned= true;
    spawnTimer= 0.0;
}
