class ZombieSuperClot extends ZombieClot_STANDARD;

var SZReplicationInfo disabledPawnRepInfo;
/** max num of clots that can be grappling a zerker before grab immunity is overridden */
var int grappleLimit;
var bool ignoreBodyShotResistance;

function detachFromTarget() {
    if (DisabledPawn != none && disabledPawnRepInfo != none) {
        disabledPawnRepInfo.numClotsAttached--;
        DisabledPawn.bMovementDisabled= false;
        DisabledPawn= none;
        disabledPawnRepInfo= none;
    }
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex) {
    local float headShotCheckScale;
    local class<KFWeaponDamageType> kfDmgTypeClass;

    kfDmgTypeClass= class<KFWeaponDamageType>(damageType);
    if (!ignoreBodyShotResistance && !bDecapitated && kfDmgTypeClass != none && (kfDmgTypeClass.default.bCheckForHeadShots && !ClassIsChildOf(kfDmgTypeClass, class'DamTypeBurned'))) {
        headShotCheckScale= 1.0;
        if (class<DamTypeMelee>(damageType) != none) {
            headShotCheckScale*= 1.25;
        }
        if (!IsHeadShot(Hitlocation, normal(Momentum), 1.0)) damage*= 0.5;
    }
    Super.takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType, HitIndex);
}

function ClawDamageTarget() {
    local vector PushDir;
    local KFPawn KFP;
    local float UsedMeleeDamage;


    if (MeleeDamage > 1) {
       UsedMeleeDamage = (MeleeDamage - (MeleeDamage * 0.05)) + (MeleeDamage * (FRand() * 0.1));
    }
    else {
       UsedMeleeDamage = MeleeDamage;
    }

    // If zombie has latched onto us...
    if (MeleeDamageTarget( UsedMeleeDamage, PushDir)) {
        KFP = KFPawn(Controller.Target);

        PlaySound(MeleeAttackHitSound, SLOT_Interact, 2.0);

        if (!bDecapitated && KFP != none) {
            detachFromTarget();
            DisabledPawn= KFP;
            disabledPawnRepInfo= class'SZReplicationInfo'.static.findSZri(KFP.PlayerReplicationInfo);
            if (disabledPawnRepInfo != none) {
                disabledPawnRepInfo.numClotsAttached++;
            }
            if (KFP.GetVeteran().static.CanBeGrabbed(KFPlayerReplicationInfo(KFP.PlayerReplicationInfo), self) || 
                (disabledPawnRepInfo != none && disabledPawnRepInfo.numClotsAttached > grappleLimit)) {
                DisabledPawn.DisableMovement(GrappleDuration);
            }
        }
    }
}

function RemoveHead() {
    Super(KFMonster).RemoveHead();
    MeleeAnims[0] = 'Claw';
    MeleeAnims[1] = 'Claw';
    MeleeAnims[2] = 'Claw2';

    MeleeDamage *= 2;
    MeleeRange *= 2;

    detachFromTarget();
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation) {
    detachFromTarget();
    super(KFMonster).Died(Killer, damageType, HitLocation);
}

simulated function Destroyed() {
    super(KFMonster).Destroyed();
    detachFromTarget();
}

simulated function Tick(float DeltaTime) {
    super(KFMonster).Tick(DeltaTime);

    if (bShotAnim && Role == ROLE_Authority) {
        if (LookTarget!=None) {
            Acceleration = AccelRate * Normal(LookTarget.Location - Location);
        }
    }

    if (Role == ROLE_Authority && bGrappling) {
        if (Level.TimeSeconds > GrappleEndTime) {
            bGrappling = false;
        }
    }

    // if we move out of melee range, stop doing the grapple animation
    if (bGrappling && LookTarget != none) {
        if (VSize(LookTarget.Location - Location) > MeleeRange + CollisionRadius + LookTarget.CollisionRadius) {
            bGrappling= false;
            AnimEnd(1);
            if (LookTarget == DisabledPawn) {
                detachFromTarget();
            }
        }
    }
}

defaultproperties {
    MenuName= "Super Clot"
    grappleLimit= 1
}
