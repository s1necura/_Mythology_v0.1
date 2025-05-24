#include "UndeadAttackCommon.as";

const int COINS_ON_DEATH = 10;

void onInit(CBlob@ this)
{
	UndeadAttackVars attackVars;
	attackVars.frequency = 45;
	attackVars.map_factor = 99999999999999;
	attackVars.damage = 0.75f;
	attackVars.sound = "ZombieBite" + (XORRandom(2)+1);
	this.set("attackVars", attackVars);
	
	this.set_f32("gib health", -3.0f);
	this.set_u16("coins on death", COINS_ON_DEATH);

	this.getSprite().PlaySound("/ZombieSpawn");
	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.Tag("flesh");
	this.Tag("medium weight");
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	
	if (isClient() && XORRandom(768) == 0)
	{
		this.getSprite().PlaySound("/ZombieGroan");
	}
}

