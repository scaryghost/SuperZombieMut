class ZombieSuperFP extends ZombieFleshPound;

var int logLevel;
var float rageDamage, rageDamageThreshold;
var bool bRageAgain;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    rageDamageThreshold= 25.0;
    rageDamage= 0.0;
    brageAgain= false;
    logToPlayer(1,"Level of agression, 12!");
}

simulated function Tick(float DeltaTime) {
    super.Tick(DeltaTime);
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

function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
    local bool didIHit;
    
    didIHit= super.MeleeDamageTarget(hitdamage, pushdir);
    SuperFPZombieController(Controller).bMissTarget= 
        SuperFPZombieController(Controller).bMissTarget || !didIHit;
    logToPlayer(2,"Did I hit?  "$didIHit);
    logToPlayer(2,"Am I beginning to get mad? "$IsInState('BeginRaging'));
    return didIHit;
}

simulated event SetAnimAction(name NewAction) {
    super.SetAnimAction(newAction);
    SuperFPZombieController(Controller).bAttackedTarget= 
	    (NewAction == 'Claw') || (NewAction == 'DoorBash');
}

state RageCharging {
//Not sure why we are Ignoring StartCharging()
//but best leave the code as is
Ignores StartCharging;

    function PlayDirectionalHit(Vector HitLoc) {
        super.PlayDirectionalHit(HitLoc);
    }

    function bool CanGetOutOfWay() {
        return super.CanGetOutOfWay();
    }

    // Don't override speed in this state
    function bool CanSpeedAdjust() {
        return super.CanSpeedAdjust();
    }

	function BeginState() {
        super.BeginState();
        LogToPlayer(2,"I'm MAD!");
	}

	function EndState()	{
        super.EndState();
        LogToPlayer(2,"I'm Calm!");
	}

	function Tick( float Delta ) {
        super.Tick(Delta);
	}

	function Bump( Actor Other ) {
        super.Bump(Other);
	}

	// If fleshie hits his target on a charge, then he should settle down for abit.
	function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
		local bool RetVal,bWasEnemy;
        local float oldEnemyHealth;
        local bool bAttackingHuman;

        bAttackingHuman= (KFHumanPawn(Controller.Target) != none);

        if (bAttackingHuman) {
            oldEnemyHealth= KFHumanPawn(Controller.Target).Health;
            LogToPlayer(2,"Old hp: "$oldEnemyHealth);
        }

		bWasEnemy = (Controller.Target==Controller.Enemy);
		RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage*1.75, pushdir*3);

        if (bAttackingHuman) {
            rageDamage+= oldEnemyHealth - KFHumanPawn(Controller.Target).Health;
            logToPlayer(2,"Damage dealt: "$rageDamage);
            logToPlayer(2,"New hp:"$KFHumanPawn(Controller.Target).Health);
        }

       
		if(RetVal && bWasEnemy) {
            if(bAttackingHuman && rageDamage < rageDamageThreshold) {
                //This chunk of code is copied from StartCharging()
                //Calling the function here would not work as the fp 
                //would not do the rage animation, but would keep
                //hitting the player
                SetAnimAction('PoundRage');
                Acceleration = vect(0,0,0);
                bShotAnim = true;
                Velocity.X = 0;
                Velocity.Y = 0;
                Controller.GoToState('WaitForAnim');
                KFMonsterController(Controller).bUseFreezeHack = True;
                FleshpoundZombieController(Controller).SetPoundRageTimout(GetAnimDuration('PoundRage'));
                GotoState('BeginRaging');
            } else {
                rageDamage= 0.0;
                GoToState('');
            }
        }

		return RetVal;
	}
}

defaultproperties {
    logLevel= 0
    MenuName="Super FleshPound"
    ControllerClass=Class'SuperZombie.SuperFPZombieController'
}
