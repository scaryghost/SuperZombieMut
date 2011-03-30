class SuperZombieMut extends Mutator
    config(SuperZombie);

struct oldNewZombiePair {
    var string oldClass;
    var string newClass;
};

var() config int debugLogLevel;
var() config float bloatPukeRate;
var() config float bloatPukeRange;
var() config float bloatBileMaxRange;
var array<oldNewZombiePair> replacementArray[7];

function replaceSpecialSquad(out array<KFGameType.SpecialSquad> squadArray) {
    local int i,j,k;
    local oldNewZombiePair replacementValue;
    for(j=0; j<squadArray.Length; j++) {
        for(i=0;i<squadArray[j].ZedClass.Length; i++) {
            for(k=0; k<7; k++) {
                replacementValue= replacementArray[k];
                if(squadArray[j].ZedClass[i] ~= replacementValue.oldClass) {
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

    //Replace all instances of KFChar.ZombieFleshPound with the super fp class 
    for( i=0; i<KF.StandardMonsterClasses.Length; i++) {
        for(k=0; k<7; k++) {
            replacementValue= replacementArray[k];
            //Use ~= for case insensitive compare
            if (KF.StandardMonsterClasses[i].MClassName ~= replacementValue.oldClass) {
                KF.StandardMonsterClasses[i].MClassName= replacementValue.newClass;
            }
        }
    }

    //Replace the special squad arrays
    replaceSpecialSquad(KF.ShortSpecialSquads);
    replaceSpecialSquad(KF.NormalSpecialSquads);
    replaceSpecialSquad(KF.LongSpecialSquads);

    KF.EndGameBossClass= "SuperZombie.ZombieSuperBoss";

    class'ZombieSuperFP'.default.logLevel= debugLogLevel;
    class'ZombieSuperBoss'.default.logLevel= debugLogLevel;
    class'ZombieSuperGorefast'.default.logLevel= debugLogLevel;
    class'ZombieSuperStalker'.default.logLevel= debugLogLevel;
    class'ZombieSuperSiren'.default.logLevel= debugLogLevel;
    class'ZombieSuperScrake'.default.logLevel= debugLogLevel;
    class'ZombieSuperHusk'.default.logLevel= debugLogLevel;
    class'ZombieSuperBloat'.default.logLevel= debugLogLevel;
    class'ZombieSuperBloat'.default.pukeRate= bloatPukeRate;
    class'ZombieSuperBloat'.default.pukeRange= bloatPukeRange;
    class'ZombieSuperBloat'.default.bileMaxRange= bloatBileMaxRange;

	SetTimer(0.1, false);
}

function Timer() {
	Destroy();
}

static function FillPlayInfo(PlayInfo PlayInfo) {
    Super.FillPlayInfo(PlayInfo);
    PlayInfo.AddSetting("LogLevel Modifier", "debugLogLevel","Debug log level", 0, 1, "Text", "0.1;0:4",,,true);
    PlayInfo.AddSetting("Puke Rate Modifier", "bloatPukeRate","Puke animation rate", 0, 1, "Text",,,,true);
    PlayInfo.AddSetting("Puke Range Modifier", "bloatPukeRange","Puke range distance", 0, 1, "Text",,,,true);
    PlayInfo.AddSetting("Bile Max Range Modifier", "bloatBileMaxRange","Bile max distance", 0, 1, "Text",,,,true);
}

static event string GetDescriptionText(string property) {
    switch(property) {
        case "debugLogLevel":
            return "Adjust the debug log level for the Super Zombie Mutator";
        case "bloatPukeRate":
            return "Adjust how fast the puking animation plays for the bloat";
        case "bloatPukeRange":
            return "Adjust when the bloat starts puking";
        case "bloatBileMaxRange":
            return "Adjust how far the puke travels";
        default:
            return Super.GetDescriptionText(property);
    }
}

defaultproperties {
    debugLogLevel=0;
    bloatPukeRate= 0.0;
    bloatPukeRange= 250.0;
    bloatBileMaxRange- 500.0;
	GroupName="KFSuperZombieMut"
	FriendlyName="Super Zombie"
	Description="Modifies zombie behavior"
    replacementArray(0)=(oldClass="KFChar.ZombieFleshPound",newClass="SuperZombie.ZombieSuperFP")
    replacementArray(1)=(oldClass="KFChar.ZombieGorefast",newClass="SuperZombie.ZombieSuperGorefast")
    replacementArray(2)=(oldClass="KFChar.ZombieStalker",newClass="SuperZombie.ZombieSuperStalker")
    replacementArray(3)=(oldClass="KFChar.ZombieSiren",newClass="SuperZombie.ZombieSuperSiren")
    replacementArray(4)=(oldClass="KFChar.ZombieScrake",newClass="SuperZombie.ZombieSuperScrake")
    replacementArray(5)=(oldClass="KFChar.ZombieHusk",newClass="SuperZombie.ZombieSuperHusk")
    replacementArray(6)=(oldClass="KFChar.ZombieCrawler",newClass="KFChar.ZombieShade")
}
