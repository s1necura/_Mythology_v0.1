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

void onGib(CSprite@ this)
{
    if (g_kidssafe) {
        return;
    }

    CBlob@ blob = this.getBlob();
    Vec2f pos = blob.getPosition();
    Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
    f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
}