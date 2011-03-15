class SuperZombieMut extends Mutator
    config(SuperZombie);

struct oldNewZombiePair {
    var string oldClass;
    var string newClass;
};

var() config int debugLogLevel;
var array<oldNewZombiePair> replacementArray[3];

function replaceSpecialSquad(out array<KFGameType.SpecialSquad> squadArray) {
    local int i,j,k;
    local oldNewZombiePair replacementValue;
    for(j=0; j<squadArray.Length; j++) {
        for(i=0;i<squadArray[j].ZedClass.Length; i++) {
            for(k=0; k<3; k++) {
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
        for(k=0; k<3; k++) {
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

    class'SuperFPZombieController'.default.logLevel= debugLogLevel;
    class'ZombieSuperBoss'.default.logLevel= debugLogLevel;
    class'ZombieSuperGorefast'.default.logLevel= debugLogLevel;
    class'ZombieSuperStalker'.default.logLevel= debugLogLevel;


	SetTimer(0.1, false);
}

function Timer() {
	Destroy();
}

static function FillPlayInfo(PlayInfo PlayInfo) {
    Super.FillPlayInfo(PlayInfo);
    PlayInfo.AddSetting("LogLevel Modifier", "debugLogLevel","Debug log level", 0, 1, "Text", "0.1;0:3");
}

static event string GetDescriptionText(string property) {
    switch(property) {
        case "debugLogLevel":
            return "Adjust the debug log level for the Super Zombie Mutator";
        default:
            return Super.GetDescriptionText(property);
    }
}

defaultproperties {
    debugLogLevel=0;
	GroupName="KFSuperZombieMut"
	FriendlyName="Super Zombie"
	Description="Modifies zombie behaviour"
    replacementArray(0)=(oldClass="KFChar.ZombieFleshPound",newClass="SuperZombie.ZombieSuperFP")
    replacementArray(1)=(oldClass="KFChar.ZombieGorefast",newClass="SuperZombie.ZombieSuperGorefast")
    replacementArray(2)=(oldClass="KFChar.ZombieStalker",newClass="SuperZombie.ZombieSuperStalker")

}
