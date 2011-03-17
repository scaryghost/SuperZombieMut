class SuperScrakeZombieController extends SawZombieController;

var int logLevel;
var float start, end;

function PostBeginPlay() {
    super.PostBeginPlay();
    logToPlayer(1,"I like scrubs");
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

state WaitForAnim {
Ignores SeePlayer,HearNoise,Timer,EnemyNotVisible,NotifyBump,Startle;

    function GetOutOfTheWayOfShot(vector ShotDirection, vector ShotOrigin) {
        super.GetOutOfTheWayOfShot(ShotDirection, ShotOrigin);
    }

	event AnimEnd(int Channel) {
        LogToPlayer(2,"My Stun animation ended!");
        super.AnimEnd(Channel);
	}

	function BeginState() {
        start= Level.TimeSeconds;
        super.BeginState();
	}
	function Tick( float Delta ) {
        super.Tick(Delta);
	}
	function EndState() {
        local float deltaTime;
        end= Level.TimeSeconds;
        deltaTime= end - start;
        LogToPlayer(2,"Stun Time: "$(deltaTime));
        super.EndState();
	}

Begin:
	While( KFM.bShotAnim ) {
    	Sleep(0.15);
	}
	WhatToDoNext(99);
}

defaultproperties {
    logLevel= 2;
}
