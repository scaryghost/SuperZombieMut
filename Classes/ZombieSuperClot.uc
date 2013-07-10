class ZombieSuperClot extends ZombieClot;

var SZReplicationInfo disabledPawnRepInfo;
/** max num of clots that can be grappling a zerker before grab immunity is overridden */
var int grappleLimit;

function detachFromTarget() {
    if (DisabledPawn != none) {
        disabledPawnRepInfo.numClotsAttached--;
        DisabledPawn.bMovementDisabled= false;
        DisabledPawn= none;
        disabledPawnRepInfo= none;
    }
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
            disabledPawnRepInfo.numClotsAttached++;
            if (KFPlayerReplicationInfo(KFP.PlayerReplicationInfo) == none ||
                KFP.GetVeteran().static.CanBeGrabbed(KFPlayerReplicationInfo(KFP.PlayerReplicationInfo), self) || 
                disabledPawnRepInfo.numClotsAttached > grappleLimit) {
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