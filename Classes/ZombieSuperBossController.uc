class ZombieSuperBossController extends BossZombieController;

/** Randomly decide which criteria to use when selecting enemy */
var float selection;

function bool FindNewEnemy() {
    local Pawn BestEnemy;
    local Controller C;
    local KFHumanPawn P;
    local float lowestValue1, lowestValue2;
    local float currentLowest1, currentLowest2;
    local bool canSeeLowest, canSeeCurrent;

    if (KFM.bNoAutoHuntEnemies)
        return False;

    selection= frand();
    for (C=Level.ControllerList; C!=None; C=C.NextController) {
        P= KFHumanPawn(C.Pawn);
        if (P != None && C.bIsPlayer) {
            if (selection < 0.25) {
                //closest
                currentLowest1= VSize(BestEnemy.Location - Pawn.Location);
                currentLowest2= 0;
            } else if (selection >= 0.25 && selection < 0.5) {
                //lowest on hp, or shield for tie
                currentLowest1= P.Health;
                currentLowest2= P.ShieldStrength;
            } else if (selection >= 0.5 && selection < 0.75) {
                //fastest
                currentLowest1= -P.GroundSpeed;
                currentLowest2= 0;
            } else if (selection >= 0.75) {
                //has the most carry weight
                currentLowest1= -P.CurrentWeight;
                currentLowest2= 0;
            }
            canSeeCurrent= CanSee(P);
            if (BestEnemy == none || (canSeeCurrent && !canSeeLowest) || currentLowest1 < lowestValue1 || 
                    (currentLowest1 == lowestValue1 && currentLowest2 < lowestValue2)) {
                BestEnemy= P;
                lowestValue1= currentLowest1;
                lowestValue2= currentLowest2;
                canSeeLowest= canSeeCurrent;
            }
        }
    }

    if (BestEnemy == Enemy)
        return false;

    if (BestEnemy != None) {
        ChangeEnemy(BestEnemy,CanSee(BestEnemy));
        return true;
    }
    return false;
}

state ZombieCharge {
    function DamageAttitudeTo(Pawn Other, float Damage) {
        if (selection >= 0.25)
            return;
        super.DamageAttitudeTo(Other, Damage);
    }
}

//if selection isn't find closet enemy, do not change target
function DamageAttitudeTo(Pawn Other, float Damage) {
    if (selection >= 0.25)
        return;
    super.DamageAttitudeTo(Other, Damage);
}
