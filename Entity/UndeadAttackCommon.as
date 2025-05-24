shared class UndeadAttackVars
{
	u8 frequency;       //time it takes between attacks 
	u8 map_factor;      //higher values means less map destruction
	u8 hitter;          //hitter custom-data
	f32 damage;         //damage from a successful hit
	f32 arc_length;     //size of the attack
	string sound;       //sound made during an attack
	u32 next_attack;
	
	//defaults
	UndeadAttackVars()
	{
		frequency = 0;
		map_factor = 99999999999999;
		hitter = 12; //Hitters::bite
		damage = 0.0f;
		arc_length = 2.5f;
		sound = "ZombieBite";
		next_attack = 0;
	}
};
