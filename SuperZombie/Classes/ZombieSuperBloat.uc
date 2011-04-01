class ZombieSuperBloat extends ZombieBloat;

var int logLevel;
var bool bAmIBarfing;
var float bileCoolDownTimer,bileCoolDownMax;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    bAmIBarfing= false;
    bileCoolDownTimer= 0.0;
    logToPlayer(1,"I'm skinny!");
}

simulated function Tick(float DeltaTime) {
    super.Tick(DeltaTime);
    if(!bDecapitated && bAmIBarfing) {
        bileCoolDownTimer+= DeltaTime;
        if(bileCoolDownTimer >= bileCoolDownMax) {
            SpawnTwoShots();
            bileCoolDownTimer= 0.0;
        }
    }
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

function RangedAttack(Actor A) {
    local int LastFireTime;

    if ( bShotAnim )
        return;

    if ( Physics == PHYS_Swimming ) {
        SetAnimAction('Claw');
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
    }
    else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius ) {
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
        SetAnimAction('Claw');
        //PlaySound(sound'Claw2s', SLOT_Interact); KFTODO: Replace this
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }
    else if ( (KFDoorMover(A) != none || VSize(A.Location-Location) <= 250) && !bDecapitated ) {
        bShotAnim = true;
        SetAnimAction('ZombieBarfMoving');
        RunAttackTimeout = GetAnimDuration('ZombieBarf', 1.0);
        bMovingPukeAttack=true;

        // Randomly send out a message about Bloat Vomit burning(3% chance)
        if ( FRand() < 0.03 && KFHumanPawn(A) != none && PlayerController(KFHumanPawn(A).Controller) != none ) {
            PlayerController(KFHumanPawn(A).Controller).Speech('AUTO', 7, "");
        }
    }
}

//ZombieBarf animation triggers this
function SpawnTwoShots() {
    super.SpawnTwoShots();
    bAmIBarfing= true;
}

simulated function AnimEnd(int Channel) {
    local name  Sequence;
    local float Frame, Rate;


    GetAnimParams( ExpectingChannel, Sequence, Frame, Rate );

    logToPlayer(2,Level.TimeSeconds$" "$self$" "$GetStateName()$" AnimEnd for Exp Chan "$ExpectingChannel$" = "$Sequence$" Channel: "$Channel);
    logToPlayer(2,""$bAmIBarfing);

    super.AnimEnd(Channel);
    
    if(Sequence == 'ZombieBarf')
        bAmIBarfing= false;
}

defaultproperties {
    logLevel= 0;
    bileCoolDownMax= 0.50;
}
