class SuperZombieMut extends Mutator
    config(SuperZombie);

var() config int debugLogLevel;

function PostBeginPlay() {
	local int i,j;
	local KFGameType KF;
    local string oldFPClass, newFPClass;

	KF = KFGameType(Level.Game);

  	if (Level.NetMode != NM_Standalone)
		AddToPackageMap("SuperZombie");

	if (KF == none) {
		Destroy();
		return;
	}
    
    oldFPClass= "KFChar.ZombieFleshPound";
    newFPClass= "SuperZombie.ZombieSuperFP";

    //Replace all instances of KFChar.ZombieFleshPound with the super fp class 
    for( i=0; i<KF.StandardMonsterClasses.Length; i++) {
        //Use ~= for case insensitive compare
        if (KF.StandardMonsterClasses[i].MClassName ~= oldFPClass) {
            KF.StandardMonsterClasses[i].MClassName= newFPClass;
        }
    }

    //Replace the special squad arrays
    //If only there were array of arrays...
    for(j=0; j<KF.ShortSpecialSquads.Length; j++) {
        for(i=0;i<KF.ShortSpecialSquads[j].ZedClass.Length; i++) {
            if(KF.ShortSpecialSquads[j].ZedClass[i] ~= oldFPClass) {
                KF.ShortSpecialSquads[j].ZedClass[i]=  newFPClass;
            }
        }
    }
    for(j=0; j<KF.NormalSpecialSquads.Length; j++) {
        for(i=0;i<KF.NormalSpecialSquads[j].ZedClass.Length; i++) {
            if(KF.NormalSpecialSquads[j].ZedClass[i] ~= oldFPClass) {
                KF.NormalSpecialSquads[j].ZedClass[i]=  newFPClass;
            }
        }
    }
    for(j=0; j<KF.LongSpecialSquads.Length; j++) {
        for(i=0;i<KF.LongSpecialSquads[j].ZedClass.Length; i++) {
            if(KF.LongSpecialSquads[j].ZedClass[i] ~= oldFPClass) {
                KF.LongSpecialSquads[j].ZedClass[i]=  newFPClass;
            }
        }
    }

    KF.EndGameBossClass= "SuperZombie.ZombieSuperBoss";

    class'SuperFPZombieController'.default.logLevel= debugLogLevel;
    class'ZombieSuperBoss'.default.logLevel= debugLogLevel;

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
            return "Adjust the debug log level for the Super Zombie mutator";
        default:
            return Super.GetDescriptionText(property);
    }
}

defaultproperties {
    debugLogLevel=0;
	GroupName="KFSuperZombieMut"
	FriendlyName="Super Zombies"
	Description="Modifies zombie behavior"
}
