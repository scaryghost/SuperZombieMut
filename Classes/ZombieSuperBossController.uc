class ZombieSuperBossController extends BossZombieController;

function bool FindNewEnemy() {
    local Pawn BestEnemy;
    local bool bSeeNew, bSeeBest;
    local Controller PC;
    local KFHumanPawn P;
    local float lowestHealth;

    if (KFM.bNoAutoHuntEnemies)
        return False;

    for (PC=Level.ControllerList; PC!=None; PC=PC.NextController) {
        P= KFHumanPawn(PC.Pawn);
        if(P != None && P.Health > 0) {
            if (BestEnemy == None ) {
                BestEnemy= P;
                lowestHealth= P.Health;
                bSeeBest= CanSee(P);
                log("Health:"@P.Health);
            } else {
                if (!bSeeBest || P.Health < lowestHealth ) {
                    bSeeNew= CanSee(P);
                    if (P.Health < lowestHealth) {
                        log("HEalth:"@P.Health);
                        BestEnemy= P;
                        lowestHealth= P.Health;
                        bSeeBest= bSeeNew;
                    }
                }
            }
        }
    }

    if ( BestEnemy == Enemy )
        return false;

    if ( BestEnemy != None ) {
        ChangeEnemy(BestEnemy,CanSee(BestEnemy));
        return true;
    }
    return false;
}
