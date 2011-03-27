class ZombieSuperGorefast extends ZombieGoreFast;

var int logLevel;
var float minRageDist;

simulated function PostBeginPlay() {
    logToPlayer(1,"Insert joke on a gorefast line here!");
    minRageDist= 1400.0;
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

function RangedAttack(Actor A) {
	Super(KFMonster).RangedAttack(A);
	if( !bShotAnim && !bDecapitated && VSize(A.Location-Location)<=minRageDist )
		GoToState('RunningState');
}

state RunningState {
    // Don't override speed in this state
    function bool CanSpeedAdjust() {
        return super.CanSpeedAdjust();
    }

	function BeginState() {
        super.BeginState();
	}

	function EndState()	{
        super.EndState();
	}

	function RemoveHead() {
        super.RemoveHead();
	}

    function RangedAttack(Actor A) {

    	if ( bShotAnim || Physics == PHYS_Swimming)
    		return;
    	else if ( CanAttack(A) ) {
    		bShotAnim = true;

    		// Randomly do a moving attack so the player can't kite the zed
        		SetAnimAction('ClawAndMove');
        		RunAttackTimeout = GetAnimDuration('GoreAttack1', 1.0);
    		return;
    	}
    }

    simulated function Tick(float DeltaTime) {
        super.Tick(DeltaTime);
    }


Begin:
    GoTo('CheckCharge');
CheckCharge:
    if( Controller!=None && Controller.Target!=None && VSize(Controller.Target.Location-Location)<minRageDist ) {
        Sleep(0.5+ FRand() * 0.5);
        //log("Still charging");
        GoTo('CheckCharge');
    }
    else {
        //log("Done charging");
        GoToState('');
    }
}

defaultproperties {
    logLevel= 0;
    MenuName= "Super Gorefast"
}
