class ZombieSuperFP extends ZombieFleshPound;

var int logLevel;
var float rageDamage, rageDamageLimit, rageShield, rageShieldLimit;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    rageDamageLimit= Max(35.0*1.75*DifficultyDamageModifer(),1.0);
    rageShieldLimit= Max(45.0*DifficultyDamageModifer(),1.0);
    LogToPlayer(2,"dmg limit: "$rageDamageLimit);
    LogToPlayer(2,"shield limit: "$rageShieldLimit);
    rageDamage= 0.0;
    rageShield= 0.0;
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

state BeginRaging {
    Ignores StartCharging;

    function bool CanGetOutOfWay() {
        return false;
    }

    simulated function bool HitCanInterruptAction() {
        return false;
    }

	function Tick( float Delta ) {
        Acceleration = vect(0,0,0);

        global.Tick(Delta);
	}

	function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
   		local bool RetVal,bWasEnemy;
        local float oldEnemyHealth, oldEnemyShield;
        local bool bAttackingHuman;

        bAttackingHuman= (KFHumanPawn(Controller.Target) != none);

        if (bAttackingHuman) {
            oldEnemyHealth= KFHumanPawn(Controller.Target).Health;
            oldEnemyShield= KFHumanPawn(Controller.Target).ShieldStrength;
            LogToPlayer(2,"Old hp: "$oldEnemyHealth);
            LogToPlayer(2,"Old shield: "$oldEnemyShield);
        }

		bWasEnemy = (Controller.Target==Controller.Enemy);
		RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage, pushdir*3);

        if (bAttackingHuman) {
            rageDamage+= oldEnemyHealth - KFHumanPawn(Controller.Target).Health;
            rageShield+= oldEnemyShield - KFHumanPawn(Controller.Target).ShieldStrength;
            logToPlayer(2,"Total dmg dealt: "$rageDamage);
            logToPlayer(2,"New hp:"$KFHumanPawn(Controller.Target).Health);
            logToPlayer(2,"New Shield:"$KFHumanPawn(Controller.Target).ShieldStrength);
        }
       
		if(RetVal && bWasEnemy) {
            if(bAttackingHuman && (oldEnemyShield <= 0.0 && rageDamage < rageDamageLimit || 
                (rageShield < rageShieldLimit && rageDamage < rageDamageLimit * 0.175))) {
                GotoState('RageCharging');
            } else {
                rageDamage= 0.0;
                rageShield= 0.0;
                LogToPlayer(2,"I am calm for good now");
                bChargingPlayer = False;
                bFrustrated = false;

                FleshPoundZombieController(Controller).RageFrustrationTimer = 0;

        		if( Health>0 ) {
        			GroundSpeed = GetOriginalGroundSpeed();
        		}

        		if( Level.NetMode!=NM_DedicatedServer )
        			ClientChargingAnims();

        		NetUpdateTime = Level.TimeSeconds - 1;
                SetAnimAction(MovementAnims[0]);
                Controller.GoToState('ZombieHunt');
                GoToState('');
            }
        }

		return RetVal;
	}
Begin:
    Sleep(GetAnimDuration('PoundRage'));
    GotoState('RageCharging');
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
        local float oldEnemyHealth, oldEnemyShield;
        local bool bAttackingHuman;

        bAttackingHuman= (KFHumanPawn(Controller.Target) != none);

        if (bAttackingHuman) {
            oldEnemyHealth= KFHumanPawn(Controller.Target).Health;
            oldEnemyShield= KFHumanPawn(Controller.Target).ShieldStrength;
            LogToPlayer(2,"Old hp: "$oldEnemyHealth);
            LogToPlayer(2,"Old shield: "$oldEnemyShield);
        }

		bWasEnemy = (Controller.Target==Controller.Enemy);
		RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage*1.75, pushdir*3);

        if (bAttackingHuman) {
            rageDamage+= oldEnemyHealth - KFHumanPawn(Controller.Target).Health;
            rageShield+= oldEnemyShield - KFHumanPawn(Controller.Target).ShieldStrength;
            logToPlayer(2,"Total dmg dealt: "$rageDamage);
            logToPlayer(2,"New hp:"$KFHumanPawn(Controller.Target).Health);
            logToPlayer(2,"New Shield:"$KFHumanPawn(Controller.Target).ShieldStrength);
        }

       
		if(RetVal && bWasEnemy) {
            if(bAttackingHuman && (oldEnemyShield <= 0.0 && rageDamage < rageDamageLimit || 
                (rageShield < rageShieldLimit && rageDamage < rageDamageLimit * 0.175))) {
                //This chunk of code is copied from StartCharging()
                //Calling the function here would not work as the fp 
                //would not do the rage animation, but would keep
                //hitting the player
                LogToPlayer(2,"Ah am still mad!");
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
                rageShield= 0.0;
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

//
//Medic:
//5/15
//6/20

//Berserker:
//11/35
//15/55

//Everyone else:
//20/62
//26/80 - 21/65 - 14/45 - 4/12.75
