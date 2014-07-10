class ZombieSuperGorefast extends ZombieGoreFast_STANDARD;

/** minRageDist minimum distance to trigger the Super Gorefast's rage state */
var float minRageDist;

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

    function EndState() {
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
            
            //Always do the charging melee attack
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
    MenuName= "Super Gorefast"
    minRageDist= 1400
}
