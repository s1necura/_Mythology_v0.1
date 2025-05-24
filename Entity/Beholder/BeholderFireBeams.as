const f32 ORB_SPEED = 7.0f;

void onInit(CBlob@ this)
{
    this.set_u8("current_attack", 0);
    this.set_u8("orb_count", 0);
}

void onTick(CBlob@ this)
{
    if (isServer() && (this.isKeyPressed(key_action1) || this.get_u8("orb_count")>0 ))
    {
        u8 current_attack = this.get_u8("current_attack");
        u8 orb_count = this.get_u8("orb_count");
        
        Vec2f offset;
        string proj_blob;
        u8 total_orbs;
        f32 ORB_SPEED = 7.0f;

        switch (current_attack)
        {
            case 0:
                offset = Vec2f(0.0f, 0.0f);
                proj_blob = "orbparalysis";
                total_orbs = 30;
                ORB_SPEED = 10.0f;
                break;
            case 1:
                offset = Vec2f(10.0f, 0.0f);
                proj_blob = "orbnightmare";
                total_orbs = 15;
                ORB_SPEED = 5.0f;
                break;
            case 2:
                offset = Vec2f(-10.0f, 0.0f);
                proj_blob = "orbpurple";
                total_orbs = 200;
                ORB_SPEED = 5.0f;
                break;
            case 3:
                proj_blob = "null";
                total_orbs = 100;
                break;
            case 4:
                offset = Vec2f(0.0f, 0.0f);
                proj_blob = "orbparalysis";
                total_orbs = 30;
                ORB_SPEED = 10.0f;
                break;
            case 5:
                offset = Vec2f(10.0f, 0.0f);
                proj_blob = "orbred";
                total_orbs = 10;
                ORB_SPEED = 7.0f;
            break;
            case 6:
                offset = Vec2f(10.0f, 0.0f);
                proj_blob = "orbwhite";
                total_orbs = 20;
                ORB_SPEED = 30.0f;
            break;
            case 7:
                offset = Vec2f(10.0f, 0.0f);
                proj_blob = "frost_ball";
                total_orbs = 3;
                ORB_SPEED = 7.0f;
            break;
            case 8:
                proj_blob = "null";
                total_orbs = 100;
                break;
        }
        
        Vec2f pos = this.getPosition() + offset;
        u16 targetID = this.get_u16("target");
        CBlob@ targetBlob = targetID != 0xffff ? getBlobByNetworkID(targetID) : null;
        Vec2f aimPos = targetBlob !is null ? targetBlob.getPosition() : this.getAimPos();
        Vec2f dir = aimPos - pos; dir.Normalize();
        
        CBlob@ orb = server_CreateBlob(proj_blob, this.getTeamNum(), pos);
        if (orb !is null)
        {
            orb.setVelocity(dir * ORB_SPEED);
            if (targetBlob !is null) orb.set_u16("target", targetBlob.getNetworkID());
        }
        
        orb_count++;
        if (orb_count >= total_orbs)
        {
            orb_count = 0;
            current_attack = (current_attack + 1) % 9;
        }
        
        this.set_u8("orb_count", orb_count);
        this.set_u8("current_attack", current_attack);
    }
}