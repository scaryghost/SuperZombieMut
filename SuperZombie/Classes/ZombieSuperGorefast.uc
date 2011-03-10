class ZombieSuperGorefast extends ZombieGoreFast;

var int logLevel;

simulated function PostBeginPlay() {
    logToPlayer(1,"Spawning Super Gorefast!");
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
        local float ChargeChance;

        // Decide what chance the gorefast has of charging during an attack
        if( Level.Game.GameDifficulty < 2.0 )
        {
            ChargeChance = 0.1;
        }
        else if( Level.Game.GameDifficulty < 4.0 )
        {
            ChargeChance = 0.2;
        }
        else if( Level.Game.GameDifficulty < 7.0 )
        {
            ChargeChance = 0.3;
        }
        else // Hardest difficulty
        {
            ChargeChance = 1.0;
        }

    	if ( bShotAnim || Physics == PHYS_Swimming)
    		return;
    	else if ( CanAttack(A) )
    	{
    		bShotAnim = true;

    		// Randomly do a moving attack so the player can't kite the zed
            if( FRand() < ChargeChance )
    		{
        		SetAnimAction('ClawAndMove');
        		RunAttackTimeout = GetAnimDuration('GoreAttack1', 1.0);
    		}
    		else
    		{
        		SetAnimAction('Claw');
        		Controller.bPreparingMove = true;
        		Acceleration = vect(0,0,0);
                // Once we attack stop running
        		GoToState('');
    		}
    		return;
    	}
    }

    simulated function Tick(float DeltaTime) {
        super.Tick(DeltaTime);
    }


Begin:
    GoTo('CheckCharge');
CheckCharge:
    if( Controller!=None && Controller.Target!=None && VSize(Controller.Target.Location-Location)<700 )
    {
        Sleep(0.5+ FRand() * 0.5);
        //log("Still charging");
        GoTo('CheckCharge');
    }
    else
    {
        //log("Done charging");
        GoToState('');
    }
}

defaultproperties {
    logLevel= 1;
}