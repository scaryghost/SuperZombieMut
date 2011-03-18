class SuperScrakeZombieController extends SawZombieController;

state WaitForAnim {
Ignores SeePlayer,HearNoise,Timer,EnemyNotVisible,NotifyBump,Startle;

    function GetOutOfTheWayOfShot(vector ShotDirection, vector ShotOrigin) {
        super.GetOutOfTheWayOfShot(ShotDirection, ShotOrigin);
    }

	event AnimEnd(int Channel) {
        super.AnimEnd(Channel);
	}

	function BeginState() {
        super.BeginState();
	}
	function Tick( float Delta ) {
        super.Tick(Delta);
	}
	function EndState() {
        ZombieSuperScrake(pawn).bIsFlippedOver= false;
        super.EndState();
	}

Begin:
	While( KFM.bShotAnim ) {
    	Sleep(0.15);
	}
	WhatToDoNext(99);
}
