class ZombieSuperBoss extends ZombieBoss;

function int OnlyEnemyAround( Pawn Other )
{
	local Controller C;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.bIsPlayer && C.Pawn!=None && C.Pawn!=Other && ((VSize(C.Pawn.Location-Location)<1500 && FastTrace(C.Pawn.Location,Location))
		 || (VSize(C.Pawn.Location-Other.Location)<1000 && FastTrace(C.Pawn.Location,Other.Location))) )
			Return False;
	}
	Return True;
}

function RangedAttack(Actor A)
{
	local bool bOnlyE;

	bOnlyE = (Pawn(A)!=None && OnlyEnemyAround(Pawn(A)));

	if(!bOnlyE)
	{
		bShotAnim = true;
		Acceleration = vect(0,0,0);
		SetAnimAction('PreFireMissile');

		HandleWaitForAnim('PreFireMissile');

		GoToState('FireMissile');
	} else {
        super.RangedAttack(A);
    }
}
