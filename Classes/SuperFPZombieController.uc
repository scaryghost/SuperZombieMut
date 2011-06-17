class SuperFPZombieController extends FleshpoundZombieController;

var bool bFindNewEnemy, bSmashDoor, bStartled, bAttackedTarget, bMissTarget;
var float prevRageTimer;
var float prevRageThreshold;

function PostBeginPlay() {
    super.PostBeginPlay();
    bFindNewEnemy= false;
    bSmashDoor= false;
    bStartled= false;
    bAttackedTarget= false;
    bMissTarget= false;
    prevRageTimer= 0;
    prevRageThreshold= default.RageFrustrationThreshhold + (Frand() * 5); 
}

function bool FindNewEnemy() {
    bFindNewEnemy= true;
    return super.FindNewEnemy();
}

function BreakUpDoor(KFDoorMover Other, bool bTryDistanceAttack) {
    bSmashDoor= true;
    super.BreakUpDoor(Other,bTryDistanceAttack);
}

function Startle(Actor Feared) {
    bStartled= True;
    super.Startle(Feared);
}

state ZombieCharge {
    function Tick( float Delta ) {
        super.Tick(Delta);
    }

    function bool StrafeFromDamage(float Damage, class<DamageType> DamageType, bool bFindDest) {
        return super.StrafeFromDamage(Damage, DamageType, bFindDest);
    }

    function bool TryStrafe(vector sideDir) {
        return super.TryStrafe(sideDir);
    }

    function Timer() {
        super.Timer();
    }

    function BeginState() {
        super.BeginState();
        if (!bSmashDoor && ((bAttackedTarget && bMissTarget) 
            || bFindNewEnemy || bStartled)) {
            RageFrustrationTimer= prevRageTimer;
            RageFrustrationThreshhold= prevRageThreshold;
        }
        bFindNewEnemy= false;
        bSmashDoor= false;
        bStartled= false;
        bAttackedTarget= false;
        bMissTarget= false;
    }

    function EndState() {
        prevRageTimer= RageFrustrationTimer;
        prevRageThreshold= RageFrustrationThreshhold;
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
