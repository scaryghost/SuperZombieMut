class Types extends Object
    abstract;

struct WeaponDamage {
    var class<DamageType> dmgType;
    var int amount;
};

struct Resistance {
    var class<DamageType> dmgType;
    var float scale;
};

