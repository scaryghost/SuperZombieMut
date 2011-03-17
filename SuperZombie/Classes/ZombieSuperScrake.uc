class ZombieSuperScrake extends ZombieScrake;

#exec OBJ LOAD FILE=PlayerSounds.uax

var int maxTimesFlipOver;
var int logLevel;

function PostBeginPlay() {
    super.PostBeginPlay();
    logToPlayer(1,"I like scrubs");
}

function logToPlayer(int level, string msg) {
    isItMyLogLevel(level) && outputToChat(msg);
}

function bool isItMyLogLevel(int level) {
    return (logLevel >= level);
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

function bool FlipOver() {
    local float animDur;
    animDur= GetAnimDuration('KnockDown',1.0);
    logToPlayer(2,""$animDur);
    maxTimesFlipOver--;
    logToPlayer(2,"Stuns Remaining: "$maxTimesFlipOver);
    return (maxTimesFlipOver >= 0) && super.FlipOver();
}

defaultproperties {
    logLevel= 2;
    maxTimesFlipOver= 1
    MenuName= "Super Scrake"
    ControllerClass=Class'SuperZombie.SuperScrakeZombieController'
}
