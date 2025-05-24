// Zombie Fortress game events

const u8 GAME_WON = 5;
f32 lastDayHour;

void onStateChange(CRules@ this, const u8 oldState)
{
	const u8 newState = this.getCurrentState();
	
	switch(newState)
	{
		case GAME_OVER:
		{
			Sound::Play("FanfareLose.ogg");
			break;
		}
		case GAME_WON:
		{
			Sound::Play("FanfareWin.ogg");
			break;
		}
	}
}

void onTick(CRules@ this)
{
	if (!isServer()) return;
	
	if (getGameTime() % 60 == 0)
	{
		checkHourChange(this);
	}
}

void checkHourChange(CRules@ this)
{
	CMap@ map = getMap();
	const u8 dayHour = Maths::Roundf(map.getDayTime()*10);
	if (dayHour != lastDayHour)
	{
		lastDayHour = dayHour;
		switch(dayHour)
		{
			case 5: //mid day
			{
				doTraderEvent(this, map);
				break;
			}
			case 10: //midnight
			{
				doSedgwickEvent(this, map);
				break;
			}
		}
	}
}