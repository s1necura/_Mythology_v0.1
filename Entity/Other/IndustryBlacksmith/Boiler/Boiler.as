void onInit(CBlob@ this)
{
	this.Tag("medium weight");
CShape@ shape = this.getShape();
if (shape is null) return;
    shape.SetStatic(true);

    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;
    sprite.SetZ(-50);
}