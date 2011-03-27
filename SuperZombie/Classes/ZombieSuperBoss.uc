class ZombieSuperBoss extends ZombieBoss;

var int logLevel;

simulated function PostBeginPlay() {
    logToPlayer(1,"What have you done to my experiments?! Rawr!");
    super.PostBeginPlay();
}

simulated function Tick(float DeltaTime) {
    super.Tick(DeltaTime);
}


function int numEnemiesAround(float minDist) {
	local Controller C;
    local int count;

    count= 0;
	For( C=Level.ControllerList; C!=None; C=C.NextController ) {
		if( C.bIsPlayer && C.Pawn!=None && VSize(C.Pawn.Location-Location)<=minDist && FastTrace(C.Pawn.Location,Location)) {
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

state FireSuperMissile extends FireMissile {
Ignores RangedAttack;

    function bool ShouldChargeFromDamage() {
        return super.ShouldChargeFromDamage();
    }

	function BeginState() {
        super.BeginState();
	}

	function AnimEnd( int Channel )	{
        super.AnimEnd(Channel);
	}

    function EndState() {
        GotoState('Escaping');
    }
Begin:
	while ( true ) {
		Acceleration = vect(0,0,0);
		Sleep(0.1);
	}
}

State Escaping // Got hurt and running away...
{
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

	function BeginHealing()	{
        super.BeginHealing();
	}

	function RangedAttack(Actor A) {
        super.RangedAttack(A);
	}

	function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
        return super.MeleeDamageTarget(hitdamage, pushdir);
	}

	function Tick( float Delta ) {
        super.Tick(Delta);
    }

	function EndState()	{
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
    local int numEnemies; 

    logToPlayer(3,GetStateName()$"");

    if ( class<DamTypeCrossbow>(damageType) == none && class<DamTypeCrossbowHeadShot>(damageType) == none ) {
    	bOnlyDamagedByCrossbow = false;
    }

    // Scale damage from the pipebomb down a bit if lots of pipe bomb damage happens
    // at around the same times. Prevent players from putting all thier pipe bombs
    // in one place and owning the patriarch in one blow.
	if ( class<DamTypePipeBomb>(damageType) != none ) {
	   UsedPipeBombDamScale = FMax(0,(1.0 - PipeBombDamageScale));

	   PipeBombDamageScale += 0.075;

	   if( PipeBombDamageScale > 1.0 ) {
	       PipeBombDamageScale = 1.0;
	   }

	   Damage *= UsedPipeBombDamScale;
	}

    Super(KFMonster).TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);

    if( Level.TimeSeconds - LastDamageTime > 10 ) {
        ChargeDamage = 0;
    }
    else {
        LastDamageTime = Level.TimeSeconds;
        ChargeDamage += Damage;
    }

    if( ShouldChargeFromDamage() && ChargeDamage > 200 ) {
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

    numEnemies= numEnemiesAround(150);

	if( !IsInState('FireSuperMissile') && (SyringeCount==0 && Health<HealingLevels[0]) || (SyringeCount==1 && Health<HealingLevels[1]) || (SyringeCount==2 && Health<HealingLevels[2]) ) {
        if(numEnemies >= 3) {
            bShotAnim = true;
    		Acceleration = vect(0,0,0);
    		SetAnimAction('PreFireMissile');

    		HandleWaitForAnim('PreFireMissile');
            logToPlayer(2,"I'm not dropping to my knees.");

    		GoToState('FireSuperMissile');

        } else {
        	bShotAnim = true;
    		Acceleration = vect(0,0,0);
    		SetAnimAction('KnockDown');
    		HandleWaitForAnim('KnockDown');
    		KFMonsterController(Controller).bUseFreezeHack = True;
    		GoToState('KnockDown');
        }
	}
} 

defaultproperties {
    logLevel= 0;
    MenuName= "Super Patriarch"
}
