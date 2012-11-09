class SZInteraction extends Interaction;

var Material bleedIcon, poisonIcon;
var float size;

event NotifyLevelChange(){
    Master.RemoveInteraction(self);
}

function PostRender(Canvas canvas) {
    local SZReplicationInfo szRI;
    local int x, y, offset;

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
}

defaultproperties {
    bActive= true
    bVisible= true

    size= 75.6
    bleedIcon= Texture'SuperZombieMut.BleedIcon'
    poisonIcon= Texture'SuperZombieMut.PoisonIcon'
}
