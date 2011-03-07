class ZombieSuperBoss extends ZombieBoss;

var bool bShootRocket;
var bool bFiringSuperMissile;
var float rocketTimer;

simulated function PostBeginPlay() {
    logToPlayer("Super Boss spawning!");
    bShootRocket= false;
    bFiringSuperMissile= false;
//    rocketTimer= 0.0;
    super.PostBeginPlay();
}

simulated function Tick(float DeltaTime) {
    super.Tick(DeltaTime);
/*
    if(!bShootRocket) {
        rocketTimer+= DeltaTime;
    }
    if (rocketTimer > 3.0) {
        bShootRocket= true;
        rocketTimer= 0.0;
    }
*/
}

function DoorAttack(Actor A)
{
	if ( bShotAnim )
		return;
	else if ( A!=None )
	{
		Controller.Target = A;
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('PreFireMissile');
		HandleWaitForAnim('PreFireMissile');
		GoToState('FireMissile');
	}
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

function bool logToPlayer(string msg) {
    local Controller C;

    for (C = Level.ControllerList; C != None; C = C.NextController) {
        if (PlayerController(C) != None) {
            PlayerController(C).ClientMessage(msg);
        }
    }

    return true;
}
function RangedAttack(Actor A) {
    local int numCloseEnemies;
    local float minDist;
    
    minDist= 150.0;
    numCloseEnemies= numEnemiesAround(minDist);
	if(!bShotAnim && (numCloseEnemies >= 1)) {
		bShotAnim = true;
		Acceleration = vect(0,0,0);
//		SetAnimAction('PreFireMissile');

//		HandleWaitForAnim('PreFireMissile');
        LogToPlayer("Firing super missile!");

		GoToState('FireSuperMissile');
	} else {
        super.RangedAttack(A);
    }
}

state FireSuperMissile extends FireMissile {
Ignores RangedAttack;

    function bool ShouldChargeFromDamage() {
        return super.ShouldChargeFromDamage();
    }

	function BeginState() {
        bFiringSuperMissile= true;
        super.BeginState();
	}

	function AnimEnd( int Channel )	{
        super.AnimEnd(Channel);
	}

    function EndState() {
        bFiringSuperMissile= false;
        super.EndState();
    }
Begin:
	while ( true ) {
		Acceleration = vect(0,0,0);
		Sleep(0.1);
	}
}
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{  
    local float DamagerDistSq;
	local float UsedPipeBombDamScale;
    local int numEnemies; 

    logToPlayer(GetStateName()$" Took damage. Health="$Health$" Damage = "$Damage$" HealingLevels "$HealingLevels[SyringeCount]);

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

	if( (SyringeCount==0 && Health<HealingLevels[0]) || (SyringeCount==1 && Health<HealingLevels[1]) || (SyringeCount==2 && Health<HealingLevels[2]) ) {
        if (bFiringSuperMissile == false) {
        	bShotAnim = true;
    		Acceleration = vect(0,0,0);
    		SetAnimAction('KnockDown');
    		HandleWaitForAnim('KnockDown');
    		KFMonsterController(Controller).bUseFreezeHack = True;
    		GoToState('KnockDown');
        }
	}
} 

