class SuperZombieMut extends Mutator
    config(SuperZombieMut);

struct oldNewZombiePair {
    var string oldClass;
    var string newClass;
    var bool bReplace;
};

struct propertyDescPair {
    var string property;
    var string longDescription;
    var string shortDescription;
};

var() config int debugLogLevel;
var() config bool bReplaceCrawler, bReplaceStalker, bReplaceGorefast, bReplaceBloat, 
                bReplaceSiren, bReplaceHusk, bReplaceScrake, bReplaceFleshpound, bReplaceBoss;
var array<oldNewZombiePair> replacementArray;
var array<propertyDescPair> propDescripArray;

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
		AddToPackageMap("SuperZombie");

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
        KF.EndGameBossClass= "SuperZombie.ZombieSuperBoss";
    }
    if (bReplaceStalker) {
        KF.FallbackMonsterClass= "SuperZombie.ZombieSuperStalker";
    }

    class'ZombieSuperFP'.default.logLevel= debugLogLevel;
    class'ZombieSuperBoss'.default.logLevel= debugLogLevel;
    class'ZombieSuperGorefast'.default.logLevel= debugLogLevel;
    class'ZombieSuperStalker'.default.logLevel= debugLogLevel;
    class'ZombieSuperSiren'.default.logLevel= debugLogLevel;
    class'ZombieSuperScrake'.default.logLevel= debugLogLevel;
    class'ZombieSuperHusk'.default.logLevel= debugLogLevel;
    class'ZombieSuperBloat'.default.logLevel= debugLogLevel;

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
    //debugLogLevel info is stored in index 0
    PlayInfo.AddSetting(mutConfigGroup, default.propDescripArray[0].property, 
            default.propDescripArray[0].shortDescription, 0, 1, "Text", "0.1;0:4",,,true);
    for(i= 1; i<default.propDescripArray.Length;i++) {
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
    debugLogLevel=0;
	GroupName="KFSuperZombieMut"
	FriendlyName="Super Zombie"
	Description="Alters the behavior of the specimens.  This mutator's version is 1.6."
    replacementArray(0)=(oldClass="KFChar.ZombieFleshPound",newClass="SuperZombie.ZombieSuperFP",bReplace=false)
    replacementArray(1)=(oldClass="KFChar.ZombieGorefast",newClass="SuperZombie.ZombieSuperGorefast",bReplace=false)
    replacementArray(2)=(oldClass="KFChar.ZombieStalker",newClass="SuperZombie.ZombieSuperStalker",bReplace=false)
    replacementArray(3)=(oldClass="KFChar.ZombieSiren",newClass="SuperZombie.ZombieSuperSiren",bReplace=false)
    replacementArray(4)=(oldClass="KFChar.ZombieScrake",newClass="SuperZombie.ZombieSuperScrake",bReplace=false)
    replacementArray(5)=(oldClass="KFChar.ZombieHusk",newClass="SuperZombie.ZombieSuperHusk",bReplace=false)
    replacementArray(6)=(oldClass="KFChar.ZombieCrawler",newClass="KFChar.ZombieShade",bReplace=false)
    replacementArray(7)=(oldClass="KFChar.ZombieBloat",newClass="SuperZombie.ZombieSuperBloat",bReplace=false)
    propDescripArray(0)=(property="debugLogLevel",longDescription="Adjust the debug log level for the Super Zombie Mutator",shortDescription="Debug log level")
    propDescripArray(1)=(property="bReplaceCrawler",longDescription="Replace Crawlers with Shades",shortDescription="Replace Crawlers")
    propDescripArray(2)=(property="bReplaceStalker",longDescription="Replace Stalkers with SuperStalkers",shortDescription="Replace Stalkers")
    propDescripArray(3)=(property="bReplaceGorefast",longDescription="Replace Gorefasts with SuperGorefasts",shortDescription="Replace Gorefasts")
    propDescripArray(4)=(property="bReplaceBloat",longDescription="Replace Bloats with SuperBloats",shortDescription="Replace Bloats")
    propDescripArray(5)=(property="bReplaceSiren",longDescription="Replace Sirens with SuperSirens",shortDescription="Replace Sirens")
    propDescripArray(6)=(property="bReplaceHusk",longDescription="Replace Husks with SuperHusks",shortDescription="Replace Husks")
    propDescripArray(7)=(property="bReplaceScrake",longDescription="Replace Scrakes with SuperScrakes",shortDescription="Replace Scrakes")
    propDescripArray(8)=(property="bReplaceFleshpound",longDescription="Replace Fleshpounds with SuperFleshpounds",shortDescription="Replace Fleshpounds")
    propDescripArray(9)=(property="bReplaceBoss",longDescription="Replace the Patriarch with the SuperPatriarch",shortDescription="Replace Patriarch")
}
