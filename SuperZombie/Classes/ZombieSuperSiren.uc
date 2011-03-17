// Zombie Monster for KF Invasion gametype
class ZombieSuperSiren extends ZombieSiren;

var int logLevel;

simulated function PostBeginPlay() {
    logToPlayer(1,"Super Siren spawning!");
    super.PostBeginPlay();
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

simulated function SpawnTwoShots() {
    DoShakeEffect();

	if( Level.NetMode!=NM_Client ) {
		// Deal Actual Damage.
		if( Controller!=None && KFDoorMover(Controller.Target)!=None ) {
			Controller.Target.TakeDamage(ScreamDamage*0.6,Self,Location,vect(0,0,0),ScreamDamageType);
            HurtRadiusThroughDoor(ScreamDamage*0.5 ,ScreamRadius, ScreamDamageType, ScreamForce, Location);
            logToPlayer(1,"Scream at door!");
        }
		else {
            HurtRadius(ScreamDamage ,ScreamRadius, ScreamDamageType, ScreamForce, Location);
        }
	}
}

simulated function HurtRadiusThroughDoor( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation ) {
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
	local float UsedDamageAmount;

	if( bHurtEntry )
		return;

	bHurtEntry = true;
	foreach CollidingActors( class 'Actor', Victims, DamageRadius, HitLocation ) {
		if( (Victims != self) && !Victims.IsA('FluidSurfaceInfo') && 
            !Victims.IsA('KFMonster') && !Victims.IsA('ExtendedZCollision') ) {
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);

			if (!Victims.IsA('KFHumanPawn')) // If it aint human, don't pull the vortex crap on it.
				Momentum = 0;

			if (Victims.IsA('KFGlassMover')) {   // Hack for shattering in interesting ways.
				UsedDamageAmount = 100000; // Siren always shatters glass
			}
			else {
                UsedDamageAmount = DamageAmount;
			}

			Victims.TakeDamage(damageScale * UsedDamageAmount,Instigator, 
                Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
                (damageScale * Momentum * dir),DamageType);

            if (Instigator != None && Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
				Vehicle(Victims).DriverRadiusDamage(UsedDamageAmount, DamageRadius, Instigator.Controller, 
                DamageType, Momentum, HitLocation);
		}
	}
	bHurtEntry = false;
}

defaultproperties {
    MenuName="Super Siren"
    logLevel= 0;
}
