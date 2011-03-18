class ZombieSuperScrake extends ZombieScrake;

var int maxTimesFlipOver;
var int logLevel;
var bool bIsFlippedOver;

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
    maxTimesFlipOver--;
    logToPlayer(2,"Stuns Remaining: "$maxTimesFlipOver);
    bIsFlippedOver= (maxTimesFlipOver >= 0) && super.FlipOver();
    return bIsFlippedOver;
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex) {
    local int oldHealth;
    local int totalDamage;

    oldHealth= Health;
    super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, damageType, HitIndex);
    totalDamage= oldHealth - Health;

    if( bIsFlippedOver && Health>0 && totalDamage <=(float(Default.Health)/1.5) ) {
        //Break stun if the scrake is hit with a weak attack
        bShotAnim= false;
        SetAnimAction(WalkAnims[0]);
        SuperScrakeZombieController(Controller).GoToState('ZombieHunt');
        bIsFlippedOver= false;
    }
} 

defaultproperties {
    logLevel= 0;
    maxTimesFlipOver= 1
    bIsFlippedOver= true
    MenuName= "Super Scrake"
    ControllerClass=Class'SuperZombie.SuperScrakeZombieController'
}
