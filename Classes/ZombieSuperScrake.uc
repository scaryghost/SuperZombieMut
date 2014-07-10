class ZombieSuperScrake extends ZombieScrake_STANDARD;

/** maxTimesFlipOver    How many times the scrake can be stunned.  When it is -1, the the scrake cannot be stunned */
var int maxTimesFlipOver;
/** bIsFlippedOver  True if the scrake is flipped over, i.e. stunned */
var bool bIsFlippedOver;

/**
 *  Changed so the scrake only flips over a fixed number of times
 */
function bool FlipOver() {
    local bool bCalledFlipOver;
    local name  Sequence;
    local float Frame, Rate;

    GetAnimParams(ExpectingChannel, Sequence, Frame, Rate);
    maxTimesFlipOver--;
    bCalledFlipOver= ((bShotAnim && (Sequence == 'KnockDown' || Sequence == 'SawZombieIdle') || maxTimesFlipOver >= 0) && super.FlipOver());
    bIsFlippedOver= bIsFlippedOver || bCalledFlipOver;
    return bCalledFlipOver;
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex) {
    local bool bIsHeadShot;
    local int oldHealth;
    local float headShotCheckScale;

    oldHealth= Health;
    if (class<KFWeaponDamageType>(damageType) != none && class<KFWeaponDamageType>(damageType).default.bCheckForHeadShots) {
        headShotCheckScale= 1.0;
        if (class<DamTypeMelee>(damageType) != none) {
            headShotCheckScale*= 1.25;
        }
        bIsHeadShot = IsHeadShot(Hitlocation, normal(Momentum), 1.0);
    }
    Super.takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType, HitIndex);
    
    /** Break stun if the scrake is hit with a weak attack or not head shotted with an attack that can head shot */
    if( bIsFlippedOver && Health>0 && (!bIsHeadShot && class<KFWeaponDamageType>(damageType) != none && 
            class<KFWeaponDamageType>(damageType).default.bCheckForHeadShots || (oldHealth - Health) * 1.5 <=(float(Default.Health)))) {
        bShotAnim= false;
        bIsFlippedOver= false;
        SetAnimAction(WalkAnims[0]);
        SawZombieController(Controller).GoToState('ZombieHunt');
    }

} 

function PlayDirectionalHit(Vector HitLoc) {
    local Vector X,Y,Z, Dir;
    local KFPawn KFP;
    local bool bCanMeleeFlinch;

    GetAxes(Rotation, X,Y,Z);
    HitLoc.Z = Location.Z;
    Dir = -Normal(Location - HitLoc);

    if( !HitCanInterruptAction() ) {
        return;
    }

    KFP= KFPawn(LastDamagedBy);
    bCanMeleeFlinch= (VSize(LastDamagedBy.Location - Location) <= (MeleeRange * 2) && ClassIsChildOf(LastDamagedbyType,class 'DamTypeMelee') &&
                 KFP != none && KFPlayerReplicationInfo(KFP.OwnerPRI).ClientVeteranSkill.Static.CanMeleeStun() && LastDamageAmount > (0.10* default.Health));

    // random
    if ( VSize(Location - HitLoc) < 1.0 )
        Dir = VRand();
    else Dir = -Normal(Location - HitLoc);

    if ( Dir dot X > 0.7 || Dir == vect(0,0,0)) {
        if( LastDamagedBy!=none && LastDamageAmount>0 && StunsRemaining != 0) {
            if (LastDamageAmount >= (0.5 * default.Health) || bCanMeleeFlinch) {
                SetAnimAction(HitAnims[Rand(3)]);
                bSTUNNED = true;
                SetTimer(StunTime,false);
                StunsRemaining--;
            }
            else if (LastDamageAmount < (0.5 * default.Health) && !ClassIsChildOf(LastDamagedbyType,class 'DamTypeMelee')) {
                /** Non-zerker with melee weapons cannot interrupt a scrake attack */
                SetAnimAction(KFHitFront);
            }
        }
    }
    else if ( Dir Dot X < -0.7 )
        SetAnimAction(KFHitBack);
    else if ( Dir Dot Y > 0 )
        SetAnimAction(KFHitRight);
    else SetAnimAction(KFHitLeft);
}

defaultproperties {
    maxTimesFlipOver= 1
    bIsFlippedOver= false
    MenuName= "Super Scrake"
}
