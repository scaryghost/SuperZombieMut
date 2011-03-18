class SuperScrakeZombieController extends SawZombieController;

var float start, end;

state WaitForAnim {
Ignores SeePlayer,HearNoise,Timer,EnemyNotVisible,NotifyBump,Startle;

    function GetOutOfTheWayOfShot(vector ShotDirection, vector ShotOrigin) {
        super.GetOutOfTheWayOfShot(ShotDirection, ShotOrigin);
    }

	event AnimEnd(int Channel) {
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
        ZombieSuperScrake(pawn).bIsFlippedOver= false;
        super.EndState();
	}

Begin:
	While( KFM.bShotAnim ) {
    	Sleep(0.15);
	}
	WhatToDoNext(99);
}
