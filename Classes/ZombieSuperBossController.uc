class ZombieSuperBossController extends BossZombieController;

var int selection;

function PostBeginPlay() {
    super.PostBeginPlay();
    selection= rand(4);
}

function bool FindNewEnemy() {
    local Pawn BestEnemy;
    local Controller PC;
    local KFHumanPawn P;
    local float lowestValue1, lowestValue2;
    local float currentLowest1, currentLowest2;
    local bool canSeeLowest, canSeeCurrent;

    if (KFM.bNoAutoHuntEnemies)
        return False;

    selection= rand(4);
    for (PC=Level.ControllerList; PC!=None; PC=PC.NextController) {
        P= KFHumanPawn(PC.Pawn);
        if (P != None && PC.bIsPlayer) {
            switch(selection) {
                case 0:
                    currentLowest1= VSize(BestEnemy.Location - Pawn.Location);
                    currentLowest2= 0;
                    break;
                case 1:
                    currentLowest1= P.Health;
                    currentLowest2= P.ShieldStrength;
                    break;
                case 2:
                    currentLowest1= -P.GroundSpeed;
                    currentLowest2= 0;
                    break;
                case 3:
                    currentLowest1= -P.CurrentWeight;
                    currentLowest2= 0;
                    break;
                default:
                    log("ZombieSuperBossController.FindNewEnemy(): Unkown selection number"@selection);
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
        if (selection != 0)
            return;
        super.DamageAttitudeTo(Other, Damage);
    }
}

function DamageAttitudeTo(Pawn Other, float Damage) {
        if (selection != 0)
            return;
    super.DamageAttitudeTo(Other, Damage);
}
