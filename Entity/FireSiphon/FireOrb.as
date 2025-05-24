const f32 ORB_SPEED = 7.0f;



void onTick(CBlob@ this)
{
    //1 beam
    if (isServer() && this.isKeyPressed(key_action1))
    {
        Vec2f offset(0.0f, -7.0f);
        Vec2f pos = this.getPosition() + offset;
        u16 targetID = this.get_u16("target");
        CBlob@ targetBlob = targetID != 0xffff ? getBlobByNetworkID(targetID) : null;
        Vec2f aimPos = targetBlob !is null ? targetBlob.getPosition() : this.getAimPos();
        Vec2f dir = aimPos - pos; dir.Normalize();

        CBlob@ orb = server_CreateBlob("orbfire", this.getTeamNum(), pos);
        if (orb !is null)
        {
            orb.setVelocity(dir * ORB_SPEED);
            if (targetBlob !is null) orb.set_u16("target", targetBlob.getNetworkID());
        }
        
    }
}