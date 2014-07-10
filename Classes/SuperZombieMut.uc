class SuperZombieMut extends Mutator
    config(SuperZombieMut);

/** Struct that stores what a specific zombie should be replaced with */
struct oldNewZombiePair {
    var string oldClass;
    var string newClass;
    var bool bReplace;
};

/** Struct that stores all the property attributes */
struct propertyDescPair {
    var string property;
    var string longDescription;
    var string shortDescription;
};

/** Configuration variables that store whether or not to replace the specimen */
var() config bool bReplaceCrawler, bReplaceStalker, bReplaceClot, bReplaceGorefast, bReplaceBloat, 
                bReplaceSiren, bReplaceHusk, bReplaceScrake, bReplaceFleshpound, bReplaceBoss;
var() config bool forceFpSecret;

/** Array that stores all the replacement pairs */
var array<oldNewZombiePair> replacementArray;
/** Array that stores all the properties and their descriptions */
var array<propertyDescPair> propDescripArray;
var array<String> replCaps;

var BleedingPawns BP;
var PoisonedPawns PP;
var array<class<DamageType> > fpExtraResistantTypes;

/** Replaces the zombies in the given squadArray */
function replaceSpecialSquad(out array<KFMonstersCollection.SpecialSquad> squadArray) {
    local int i,j,k;

    for(j=0; j<squadArray.Length; j++) {
        for(i=0;i<squadArray[j].ZedClass.Length; i++) {
            for(k=0; k<replacementArray.Length; k++) {
                if(replacementArray[k].bReplace && InStr(Caps(squadArray[j].ZedClass[i]), replCaps[k]) != -1) {
                    squadArray[j].ZedClass[i]=  replacementArray[k].newClass;
                }
            }
        }
    }
}

function addImmuneDamageType(class<DamageType> newType) {
    local int i;

    for(i= 0; i < fpExtraResistantTypes.Length && fpExtraResistantTypes[i] != newType; i++) {
    }
    if (i >= fpExtraResistantTypes.Length) {
        fpExtraResistantTypes[fpExtraResistantTypes.Length]= newType;
    }
}

function PostBeginPlay() {
    local int i,k;
    local KFGameType KF;
    local array<String> mcCaps;

    KF= KFGameType(Level.Game);
    if (KF == none) {
        Destroy();
        return;
    }
    if (KF.MonsterCollection == class'KFGameType'.default.MonsterCollection) {
        KF.MonsterCollection= class'SZMonstersCollection';
    }
    AddToPackageMap("SuperZombieMut");

    PP= spawn(class'PoisonedPawns');
    BP= spawn(class'BleedingPawns');

    replacementArray[0].bReplace= bReplaceFleshpound;
    replacementArray[1].bReplace= bReplaceGorefast;
    replacementArray[2].bReplace= bReplaceStalker;
    replacementArray[3].bReplace= bReplaceSiren;
    replacementArray[4].bReplace= bReplaceScrake;
    replacementArray[5].bReplace= bReplaceHusk;
    replacementArray[6].bReplace= bReplaceCrawler;
    replacementArray[7].bReplace= bReplaceBloat;
    replacementArray[8].bReplace= bReplaceClot;

    for(i= 0; i < KF.MonsterCollection.default.MonsterClasses.Length; i++) {
        mcCaps[mcCaps.Length]= Caps(KF.MonsterCollection.default.MonsterClasses[i].MClassName);
    }
    for(i= 0; i < replacementArray.Length; i++) {
        replCaps[replCaps.Length]= Caps(replacementArray[i].oldClass);
    }
    //Replace all instances of the old specimens with the new ones 
    for(i= 0; i < mcCaps.Length; i++) {
        for(k= 0; k < replCaps.Length; k++) {
            if (replacementArray[k].bReplace && InStr(mcCaps[i], replCaps[k]) != -1) {
                log("SuperZombies - Replacing"@KF.MonsterCollection.default.MonsterClasses[i].MClassName);
                KF.MonsterCollection.default.MonsterClasses[i].MClassName= replacementArray[k].newClass;
            }
        }
    }

    //Replace the special squad arrays
    replaceSpecialSquad(KF.MonsterCollection.default.ShortSpecialSquads);
    replaceSpecialSquad(KF.MonsterCollection.default.NormalSpecialSquads);
    replaceSpecialSquad(KF.MonsterCollection.default.LongSpecialSquads);
    replaceSpecialSquad(KF.MonsterCollection.default.FinalSquads);   

    if (bReplaceBoss) {
        KF.MonsterCollection.default.EndGameBossClass= "SuperZombieMut.ZombieSuperBoss";
    }
    if (bReplaceStalker) {
        KF.MonsterCollection.default.FallbackMonsterClass= "SuperZombieMut.ZombieSuperStalker";
    }
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant) {
    local PlayerReplicationInfo pri;
    local SZReplicationInfo szRI;
    local int i;

    if (PlayerReplicationInfo(Other) != none && PlayerReplicationInfo(Other).Owner != none) {
        pri= PlayerReplicationInfo(Other);
        szRI= spawn(class'SZReplicationInfo', pri.Owner);
        szRI.ownerPRI= pri;
    } if (ZombieSuperCrawler(Other) != none) {
        ZombieSuperCrawler(Other).mut= self;
    } else if (ZombieSuperStalker(Other) != none) {
        ZombieSuperStalker(Other).mut= self;
    } else if (ZombieSuperFP(Other) != none && (forceFpSecret || 
            (KFGameType(Level.Game).KFGameLength != KFGameType(Level.Game).GL_Custom && Level.Game.NumPlayers <= 6))) {
        for(i= 0; i < fpExtraResistantTypes.Length; i++) {
            ZombieSuperFP(Other).extraResistantTypes[i]= fpExtraResistantTypes[i];
        }
        ZombieSuperFP(Other).mutRef= self;
    }
    return true;
}

static function FillPlayInfo(PlayInfo PlayInfo) {
    local string mutConfigGroup;
    local int i;

    Super.FillPlayInfo(PlayInfo);
   
    mutConfigGroup= "Super Zombie Config"; 
    for(i= 0; i<default.propDescripArray.Length;i++) {
        PlayInfo.AddSetting(mutConfigGroup, default.propDescripArray[i].property, 
        default.propDescripArray[i].shortDescription, 0, 0, "Check");
    }
    PlayInfo.AddSetting(mutConfigGroup, "forceFpSecret", "Enable fp secret ability for sandbox or 7+ player games", 0, 0, "Check",,,,true);
}

static event string GetDescriptionText(string property) {
    local int i;

    for(i=0;i<default.propDescripArray.Length;i++) {
        if(default.propDescripArray[i].property == property) {
            return default.propDescripArray[i].longDescription;
        }
    }
    if (property == "forceFpSecret") {
        return "By default, fp secret ability is disabled for sandbox and 7+ player games since it is intended for normal KF games";
    }
    return Super.GetDescriptionText(property);
}

simulated function Tick(float DeltaTime) {
    local PlayerController PC;
 
    PC = Level.GetLocalPlayerController();
    if (PC != None) { 
        PC.Player.InteractionMaster.AddInteraction("SuperZombieMut.SZInteraction", PC.Player);
    }
    Disable('Tick');
}

defaultproperties {
    GroupName="KFSuperZombieMut"
    FriendlyName="Super Zombies v2.2.1"
    Description="Gives specimens new abilities and behaviors."

    RemoteRole= ROLE_SimulatedProxy
    bAlwaysRelevant= true

    replacementArray(0)=(oldClass="KFChar.ZombieFleshPound",newClass="SuperZombieMut.ZombieSuperFP")
    replacementArray(1)=(oldClass="KFChar.ZombieGorefast",newClass="SuperZombieMut.ZombieSuperGorefast")
    replacementArray(2)=(oldClass="KFChar.ZombieStalker",newClass="SuperZombieMut.ZombieSuperStalker")
    replacementArray(3)=(oldClass="KFChar.ZombieSiren",newClass="SuperZombieMut.ZombieSuperSiren")
    replacementArray(4)=(oldClass="KFChar.ZombieScrake",newClass="SuperZombieMut.ZombieSuperScrake")
    replacementArray(5)=(oldClass="KFChar.ZombieHusk",newClass="SuperZombieMut.ZombieSuperHusk")
    replacementArray(6)=(oldClass="KFChar.ZombieCrawler",newClass="SuperZombieMut.ZombieSuperCrawler")
    replacementArray(7)=(oldClass="KFChar.ZombieBloat",newClass="SuperZombieMut.ZombieSuperBloat")
    replacementArray(8)=(oldClass="KFChar.ZombieClot",newClass="SuperZombieMut.ZombieSuperClot")

    propDescripArray(0)=(property="bReplaceCrawler",longDescription="Replace Crawlers with Super Crawlers",shortDescription="Replace Crawlers")
    propDescripArray(1)=(property="bReplaceStalker",longDescription="Replace Stalkers with Super Stalkers",shortDescription="Replace Stalkers")
    propDescripArray(2)=(property="bReplaceClot",longDescription="Replace Clots with Super Clots",shortDescription="Replace Clots")
    propDescripArray(3)=(property="bReplaceGorefast",longDescription="Replace Gorefasts with Super Gorefasts",shortDescription="Replace Gorefasts")
    propDescripArray(4)=(property="bReplaceBloat",longDescription="Replace Bloats with Super Bloats",shortDescription="Replace Bloats")
    propDescripArray(5)=(property="bReplaceSiren",longDescription="Replace Sirens with Super Sirens",shortDescription="Replace Sirens")
    propDescripArray(6)=(property="bReplaceHusk",longDescription="Replace Husks with Super Husks",shortDescription="Replace Husks")
    propDescripArray(7)=(property="bReplaceScrake",longDescription="Replace Scrakes with Super Scrakes",shortDescription="Replace Scrakes")
    propDescripArray(8)=(property="bReplaceFleshpound",longDescription="Replace Fleshpounds with Super Fleshpounds",shortDescription="Replace Fleshpounds")
    propDescripArray(9)=(property="bReplaceBoss",longDescription="Replace the Patriarch with the Super Patriarch",shortDescription="Replace Patriarch")

    bReplaceCrawler=true
    bReplaceStalker=true
    bReplaceClot=true
    bReplaceGorefast=true
    bReplaceBloat=true
    bReplaceSiren=true
    bReplaceHusk=true
    bReplaceScrake=true
    bReplaceFleshpound=true
    bReplaceBoss=true
}
