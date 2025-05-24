#include "ShieldCommon.as";
#include "Hitters.as";
//#include "ParticleSparks.as";
//#include "KnockedCommon.as";
//#include "KnightCommon.as";
//#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.Tag("exploding");
	this.set_f32("explosive_radius", 8.0f);
	this.set_f32("explosive_damage", 0.25f);
	this.set_f32("map_damage_radius", 12.0f);
	this.set_f32("map_damage_ratio", -3.0f); //heck no!
}

void onTick(CBlob@ this)
{
			sparkswhite(this.getPosition(), float(XORRandom(1024)) / 1024.0f * 359.0f, 0.5f);
	if (this.getCurrentScript().tickFrequency == 1)
	{
		this.getShape().SetGravityScale(0.0f);
		this.server_SetTimeToDie(2);
		this.SetLight(true);
		this.SetLightRadius(12.0f);
		this.SetLightColor(SColor(255, 255, 240, 240));
		this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
		this.getSprite().PlaySound("OrbFireSound.ogg");
		this.getSprite().SetZ(1000.0f);

		//makes a stupid annoying sound
		//ParticleZombieLightning( this.getPosition() );

		// done post init
		this.getCurrentScript().tickFrequency = -0;
	}

	{
		u16 id = this.get_u16("target");
		if (id != 0xffff && id != 0)
		{
			CBlob@ b = getBlobByNetworkID(id);
			if (b !is null)
			{
				Vec2f vel = this.getVelocity();
				if (vel.LengthSquared() < 0.1f) //9.0F
				{
					Vec2f dir = b.getPosition() - this.getPosition();
					dir.Normalize();


					this.setVelocity(vel + dir * 10.0f); //3.0f //10
				} //else this.server_Die();
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (blob.hasTag("flesh") && !blob.hasTag("dead") && blob.getTeamNum() != this.getTeamNum());
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
    if (solid)
    {
        if (blob !is null && blob.getTeamNum() != this.getTeamNum())
        {
            Vec2f direction = blob.getPosition() - this.getPosition();
            f32 damage = 0.0f;
            if (!blockAttack(blob, direction, damage))
            {
			this.server_Hit(blob, blob.getPosition(), Vec2f_zero, damage, Hitters::bomb, true);
			}
			Sound::Play("Collides.ogg", this.getPosition(),3);
			sparks(this.getPosition(), float(XORRandom(1024)) / 1024.0f * 359.0f, 1.3f);
			sparkswhite(this.getPosition(), float(XORRandom(1024)) / 1024.0f * 359.0f, 0.5f);
			sparksfast(this.getPosition(), float(XORRandom(1024)) / 1024.0f * 359.0f, 0.3f);
            this.server_Die();
        }
    }
    if (blob is null)
    {
        this.server_Die();
		
			Sound::Play("Collides.ogg", this.getPosition(),3);
			sparks(this.getPosition(), float(XORRandom(1024)) / 1024.0f * 359.0f, 1.3f);
			sparkswhite(this.getPosition(), float(XORRandom(1024)) / 1024.0f * 359.0f, 0.5f);
			sparksfast(this.getPosition(), float(XORRandom(1024)) / 1024.0f * 359.0f, 0.3f);
    }
}























void sparks(Vec2f at, f32 angle, f32 damage, f32 angleVariation = 180, f32 velocityVariation = 0.0f)
{
    int amount = damage * 25 + XORRandom(5);

    for (int i = 0; i < amount; i++)
    {
        const float randFloat = float(XORRandom(100)) / 100.0f;
        Vec2f vel = getRandomVelocity(angle, damage * 3.0f + velocityVariation * (randFloat - 0.5f), angleVariation);
        //vel.y = -Maths::Abs(vel.y) + Maths::Abs(vel.x) / 3.0f - 2.0f - randFloat;
        CParticle@ p = ParticlePixel(at, vel, SColor(255, 255, 30, 30), true, XORRandom(8));
        p.gravity = Vec2f(0.0f, 0.0f);
    }
}
void sparkswhite(Vec2f at, f32 angle, f32 damage, f32 angleVariation = 180, f32 velocityVariation = 0.0f)
{
    int amount = damage * 5 + XORRandom(5);

    for (int i = 0; i < amount; i++)
    {
        const float randFloat = float(XORRandom(100)) / 100.0f;
        Vec2f vel = getRandomVelocity(angle, damage * 3.0f + velocityVariation * (randFloat - 0.5f), angleVariation);
        //vel.y = -Maths::Abs(vel.y) + Maths::Abs(vel.x) / 3.0f - 2.0f - randFloat;
        CParticle@ p = ParticlePixel(at, vel, SColor(255, 255, 255, 255), true, XORRandom(20));
        p.gravity = Vec2f(0.0f, 0.0f);
    }
}
void sparksfast(Vec2f at, f32 angle, f32 damage, f32 angleVariation = 180, f32 velocityVariation = 0.0f)
{
    int amount = damage * 1 + XORRandom(0);

    for (int i = 0; i < amount; i++)
    {
        const float randFloat = float(XORRandom(100)) / 100.0f;
        Vec2f vel = getRandomVelocity(angle, damage * 3.0f + velocityVariation * (randFloat - 0.5f), angleVariation);
        //vel.y = -Maths::Abs(vel.y) + Maths::Abs(vel.x) / 3.0f - 2.0f - randFloat;
        CParticle@ p = ParticlePixel(at, vel, SColor(255, 255, 255, 255), true, XORRandom(40));
        p.gravity = Vec2f(0.0f, 0.0f);
    }
}