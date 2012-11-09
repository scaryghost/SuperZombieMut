class HuskFireProjectile_SZ extends KFChar.HuskFireProjectile;

simulated singular function Touch(Actor Other) {
    local vector    HitLocation, HitNormal;

    //Don't touch bulletwhip attachment.  Taken from HuskFireProjectile
    if ( Other == None || KFBulletWhipAttachment(Other) != none )
        return;
    if ( Other.bProjTarget || Other.bBlockActors ) {
        LastTouched = Other;
        if ( Velocity == vect(0,0,0) || Other.IsA('Mover') ) {
            ProcessTouch(Other,Location);
            LastTouched = None;
            return;
        }

        if ( Other.TraceThisActor(HitLocation, HitNormal, Location, Location - 2*Velocity, GetCollisionExtent()) )
            HitLocation = Location;

        ProcessTouch(Other, HitLocation);
        LastTouched = None;
        if ( (Role < ROLE_Authority) && (Other.Role == ROLE_Authority) && (Pawn(Other) != None) )
            ClientSideTouch(Other, HitLocation);
    }
}
