void onInit(CBlob@ this)
{
CShape@ shape = this.getShape();
if (shape is null) return;
    shape.SetStatic(true);
    shape.SetGravityScale(0.0f);

    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;
    sprite.SetZ(-50);
}