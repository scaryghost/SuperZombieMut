class ZombieSuperFP extends ZombieFleshPound;

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

defaultproperties {
    logLevel= 0
    MenuName="Super FleshPound"
    ControllerClass=Class'SuperZombie.SuperFPZombieController'
}
