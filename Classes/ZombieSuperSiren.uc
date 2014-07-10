class ZombieSuperSiren extends ZombieSiren_STANDARD;

/**
 *  Modified the function so the screams hit through doors as well as damaging them
 */ 
simulated function SpawnTwoShots() {
    DoShakeEffect();

    if( Level.NetMode!=NM_Client ) {
        // Deal Actual Damage.
        if( Controller!=None && KFDoorMover(Controller.Target)!=None ) {
            Controller.Target.TakeDamage(ScreamDamage*0.6,Self,Location,vect(0,0,0),ScreamDamageType);
            HurtRadiusThroughDoor(ScreamDamage*0.6 ,ScreamRadius, ScreamDamageType, ScreamForce, Location);
        }
        else {
            HurtRadiusThroughDoor(ScreamDamage ,ScreamRadius, ScreamDamageType, ScreamForce, Location);
        }
    }
}

/**
 *  Changed the Super Siren's screen to hit through all objects
 *  TODO: Make the scream do less damage per non human hit?
 */
simulated function HurtRadiusThroughDoor( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation ) {
    local actor Victims;
    local float damageScale, dist;
    local vector dir;
    local float UsedDamageAmount, usedMomentum;

    if( bHurtEntry )
        return;

    bHurtEntry = true;
    //Changed to CollidingActors
    foreach CollidingActors( class 'Actor', Victims, DamageRadius, HitLocation ) {
        if( (Victims != self) && !Victims.IsA('FluidSurfaceInfo') && 
            !Victims.IsA('KFMonster') && !Victims.IsA('ExtendedZCollision') ) {
            dir = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dir));
            dir = dir/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);

            if (!Victims.IsA('KFHumanPawn')) {// If it aint human, don't pull the vortex crap on it.
                UsedMomentum = 0;
            } else {
                UsedMomentum= Momentum;
            }

            if (Victims.IsA('KFGlassMover')) {   // Hack for shattering in interesting ways.
                UsedDamageAmount = 100000; // Siren always shatters glass
            }
            else {
                UsedDamageAmount = DamageAmount;
            }

            Victims.TakeDamage(damageScale * UsedDamageAmount,Instigator, 
                Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
                (damageScale * UsedMomentum * dir),DamageType);

            if (Instigator != None && Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
                Vehicle(Victims).DriverRadiusDamage(UsedDamageAmount, DamageRadius, Instigator.Controller, 
                DamageType, UsedMomentum, HitLocation);
        }
    }
    bHurtEntry = false;
}

defaultproperties {
    MenuName="Super Siren"
    ScreamRadius=700
    ScreamForce=-200000
}
