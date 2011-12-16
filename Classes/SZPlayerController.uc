class SZPlayerController extends KFPlayerController;

function SetPawnClass(string inClass, string inCharacter) {
    super.SetPawnClass(inClass, inCharacter);
    PawnClass = Class'SuperZombieMut.SZHumanPawn';
}

