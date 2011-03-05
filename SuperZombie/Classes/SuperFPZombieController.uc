class SuperFPZombieController extends FleshpoundZombieController;

var bool bFindNewEnemy, bSmashDoor, bStartled;
var float prevRageTimer;
var float prevRageThreshold;
var int logLevel;

function PostBeginPlay() {
    super.PostBeginPlay();
    bFindNewEnemy= false;
    bSmashDoor= false;
    bStartled= false;
    prevRageTimer= 0;
    prevRageThreshold= default.RageFrustrationThreshhold + (Frand() * 5); 

    isItMyLogLevel(1) && logToPlayer("Level of aggression, 12!");
}

function bool logToPlayer(string msg) {
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

function bool FindNewEnemy() {
    isItMyLogLevel(2) && logToPlayer("Searching for enemy");
    bFindNewEnemy= true;
    return super.FindNewEnemy();
}

function BreakUpDoor(KFDoorMover Other, bool bTryDistanceAttack) {
    isItMyLogLevel(2) && logToPlayer("FP SMASH DOOR!");
    bSmashDoor= true;
    super.BreakUpDoor(Other,bTryDistanceAttack);
}

function Startle(Actor Feared) {
    isItMyLogLevel(2) && logToPlayer("Ahh!! Grenade!");
    bStartled= True;
    super.Startle(Feared);
}

state ZombieCharge {
	function Tick( float Delta ) {
        super.Tick(Delta);
        isItMyLogLevel(3) && logToPlayer("Time left: "$(RageFrustrationThreshhold-RageFrustrationTimer));
	}

	function bool StrafeFromDamage(float Damage, class<DamageType> DamageType, bool bFindDest) {
	    return super.StrafeFromDamage(Damage, DamageType, bFindDest);
	}

	function bool TryStrafe(vector sideDir)	{
        return super.TryStrafe(sideDir);
	}

	function Timer() {
        super.Timer();
	}

	function BeginState() {
        super.BeginState();
        if (!bSmashDoor && (bFindNewEnemy || bStartled)) {
            RageFrustrationTimer= prevRageTimer;
            RageFrustrationThreshhold= prevRageThreshold;
        }
        bFindNewEnemy= false;
        bSmashDoor= false;
        bStartled= false;
        
        isItMyLogLevel(2) && logToPlayer("Entering ZombieCharge state");
	}

    function EndState() {
        prevRageTimer= RageFrustrationTimer;
        prevRageThreshold= RageFrustrationThreshhold;

        isItMyLogLevel(2) && logToPlayer("Leaving ZombieCharge state");
    }

WaitForAnim:

	if ( Monster(Pawn).bShotAnim ) {
		Goto('Moving');
	}
	if ( !FindBestPathToward(Enemy, false,true) )
		GotoState('ZombieRestFormation');
Moving:
	MoveToward(Enemy);
	WhatToDoNext(17);
	if ( bSoaking )
		SoakStop("STUCK IN CHARGING!");
}

defaultproperties {
    logLevel= 0;
}
