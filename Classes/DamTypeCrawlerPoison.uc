class DamTypeCrawlerPoison extends DamTypeZombieAttack;

defaultproperties {
     DeathString="%o was poisoned by %k."
     FemaleSuicide="%o ate herself."
     MaleSuicide="%o ate himself."
     PawnDamageEmitter=Class'ROEffects.ROBloodPuff'
     LowGoreDamageEmitter=Class'ROEffects.ROBloodPuffNoGore'
     LowDetailEmitter=Class'ROEffects.ROBloodPuffSmall'
}
