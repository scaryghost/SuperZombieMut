class SZPlayerController extends KFPCServ;

function SetPawnClass(string inClass, string inCharacter) {
    super.SetPawnClass(inClass, inCharacter);
    PawnClass = Class'SuperZombieMut_ServerPerks.SZHumanPawn';
}

