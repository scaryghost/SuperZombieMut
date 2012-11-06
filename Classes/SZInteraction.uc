class SZInteraction extends Interaction;

var HudBase.NumericWidget health;

event NotifyLevelChange(){
    Master.RemoveInteraction(self);
}

function PostRender(Canvas canvas) {
    health.value= KFPlayerReplicationInfo(ViewportOwner.Actor.PlayerReplicationInfo).PlayerHealth;
    HudBase(ViewportOwner.Actor.myHud).DrawNumericWidget(canvas, health, class'HUDKillingFloor'.default.DigitsSmall);
}

defaultproperties {
    bActive= true
    bVisible= true
    health=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.042500,PosY=0.950000,Tints[0]=(B=0,G=255,R=0,A=200),Tints[1]=(B=0,G=255,R=0,A=200))
}
