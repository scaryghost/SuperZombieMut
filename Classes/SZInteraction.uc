class SZInteraction extends Interaction;

var Material bleedIcon, poisonIcon;
var float size;

event NotifyLevelChange(){
    Master.RemoveInteraction(self);
}

function PostRender(Canvas canvas) {
    local HUDKillingFloor kfHud;
    local SZReplicationInfo szRI;
    local int x, y, offset, i;
    local Vector CamPos, ViewDir;
    local Rotator CamRot;
    local float OffsetX, BarLength, BarHeight, XL, YL, posY;

    szRI= class'SZReplicationInfo'.static.findSZri(ViewportOwner.Actor.PlayerReplicationInfo);
    if (szRI != none) {
        offset= 2;
        if (szRI.isBleeding) {
            x= canvas.ClipX * 0.007;
            y= canvas.ClipY * 0.93 - size * offset;
            offset++;
            canvas.SetPos(x, y);
            canvas.DrawTile(bleedIcon, size, size, 0, 0, bleedIcon.MaterialUSize(), bleedIcon.MaterialVSize());
        }
        if (szRI.isPoisoned) {
            x= canvas.ClipX * 0.007;
            y= canvas.ClipY * 0.93 - size * offset;
            canvas.SetPos(x, y);
            canvas.DrawTile(poisonIcon, size, size, 0, 0, poisonIcon.MaterialUSize(), poisonIcon.MaterialVSize());
        }
    }

    canvas.GetCAmeraLocation(CamPos, CamRot);
    ViewDir= vector(CamRot);
    kfHud= HUDKillingFloor(ViewportOwner.Actor.myHUD);
    OffsetX = (36.f * kfHud.default.VeterancyMatScaleFactor * 0.6) - (kfHud.default.HealthIconSize + 2.0);
    BarLength = FMin(kfHud.default.BarLength * (float(canvas.SizeX) / 1024.f), kfHud.default.BarLength);
    BarHeight = FMin(kfHud.default.BarHeight * (float(canvas.SizeX) / 1024.f), kfHud.default.BarHeight);
    for (i = 0; i < kfHUD.PlayerInfoPawns.Length; i++) {
        szRI= class'SZReplicationInfo'.static.findSZri(kfHUD.PlayerInfoPawns[i].Pawn.PlayerReplicationInfo);
        if (szRI != None && kfHUD.PlayerInfoPawns[i].Pawn != none && kfHUD.PlayerInfoPawns[i].Pawn.Health > 0 && 
                (kfHUD.PlayerInfoPawns[i].Pawn.Location - kfHUD.PawnOwner.Location) dot ViewDir > 0.8 &&
                kfHUD.PlayerInfoPawns[i].RendTime > ViewportOwner.Actor.Level.TimeSeconds) {
            canvas.StrLen(Left(kfHUD.PlayerInfoPawns[i].Pawn.PlayerReplicationInfo.PlayerName, 16), XL, YL);
            if (kfHUD.PlayerInfoPawns[i].Pawn.ShieldStrength <= 0) {
                posY= (kfHUD.PlayerInfoPawns[i].PlayerInfoScreenPosY - YL) - 2.75 * BarHeight -
                        kfHUD.default.ArmorIconSize * 0.5;
            } else {
                posY= (kfHUD.PlayerInfoPawns[i].PlayerInfoScreenPosY - YL) - 3.8 * BarHeight -
                        kfHUD.default.ArmorIconSize * 0.5;
            }
            offset= 0;
            if (szRI.isBleeding) {
                canvas.SetPos(kfHUD.PlayerInfoPawns[i].PlayerInfoScreenPosX - OffsetX - 0.15 * BarLength - 
                        kfHUD.default.ArmorIconSize - 2.0, posY);
                canvas.DrawTileScaled(bleedIcon, 0.1875, 0.1875);
            }
            if (szRI.isPoisoned) {
                canvas.SetPos(kfHUD.PlayerInfoPawns[i].PlayerInfoScreenPosX - OffsetX + 0.15 * BarLength -
                        kfHUD.default.ArmorIconSize - 2.0, posY);
                canvas.DrawTileScaled(poisonIcon, 0.1875, 0.1875);
            }
        }
    }
}

defaultproperties {
    bActive= true
    bVisible= true

    size= 75.6
    bleedIcon= Texture'SuperZombieMut.BleedIcon'
    poisonIcon= Texture'SuperZombieMut.PoisonIcon'
}
