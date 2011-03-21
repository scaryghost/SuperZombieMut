class ZombieSuperFP extends ZombieFleshPound;

var int logLevel;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    logToPlayer(1,"Level of agression, 12!");
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

function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
    local bool didIHit;
    
    didIHit= super.MeleeDamageTarget(hitdamage, pushdir);
    SuperFPZombieController(Controller).bMissTarget= 
        SuperFPZombieController(Controller).bMissTarget && !didIHit;
    logToPlayer(2,"Did I hit?  "$didIHit);

    return didIHit;
}

simulated event SetAnimAction(name NewAction) {
    super.SetAnimAction(newAction);
    SuperFPZombieController(Controller).bAttackedTarget= 
	    (NewAction == 'Claw') || (NewAction == 'DoorBash');
}

defaultproperties {
    logLevel= 0
    MenuName="Super FleshPound"
    ControllerClass=Class'SuperZombie.SuperFPZombieController'
}
