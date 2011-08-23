class SuperZombieMut extends Mutator
    config(SuperZombieMut);

/**
 *  Struct that stores what a specific zombie should be replaced with
 */
struct oldNewZombiePair {
    var string oldClass;
    var string newClass;
    var bool bReplace;
};

/**
 *  Struct that stores all the property attributes
 */
struct propertyDescPair {
    var string property;
    var string longDescription;
    var string shortDescription;
};

/**
 *  Configuration variables that store whether or not to replace the specimen
 */
var() config bool bReplaceCrawler, bReplaceStalker, bReplaceGorefast, bReplaceBloat, 
                bReplaceSiren, bReplaceHusk, bReplaceScrake, bReplaceFleshpound, bReplaceBoss;
/**
 *  Array that stores all the replacement pairs
 */
var array<oldNewZombiePair> replacementArray;

/**
 *  Array that stores all the properties and their descriptions
 */
var array<propertyDescPair> propDescripArray;

/**
 *  Replaces the zombies in the given squadArray
 */
function replaceSpecialSquad(out array<KFGameType.SpecialSquad> squadArray) {
    local int i,j,k;
    local oldNewZombiePair replacementValue;
    for(j=0; j<squadArray.Length; j++) {
        for(i=0;i<squadArray[j].ZedClass.Length; i++) {
            for(k=0; k<replacementArray.Length; k++) {
                replacementValue= replacementArray[k];
                if(replacementValue.bReplace && squadArray[j].ZedClass[i] ~= replacementValue.oldClass) {
                    squadArray[j].ZedClass[i]=  replacementValue.newClass;
                }
            }
        }
    }
}

function PostBeginPlay() {
    local int i,k;
    local KFGameType KF;
    local oldNewZombiePair replacementValue;

    KF = KFGameType(Level.Game);
    if (Level.NetMode != NM_Standalone)
        AddToPackageMap("SuperZombieMut");

    if (KF == none) {
        Destroy();
        return;
    }

    replacementArray[0].bReplace= bReplaceFleshpound;
    replacementArray[1].bReplace= bReplaceGorefast;
    replacementArray[2].bReplace= bReplaceStalker;
    replacementArray[3].bReplace= bReplaceSiren;
    replacementArray[4].bReplace= bReplaceScrake;
    replacementArray[5].bReplace= bReplaceHusk;
    replacementArray[6].bReplace= bReplaceCrawler;
    replacementArray[7].bReplace= bReplaceBloat;

    //Replace all instances of the old specimens with the new ones 
    for( i=0; i<KF.StandardMonsterClasses.Length; i++) {
        for(k=0; k<replacementArray.Length; k++) {
            replacementValue= replacementArray[k];
            //Use ~= for case insensitive compare
            if (replacementValue.bReplace && KF.StandardMonsterClasses[i].MClassName ~= replacementValue.oldClass) {
                KF.StandardMonsterClasses[i].MClassName= replacementValue.newClass;
            }
        }
    }

    //Replace the special squad arrays
    replaceSpecialSquad(KF.ShortSpecialSquads);
    replaceSpecialSquad(KF.NormalSpecialSquads);
    replaceSpecialSquad(KF.LongSpecialSquads);
    replaceSpecialSquad(KF.FinalSquads);

    if (bReplaceBoss) {
        KF.EndGameBossClass= "SuperZombieMut.ZombieSuperBoss";
    }
    if (bReplaceStalker) {
        KF.FallbackMonsterClass= "SuperZombieMut.ZombieSuperStalker";
    }

    SetTimer(0.1, false);
}

function Timer() {
    Destroy();
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
}

static event string GetDescriptionText(string property) {
    local int i;

    for(i=0;i<default.propDescripArray.Length;i++) {
        if(default.propDescripArray[i].property == property) {
            return default.propDescripArray[i].longDescription;
        }
    }

    return Super.GetDescriptionText(property);
}

defaultproperties {
    GroupName="KFSuperZombieMut"
    FriendlyName="Super Zombie"
    Description="Alters the behavior of the specimens.  This mutator's version is 1.7.1."
    replacementArray(0)=(oldClass="KFChar.ZombieFleshPound",newClass="SuperZombieMut.ZombieSuperFP",bReplace=false)
    replacementArray(1)=(oldClass="KFChar.ZombieGorefast",newClass="SuperZombieMut.ZombieSuperGorefast",bReplace=false)
    replacementArray(2)=(oldClass="KFChar.ZombieStalker",newClass="SuperZombieMut.ZombieSuperStalker",bReplace=false)
    replacementArray(3)=(oldClass="KFChar.ZombieSiren",newClass="SuperZombieMut.ZombieSuperSiren",bReplace=false)
    replacementArray(4)=(oldClass="KFChar.ZombieScrake",newClass="SuperZombieMut.ZombieSuperScrake",bReplace=false)
    replacementArray(5)=(oldClass="KFChar.ZombieHusk",newClass="SuperZombieMut.ZombieSuperHusk",bReplace=false)
    replacementArray(6)=(oldClass="KFChar.ZombieCrawler",newClass="KFChar.ZombieShade",bReplace=false)
    replacementArray(7)=(oldClass="KFChar.ZombieBloat",newClass="SuperZombieMut.ZombieSuperBloat",bReplace=false)
    propDescripArray(0)=(property="bReplaceCrawler",longDescription="Replace Crawlers with Shades",shortDescription="Replace Crawlers")
    propDescripArray(1)=(property="bReplaceStalker",longDescription="Replace Stalkers with SuperStalkers",shortDescription="Replace Stalkers")
    propDescripArray(2)=(property="bReplaceGorefast",longDescription="Replace Gorefasts with SuperGorefasts",shortDescription="Replace Gorefasts")
    propDescripArray(3)=(property="bReplaceBloat",longDescription="Replace Bloats with SuperBloats",shortDescription="Replace Bloats")
    propDescripArray(4)=(property="bReplaceSiren",longDescription="Replace Sirens with SuperSirens",shortDescription="Replace Sirens")
    propDescripArray(5)=(property="bReplaceHusk",longDescription="Replace Husks with SuperHusks",shortDescription="Replace Husks")
    propDescripArray(6)=(property="bReplaceScrake",longDescription="Replace Scrakes with SuperScrakes",shortDescription="Replace Scrakes")
    propDescripArray(7)=(property="bReplaceFleshpound",longDescription="Replace Fleshpounds with SuperFleshpounds",shortDescription="Replace Fleshpounds")
    propDescripArray(8)=(property="bReplaceBoss",longDescription="Replace the Patriarch with the SuperPatriarch",shortDescription="Replace Patriarch")
}
