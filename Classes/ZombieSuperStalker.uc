class ZombieSuperStalker extends ZombieStalker_STANDARD;

/** @deprecated in v2.3.2 */
var SuperZombieMut mut;

/**
 *  Changed the Tick function to match the gorefasts, so she can do a moving melee attack
 */
simulated function Tick(float DeltaTime) {
    super.Tick(DeltaTime);
    // Keep the stalker moving toward its target when attacking
    if( Role == ROLE_Authority && bShotAnim && !bWaitForAnim ) {
        if( LookTarget!=None ) {
            Acceleration = AccelRate * Normal(LookTarget.Location - Location);
        }
    }
}

/**
 *  Stalker will always claw and move
 */
function RangedAttack(Actor A) {
    if ( bShotAnim || Physics == PHYS_Swimming)
        return;
    else if ( CanAttack(A) ) {
        bShotAnim = true;
        SetAnimAction('ClawAndMove');
        //PlaySound(sound'Claw2s', SLOT_None); KFTODO: Replace this
        return;
    }
}

// Copied from the Gorefast code
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

// Copied from the Gorefast code, updated with the stalker attacks
// Handle playing the anim action on the upper body only if we're attacking and moving
simulated function int AttackAndMoveDoAnimAction( name AnimName ) {
    local int meleeAnimIndex;
    local float duration;

    if( AnimName == 'ClawAndMove' ) {
        meleeAnimIndex = Rand(3);
        AnimName = meleeAnims[meleeAnimIndex];
        CurrentDamtype = ZombieDamType[meleeAnimIndex];

        duration= GetAnimDuration(AnimName, 1.0);
    }

    if( AnimName=='StalkerSpinAttack' || AnimName=='StalkerAttack1' || AnimName=='JumpAttack') {
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
        PlayAnim(AnimName,, 0.1, 1);

        return 1;
    }

    return super.DoAnimAction( AnimName );
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
    local bool result;

    result= super.MeleeDamageTarget(hitdamage, pushdir);
    if (result && KFPawn(Controller.Target) != none) {
        class'SZReplicationInfo'.static
                .findSZri(KFPawn(Controller.Target).PlayerReplicationInfo)
                .setBleeding(Self);
    }
    return result;
}

defaultproperties {
    MenuName= "Super Stalker"
    MeleeDamage= 5;
}
