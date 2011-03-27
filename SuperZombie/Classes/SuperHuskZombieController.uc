class SuperHuskZombieController extends HuskZombieController;

/*
AdjustAim()
Returns a rotation which is the direction the bot should aim - after introducing the appropriate aiming error
Overridden to cause the zed to fire at the feet more often - Ramm
*/
function rotator AdjustAim(FireProperties FiredAmmunition, vector projStart, int aimerror)
{
	local rotator FireRotation, TargetLook;
	local float FireDist, TargetDist, ProjSpeed;
	local actor HitActor;
	local vector FireSpot, FireDir, TargetVel, HitLocation, HitNormal;
	local int realYaw;
	local bool bDefendMelee, bClean, bLeadTargetNow;
	local bool bWantsToAimAtFeet;

    //This variable is set to the Z value for the husk to shoot at the target's feet
    //It is set this way because if the target is too close to the husk and jumps,
    //the husk doesn't not aim down.
    local float aimAtFeetZ;
    aimAtFeetZ= -72.15;

	if ( FiredAmmunition.ProjectileClass != None )
		projspeed = FiredAmmunition.ProjectileClass.default.speed;

	// make sure bot has a valid target
	if ( Target == None )
	{
		Target = Enemy;
		if ( Target == None )
			return Rotation;
	}
	FireSpot = Target.Location;
    ZombieSuperHusk(pawn).logToPlayer(3,"(" $ FireSpot.X $ "," $ FireSpot.Y $ "," $ FireSpot.Z $ ")");

	TargetDist = VSize(Target.Location - Pawn.Location);

	// perfect aim at stationary objects
	if ( Pawn(Target) == None )
	{
		if ( !FiredAmmunition.bTossed )
			return rotator(Target.Location - projstart);
		else
		{
			FireDir = AdjustToss(projspeed,ProjStart,Target.Location,true);
			SetRotation(Rotator(FireDir));
			return Rotation;
		}
	}

	bLeadTargetNow = FiredAmmunition.bLeadTarget && bLeadTarget;
	bDefendMelee = ( (Target == Enemy) && DefendMelee(TargetDist) );
	aimerror = AdjustAimError(aimerror,TargetDist,bDefendMelee,FiredAmmunition.bInstantHit, bLeadTargetNow);

	// lead target with non instant hit projectiles
	if ( bLeadTargetNow )
	{
		TargetVel = Target.Velocity;
		// hack guess at projecting falling velocity of target
		if ( Target.Physics == PHYS_Falling )
		{
			if ( Target.PhysicsVolume.Gravity.Z <= Target.PhysicsVolume.Default.Gravity.Z )
				TargetVel.Z = FMin(TargetVel.Z + FMax(-400, Target.PhysicsVolume.Gravity.Z * FMin(1,TargetDist/projSpeed)),0);
			else
				TargetVel.Z = FMin(0, TargetVel.Z);
            ZombieSuperHusk(pawn).logToPlayer(2,"Target is falling!");
		}
		// more or less lead target (with some random variation)
		FireSpot += FMin(1, 0.7 + 0.6 * FRand()) * TargetVel * TargetDist/projSpeed;
        if (bDefendMelee) {
            FireSpot.Z= aimAtFeetZ;
        } else {
    		FireSpot.Z = FMin(Target.Location.Z, FireSpot.Z);
        }

		if ( (Target.Physics != PHYS_Falling) && (FRand() < 0.55) && (VSize(FireSpot - ProjStart) > 1000) )
		{
			// don't always lead far away targets, especially if they are moving sideways with respect to the bot
			TargetLook = Target.Rotation;
			if ( Target.Physics == PHYS_Walking )
				TargetLook.Pitch = 0;
			bClean = ( ((Vector(TargetLook) Dot Normal(Target.Velocity)) >= 0.71) && FastTrace(FireSpot, ProjStart) );
		}
		else // make sure that bot isn't leading into a wall
			bClean = FastTrace(FireSpot, ProjStart);
		if ( !bClean)
		{
			// reduce amount of leading
			if ( FRand() < 0.3 )
				FireSpot = Target.Location;
			else
				FireSpot = 0.5 * (FireSpot + Target.Location);
		}
	}

	bClean = false; //so will fail first check unless shooting at feet
    // Randomly determine if we should try and splash damage with the fire projectile

    if( FiredAmmunition.bTrySplash )
    {
        if( Skill < 2.0 )
        {
            if(FRand() > 0.85)
            {
                bWantsToAimAtFeet = true;
            }
        }
        else if( Skill < 3.0 )
        {
            if(FRand() > 0.5)
            {
                bWantsToAimAtFeet = true;
            }
        }
        else if( Skill >= 3.0 )
        {
            if(FRand() > 0.25)
            {
                bWantsToAimAtFeet = true;
            }
        }
    }

    bWantsToAimAtFeet= false;
	if ( FiredAmmunition.bTrySplash && (Pawn(Target) != None) && (((Target.Physics == PHYS_Falling)
        && (Pawn.Location.Z + 80 >= Target.Location.Z)) || ((Pawn.Location.Z + 19 >= Target.Location.Z)
        && (bDefendMelee || bWantsToAimAtFeet))) )
	{
        ZombieSuperHusk(pawn).logToPlayer(2,"Shooting at yo feet");
        ZombieSuperHusk(pawn).logToPlayer(3,"(" $ FireSpot.X $ "," $ FireSpot.Y $ "," $ FireSpot.Z $ ")");
        HitActor = Trace(HitLocation, HitNormal, FireSpot - vect(0,0,1) * (Target.CollisionHeight + 10), FireSpot, false);

 		bClean = (HitActor == None);
        //So if we're too close, and not jumping, bClean is false
        //same distance but jumping, bClean is true
        ZombieSuperHusk(pawn).logToPlayer(2,"Clean Before? "$bClean);
		if ( !bClean )
		{
			FireSpot = HitLocation + vect(0,0,3);
			bClean = FastTrace(FireSpot, ProjStart);
		}
		else
			bClean = ( (Target.Physics == PHYS_Falling) && FastTrace(FireSpot, ProjStart) );
        ZombieSuperHusk(pawn).logToPlayer(2,"Clean? "$bClean);
	}

	if ( !bClean )
	{
		//try middle
		FireSpot.Z = Target.Location.Z;
 		bClean = FastTrace(FireSpot, ProjStart);
	}
	if ( FiredAmmunition.bTossed && !bClean && bEnemyInfoValid )
	{
		FireSpot = LastSeenPos;
	 	HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
		if ( HitActor != None )
		{
			bCanFire = false;
			FireSpot += 2 * Target.CollisionHeight * HitNormal;
		}
		bClean = true;
	}

	if( !bClean )
	{
		// try head
 		FireSpot.Z = Target.Location.Z + 0.9 * Target.CollisionHeight;
 		bClean = FastTrace(FireSpot, ProjStart);
	}
	if ( !bClean && (Target == Enemy) && bEnemyInfoValid )
	{
		FireSpot = LastSeenPos;
		if ( Pawn.Location.Z >= LastSeenPos.Z )
			FireSpot.Z -= 0.4 * Enemy.CollisionHeight;
	 	HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
		if ( HitActor != None )
		{
			FireSpot = LastSeenPos + 2 * Enemy.CollisionHeight * HitNormal;
			if ( Monster(Pawn).SplashDamage() && (Skill >= 4) )
			{
			 	HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
				if ( HitActor != None )
					FireSpot += 2 * Enemy.CollisionHeight * HitNormal;
			}
			bCanFire = false;
		}
	}

	// adjust for toss distance
	if ( FiredAmmunition.bTossed ) {
        ZombieSuperHusk(pawn).logToPlayer(2,"Toss!");
		FireDir = AdjustToss(projspeed,ProjStart,FireSpot,true);
    }
	else {
        ZombieSuperHusk(pawn).logToPlayer(2,"No Toss!");
		FireDir = FireSpot - ProjStart;
    }

	FireRotation = Rotator(FireDir);
	realYaw = FireRotation.Yaw;
	InstantWarnTarget(Target,FiredAmmunition,vector(FireRotation));

	FireRotation.Yaw = SetFireYaw(FireRotation.Yaw + aimerror);
	FireDir = vector(FireRotation);
	// avoid shooting into wall
	FireDist = FMin(VSize(FireSpot-ProjStart), 400);
	FireSpot = ProjStart + FireDist * FireDir;
	HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
	if ( HitActor != None )
	{
		if ( HitNormal.Z < 0.7 )
		{
			FireRotation.Yaw = SetFireYaw(realYaw - aimerror);
			FireDir = vector(FireRotation);
			FireSpot = ProjStart + FireDist * FireDir;
			HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
		}
		if ( HitActor != None )
		{
			FireSpot += HitNormal * 2 * Target.CollisionHeight;
			if ( Skill >= 4 )
			{
				HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
				if ( HitActor != None )
					FireSpot += Target.CollisionHeight * HitNormal;
			}
			FireDir = Normal(FireSpot - ProjStart);
			FireRotation = rotator(FireDir);
		}
	}

    //Make it so the Husk always shoots the ground it the target is close
	SetRotation(FireRotation);
    ZombieSuperHusk(pawn).logToPlayer(3,"(" $ FireRotation.Pitch $ "," $ FireRotation.Yaw $ "," $ FireRotation.Roll $ ")");
	return FireRotation;
}

