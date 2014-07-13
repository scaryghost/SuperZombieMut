class ZombieSuperFP extends ZombieFleshPound_STANDARD
    dependson(Types);

/**
 *  rageDamage          accumulator that stores how much damage the fleshpound did when enraged
 *  rageDamageLimit     the limit that the accumulator must exceed so the fleshpound will not rage again
 *  rageShield          accumulator that stores how much shield damage the fleshpound did when enraged
 *  rageShieldLimit     the limit the shield accumulator must exceed so the fleshpound will not rage again
 */
var float rageDamage, rageDamageLimit, rageShield, rageShieldLimit;
/**
 * List of damage types the super fp is immune to
 * @deprecated
 * @see resistances
 * @see wpnDamages
 */
var array<class<DamageType> > extraResistantTypes;
/**
 * Damage type of the decapitating blow
 * @deprecated
 */
var class<DamageType> decapDamageType;
var array<Types.Resistance> resistances;
var array<Types.WeaponDamage> wpnDamages;
var SuperZombieMut mutRef;
var float tempHealth;
var bool decapCounted;

/**
 *  totalDamageRageThreshold    max damage that the fleshpound can take before raging
 *  totalRageAccumulator        accumulator to store how much damage the fleshpound has taken
 */
var int totalDamageRageThreshold, totalRageAccumulator;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    rageDamageLimit= Max(35.0*1.75*DifficultyDamageModifer(),1.0);
    rageShieldLimit= Max(45.0*DifficultyDamageModifer(),1.0);
}

/**
 * Overridden to store the decapitating damage type
 */
function RemoveHead() {
    tempHealth= Health;
    super.RemoveHead();
    tempHealth-= fmax(Health, 0);
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex) {
    local float oldHealth, hpDiff;
    local int i;

    for(i= 0; i < resistances.Length && resistances[i].dmgType != damageType; i++) { }
    if (i < resistances.Length) {
        Damage*= resistances[i].scale;
    }
    oldHealth= Health;
    super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, damageType, HitIndex);
    hpDiff= oldHealth - fmax(Health, 0);
    if (decapCounted) {
        hpDiff-= tempHealth;
        tempHealth= 0;
    }
    totalRageAccumulator+= hpDiff;

    if (!decapCounted && bDecapitated) {
        decapCounted= true;
    }
    
    if (damage != 0) {
        for(i= 0; i < wpnDamages.Length && wpnDamages[i].dmgType != damageType; i++) { }
        if (i >= wpnDamages.Length) {
            wpnDamages.Length= i + 1;
            wpnDamages[i].dmgType= damageType;
            wpnDamages[i].amount= hpDiff;
        } else {
            wpnDamages[i].amount+= hpDiff;
        }
    }
    /**
     *  If the fleshpound isn't raging and the accumulator 
     *  has exceeded the threshold, rage and reset the accumulator
     */
	if (!isInState('BeginRaging') && !bDecapitated && 
        totalRageAccumulator >= totalDamageRageThreshold && 
        !bChargingPlayer && (!(bCrispified && bBurnified) || bFrustrated) ) {
        totalRageAccumulator= 0;
        StartCharging();
    }
    if (mutRef != none && Health <= 0) {
        mutRef.addResistances(wpnDamages, HealthMax);
    }
}

/**
 *  Track if all the "hits" the swing animation made contact.  If not 
 *  bMissTarget will be set to true
 */
function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
    local bool didIHit;
    
    didIHit= super.MeleeDamageTarget(hitdamage, pushdir);
    SuperFPZombieController(Controller).bMissTarget= 
        SuperFPZombieController(Controller).bMissTarget || !didIHit;
    return didIHit;
}

/**
 *  Check if the fleshpound was attacking a door or a person
 */
simulated event SetAnimAction(name NewAction) {
    super.SetAnimAction(newAction);
    SuperFPZombieController(Controller).bAttackedTarget= 
        (NewAction == 'Claw') || (NewAction == 'DoorBash');
}

/**
 *  Overwrite the RageCharging state so the fleshpound will 
 *  rage again if he doesn't deal out enough damage.
 */
state RageCharging {
/**
 *  Not sure why we are Ignoring StartCharging()
 *  but best leave the code as is
 */
Ignores StartCharging;
    function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
        local bool RetVal,bWasEnemy;
        local float oldEnemyHealth, oldEnemyShield;
        local bool bAttackingHuman;

        //Only rage again if he was attacking a human
        bAttackingHuman= (KFHumanPawn(Controller.Target) != none);

        if (bAttackingHuman) {
            oldEnemyHealth= KFHumanPawn(Controller.Target).Health;
            oldEnemyShield= KFHumanPawn(Controller.Target).ShieldStrength;
        }

        bWasEnemy = (Controller.Target==Controller.Enemy);
        RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage*1.75, pushdir*3);

        if (bAttackingHuman) {
            rageDamage+= oldEnemyHealth - KFHumanPawn(Controller.Target).Health;
            rageShield+= oldEnemyShield - KFHumanPawn(Controller.Target).ShieldStrength;
        }

       
        if(RetVal && bWasEnemy) {
            /**
             *  If we haven't reached our damage threshold, rage again, 
             *  otherwise reset the accumulators
             */
            if(bAttackingHuman && (oldEnemyShield <= 0.0 && rageDamage < rageDamageLimit || 
                (rageShield < rageShieldLimit && rageDamage < rageDamageLimit * 0.175))) {
                GotoState('RageAgain');
            } else {
                rageDamage= 0.0;
                rageShield= 0.0;
                GoToState('');
            }
        }

        return RetVal;
    }
}


/**
 *  Had to add this temporary state because on local hosts, enraged fp 
 *  attacks call MeleeDamageTarget twice
 */
state RageAgain {

    function bool MeleeDamageTarget(int hitdamage, vector pushdir) {
        local bool RetVal,bWasEnemy;
        local float oldEnemyHealth, oldEnemyShield;
        local bool bAttackingHuman;

        bAttackingHuman= (KFHumanPawn(Controller.Target) != none);

        if (bAttackingHuman) {
            oldEnemyHealth= KFHumanPawn(Controller.Target).Health;
            oldEnemyShield= KFHumanPawn(Controller.Target).ShieldStrength;
        }

        bWasEnemy = (Controller.Target==Controller.Enemy);
        RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage, pushdir*3);

        if (bAttackingHuman) {
            rageDamage+= oldEnemyHealth - KFHumanPawn(Controller.Target).Health;
            rageShield+= oldEnemyShield - KFHumanPawn(Controller.Target).ShieldStrength;
        }
       
        if(RetVal && bWasEnemy) {
            if(bAttackingHuman && (oldEnemyShield <= 0.0 && rageDamage < rageDamageLimit || 
                (rageShield < rageShieldLimit && rageDamage < rageDamageLimit * 0.175))) {
                StartCharging();
            } else {
                rageDamage= 0.0;
                rageShield= 0.0;
                GoToState('');
            }
        }

        return RetVal;
    }

Begin:
    if( Level.NetMode == NM_DedicatedServer ) {
        StartCharging();
    }
}

defaultproperties {
    MenuName="Super FleshPound"
    ControllerClass=Class'SuperFPZombieController'
    totalDamageRageThreshold= 1440
}

