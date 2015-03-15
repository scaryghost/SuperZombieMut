class IronBall extends Inventory;

simulated function float GetMovementModifierFor(Pawn InPawn) {
    return 0.5f;
}

defaultproperties {
    PickupClass= class'SuperZombieMut.IronBallPickup'
}
