class ZombieSuperBloat extends ZombieBloat;

var float pukeRate;
var float pukeRange;
var float bileMaxRange;
var int logLevel;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    logToPlayer(1,"I'm skinny!");
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

function RangedAttack(Actor A)
{
	local int LastFireTime;
    local float ChargeChance;

	if ( bShotAnim )
		return;

	if ( Physics == PHYS_Swimming )
	{
		SetAnimAction('Claw');
		bShotAnim = true;
		LastFireTime = Level.TimeSeconds;
	}
	else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius )
	{
		bShotAnim = true;
		LastFireTime = Level.TimeSeconds;
		SetAnimAction('Claw');
		//PlaySound(sound'Claw2s', SLOT_Interact); KFTODO: Replace this
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
	}
	else if ( (KFDoorMover(A) != none || VSize(A.Location-Location) <= pukeRange) && !bDecapitated )
	{
		bShotAnim = true;

        // Decide what chance the bloat has of charging during a puke attack
        if( Level.Game.GameDifficulty < 2.0 )
        {
            ChargeChance = 0.2;
        }
        else if( Level.Game.GameDifficulty < 4.0 )
        {
            ChargeChance = 0.4;
        }
        else if( Level.Game.GameDifficulty < 5.0 )
        {
            ChargeChance = 0.6;
        }
        else // Hardest difficulty
        {
            ChargeChance = 0.8;
        }
        ChargeChance= 1.0;
		// Randomly do a moving attack so the player can't kite the zed
        if( FRand() < ChargeChance )
		{
    		SetAnimAction('ZombieBarfMoving');
    		RunAttackTimeout = GetAnimDuration('ZombieBarf', 1.0);
    		bMovingPukeAttack=true;
		}
		else
		{
    		SetAnimAction('ZombieBarf');
    		Controller.bPreparingMove = true;
    		Acceleration = vect(0,0,0);
		}


		// Randomly send out a message about Bloat Vomit burning(3% chance)
		if ( FRand() < 0.03 && KFHumanPawn(A) != none && PlayerController(KFHumanPawn(A).Controller) != none )
		{
			PlayerController(KFHumanPawn(A).Controller).Speech('AUTO', 7, "");
		}
	}
}

//ZombieBarf animation triggers this
function SpawnTwoShots()
{
	local vector X,Y,Z, FireStart;
	local rotator FireRotation;

	if( Controller!=None && KFDoorMover(Controller.Target)!=None )
	{
		Controller.Target.TakeDamage(22,Self,Location,vect(0,0,0),Class'DamTypeVomit');
		return;
	}

	GetAxes(Rotation,X,Y,Z);
	FireStart = Location+(vect(30,0,64) >> Rotation)*DrawScale;
	if ( !SavedFireProperties.bInitialized )
	{
		SavedFireProperties.AmmoClass = Class'SkaarjAmmo';
		SavedFireProperties.ProjectileClass = Class'KFBloatVomit';
		SavedFireProperties.WarnTargetPct = 1;
		SavedFireProperties.MaxRange = bileMaxRange;
		SavedFireProperties.bTossed = False;
		SavedFireProperties.bTrySplash = False;
		SavedFireProperties.bLeadTarget = True;
		SavedFireProperties.bInstantHit = True;
		SavedFireProperties.bInitialized = True;
	}

    // Turn off extra collision before spawning vomit, otherwise spawn fails
    ToggleAuxCollision(false);
	FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,600);
    logToPlayer(2,"(" $ FireRotation.Pitch $ "," $ FireRotation.Yaw $ "," $ FireRotation.Roll $ ")");
	Spawn(Class'KFBloatVomit',,,FireStart,FireRotation);

	FireStart-=(0.5*CollisionRadius*Y);
	FireRotation.Yaw -= 1200;
    logToPlayer(2,"(" $ FireRotation.Pitch $ "," $ FireRotation.Yaw $ "," $ FireRotation.Roll $ ")");
	spawn(Class'KFBloatVomit',,,FireStart, FireRotation);

	FireStart+=(CollisionRadius*Y);
	FireRotation.Yaw += 2400;
    logToPlayer(2,"(" $ FireRotation.Pitch$ "," $ FireRotation.Yaw $ "," $ FireRotation.Roll $ ")");
	spawn(Class'KFBloatVomit',,,FireStart, FireRotation);
	// Turn extra collision back on
	ToggleAuxCollision(true);
}

simulated function int DoAnimAction( name AnimName )
{
	if( AnimName=='HitF' || AnimName=='HitF2' || AnimName=='HitF3' || AnimName==KFHitFront || AnimName==KFHitBack || AnimName==KFHitRight
	 || AnimName==KFHitLeft )
	{
		AnimBlendParams(1, 1.0, 0.0,, SpineBone1);
		PlayAnim(AnimName,, 0.1, 1);
		return 1;
	}

    if(AnimName == 'ZombieBarf') {
    	PlayAnim(AnimName,pukeRate, 0,0.1);
    } else {
        PlayAnim(AnimName,, 0,0.1);
    }
	return 0;
}

// Handle playing the anim action on the upper body only if we're attacking and moving
simulated function int AttackAndMoveDoAnimAction( name AnimName )
{
    if( AnimName=='ZombieBarfMoving' )
	{
		AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
		PlayAnim('ZombieBarf',pukeRate, 0.1, 1);

		return 1;
	}

	return super.DoAnimAction( AnimName );
}

defaultproperties {
    pukeRate= 0.0;
    pukeRange= 250.0;
    logLevel= 0;
    bileMaxRange= 500.0;
}
