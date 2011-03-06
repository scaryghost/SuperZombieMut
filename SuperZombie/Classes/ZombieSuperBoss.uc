class ZombieSuperBoss extends ZombieBoss;

simulated function PostBeginPlay() {
    logToPlayer("Super Boss spawning!");
    super.PostBeginPlay();
}


function int numEnemiesAround(float minDist) {
	local Controller C;
    local int count;

    count= 0;
	For( C=Level.ControllerList; C!=None; C=C.NextController ) {
		if( C.bIsPlayer && C.Pawn!=None && VSize(C.Pawn.Location-Location)<minDist && FastTrace(C.Pawn.Location,Location)) {
			count++;
        }
	}
	return count;
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

function RangedAttack(Actor A) {
    local int numEnemies;

    numEnemies= numEnemiesAround(1500);

    logToPlayer(""$numEnemies);

	if(numEnemies >= 3)	{
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('PreFireMissile');

		HandleWaitForAnim('PreFireMissile');

		GoToState('FireMissile');
	} else {
        super.RangedAttack(A);
    }
}
