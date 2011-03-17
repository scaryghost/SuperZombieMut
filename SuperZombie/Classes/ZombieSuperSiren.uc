// Zombie Monster for KF Invasion gametype
class ZombieSuperSiren extends ZombieSiren;

var int logLevel;

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
            logToPlayer(1,"Scream at door!");
        }
		else {
            HurtRadius(ScreamDamage ,ScreamRadius, ScreamDamageType, ScreamForce, Location);
        }
	}
}

defaultproperties {
    logLevel= 1;
}
