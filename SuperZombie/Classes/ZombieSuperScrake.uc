class ZombieSuperScrake extends ZombieScrake;

var int maxTimesFlipOver;
var int logLevel;
var bool bIsFlippedOver;

simulated function PostBeginPlay() {
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
    local bool bCalledFlipOver;
    maxTimesFlipOver--;
    logToPlayer(2,"Stuns Remaining: "$maxTimesFlipOver);
    bCalledFlipOver= ((maxTimesFlipOver >= 0) && super.FlipOver());
    bIsFlippedOver= bIsFlippedOver || bCalledFlipOver;
    return bCalledFlipOver;
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex) {
    local bool bIsHeadShot;
    local int oldHealth;
    local int totalDamage;

    oldHealth= Health;
	bIsHeadShot = IsHeadShot(Hitlocation, normal(Momentum), 1.0);
	if ( Level.Game.GameDifficulty >= 5.0 && bIsHeadshot && (class<DamTypeCrossbow>(damageType) != none || class<DamTypeCrossbowHeadShot>(damageType) != none) ) {
		Damage *= 0.5; // Was 0.5 in Balance Round 1, then 0.6 in Round 2, back to 0.5 in Round 3
	}

	Super(KFMonster).takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType, HitIndex);
    totalDamage= oldHealth - Health;
    
    LogToPlayer(2,""$totalDamage);
    if( bIsFlippedOver && Health>0 && totalDamage <=(float(Default.Health)/1.5) ) {
        //Break stun if the scrake is hit with a weak attack
        bShotAnim= false;
        bIsFlippedOver= false;
        SetAnimAction(WalkAnims[0]);
        SawZombieController(Controller).GoToState('ZombieHunt');

        LogToPlayer(2,"Weak attack!");
    }
    LogToPlayer(2,"Sawing Loop? "$!IsInState('SawingLoop'));
    LogToPlayer(2,"Running State? "$!IsInState('RunningState'));
    LogToPlayer(2,"Hp: "$Health);

    if ( Level.Game.GameDifficulty >= 5.0 && !IsInState('SawingLoop') && float(Health) / HealthMax < 0.75 ) {
        LogToPlayer(2,"Grrr! I'm maad!");
        GotoState('');
        RangedAttack(InstigatedBy);
    }

} 

defaultproperties {
    logLevel= 0;
    maxTimesFlipOver= 1
    bIsFlippedOver= false
    MenuName= "Super Scrake"
}
