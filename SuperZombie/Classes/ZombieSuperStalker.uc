class ZombieSuperStalker extends ZombieStalker;

var int logLevel;
var float meleeCoolDownTimer;
var float defaultCoolDown;
var bool bMeleeCoolDown;

simulated function PostBeginPlay() {
    logToPlayer(1,"Spawning Super Stalker!");
    defaultCoolDown= GetAnimDuration('StalkerAttack1', 1.0);
    meleeCoolDownTimer= defaultCoolDown;
    bMeleeCoolDown= false;
    super.PostBeginPlay();
}

simulated function Tick(float DeltaTime) {
    super.Tick(DeltaTime);
    if(bMeleeCoolDown) {
        meleeCoolDownTimer-= DeltaTime;
    }
    if(meleeCoolDownTimer <= 0) {
        meleeCoolDownTimer= defaultCoolDown;
        bMeleeCoolDown= false;
    }

    logToPlayer(3,"Melee Cooldown: "$meleeCoolDownTimer);
    // Keep the stalker moving toward its target when attacking
	if( Role == ROLE_Authority && bShotAnim && !bWaitForAnim ) {
        if( LookTarget!=None ) {
 	        Acceleration = AccelRate * Normal(LookTarget.Location - Location);
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
	if ( bShotAnim || Physics == PHYS_Swimming)
		return;
	else if ( !bMeleeCoolDown && CanAttack(A) ) {
        bShotAnim = true;
    	SetAnimAction('ClawAndMove');
    	//PlaySound(sound'Claw2s', SLOT_None); KFTODO: Replace this
        bMeleeCoolDown= true;
		return;
	}
}

// Overridden to handle playing upper body only attacks when moving
simulated event SetAnimAction(name NewAction) {
	if( NewAction=='' )
		Return;

    ExpectingChannel = AttackAndMoveDoAnimAction(NewAction);

    bWaitForAnim= false;

	if( Level.NetMode!=NM_Client ) {
		AnimAction = NewAction;
		bResetAnimAct = True;
		ResetAnimActTime = Level.TimeSeconds+0.3;
	}
}


// Handle playing the anim action on the upper body only if we're attacking and moving
simulated function int AttackAndMoveDoAnimAction( name AnimName ) {
	local int meleeAnimIndex;
    local float duration;

    if( AnimName == 'ClawAndMove' )	{
		meleeAnimIndex = Rand(3);
		AnimName = meleeAnims[meleeAnimIndex];
		CurrentDamtype = ZombieDamType[meleeAnimIndex];

        duration= GetAnimDuration(AnimName, 1.0);
        logToPlayer(2,"Melee animation duration: "$duration);
	}

    if( AnimName=='StalkerSpinAttack' || AnimName=='StalkerAttack1' || AnimName=='JumpAttack') {
		AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
		PlayAnim(AnimName,, 0.1, 1);

		return 1;
	}

	return super.DoAnimAction( AnimName );
}

defaultproperties {
    logLevel= 0;
}
