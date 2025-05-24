//Archer Include

namespace ArcherParams
{
	enum Aim
	{
		not_aiming = 0,
		readying,
		charging,
		fired,
		no_arrows,
		stabbing,
		legolas_ready,
		legolas_charging
	}

	const ::s32 ready_time = 11;

	const ::s32 shoot_period = 30;
	const ::s32 shoot_period_1 = ArcherParams::shoot_period / 3;
	const ::s32 shoot_period_2 = 2 * ArcherParams::shoot_period / 3;
	const ::s32 legolas_period = ArcherParams::shoot_period * 3;

	const ::s32 fired_time = 7;
	const ::f32 shoot_max_vel = 17.59f;

	const ::s32 legolas_charge_time = 5;
	const ::s32 legolas_arrows_count = 1;
	const ::s32 legolas_arrows_volley = 3;
	const ::s32 legolas_arrows_deviation = 5;
	const ::s32 legolas_time = 60;
}


namespace ArrowType
{
	enum type
	{
		normal = 0,
		water,
		fire,
		bomb,
		count
	};
}

shared class ArcherInfo
{
	s8 charge_time;
	u8 charge_state;
	bool has_arrow;
	u8 stab_delay;
	u8 fletch_cooldown;
	u8 arrow_type;

	u8 legolas_arrows;
	u8 legolas_time;

	f32 cache_angle;

	ArcherInfo()
	{
		charge_time = 0;
		charge_state = 0;
		has_arrow = false;
		stab_delay = 0;
		fletch_cooldown = 0;
		arrow_type = ArrowType::normal;
	}
};

void ClientSendArrowState(CBlob@ this)
{
	if (!isClient()) { return; }
	if (isServer()) { return; } // no need to sync on localhost

	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer)) { return; }

	CBitStream params;
	params.write_u8(archer.arrow_type);

	this.SendCommand(this.getCommandID("arrow sync"), params);
}

bool ReceiveArrowState(CBlob@ this, CBitStream@ params)
{
	// valid both on client and server

	if (isServer() && isClient()) { return false; }

	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer)) { return false; }

	archer.arrow_type = 0;
	if (!params.saferead_u8(archer.arrow_type)) { return false; }

	if (isServer())
	{
		CBitStream reserialized;
		reserialized.write_u8(archer.arrow_type);

		this.SendCommand(this.getCommandID("arrow sync client"), reserialized);
	}

	return true;
}


//TODO: saferead


const string[] arrowTypeNames = { "mat_arrows",
                                  "mat_waterarrows",
                                  "mat_firearrows",
                                  "mat_bombarrows"
                                };

const string[] arrowNames = { "Regular arrows",
                              "Water arrows",
                              "Fire arrows",
                              "Bomb arrow"
                            };

const string[] arrowIcons = { "$Arrow$",
                              "$WaterArrow$",
                              "$FireArrow$",
                              "$BombArrow$"
                            };


bool hasArrows(CBlob@ this)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return false;
	}
	if (archer.arrow_type >= 0 && archer.arrow_type < arrowTypeNames.length)
	{
		return this.getBlobCount(arrowTypeNames[archer.arrow_type]) > 0;
	}
	return false;
}

bool hasArrows(CBlob@ this, u8 arrowType)
{
	if (this is null) return false;
	
	return arrowType < arrowTypeNames.length && this.hasBlob(arrowTypeNames[arrowType], 1);
}

bool hasAnyArrows(CBlob@ this)
{
	for (uint i = 0; i < ArrowType::count; i++)
	{
		if (hasArrows(this, i))
		{
			return true;
		}
	}
	return false;
}

void SetArrowType(CBlob@ this, const u8 type)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}
	archer.arrow_type = type;
}

u8 getArrowType(CBlob@ this)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return 0;
	}
	return archer.arrow_type;
}
