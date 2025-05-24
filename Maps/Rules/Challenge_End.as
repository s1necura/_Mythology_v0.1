#include "ChallengesCommon.as"

const string OUTRO_TEXT =
    "You have defeated the beholder!";

const string OUTRO_TEXT_DEAD_PRINCESS =
    "You have defeated the beholder!";

int gameEndTime	= 0;
int gameEndDuration	= getTicksASecond() * 25;

void onInit(CMap@ this)
{
	AddRulesScript(getRules());
}

void onInit(CRules@ this)
{
	SetIntroduction(this, "Save the Princess!");
	sv_mapcycle_shuffle = false;
	this.set_s32("restart_rules_after_game_time", 30 * 4); // no better place?
}

void onRestart(CRules@ this)
{
	gameEndTime = 0;
}

void onBlobDie(CRules@ this, CBlob@ blob)	   // server/noclient endgame
{
	if (getNet().isServer() && !getNet().isClient() && blob.getName() == "beholder")
	{
		this.set_s32("restart_rules_after_game_time", 30 * 12);
		this.set_bool("played fanfare", false); //
		DefaultWin(this);
	}
}

void onRender(CMap@ this)
{
	const int time = getMap().getTimeSinceStart();
	CRules@ rules = getRules();

	// end

	if (gameEndTime > 0 || time % 30 == 0)
	{
		CBlob@ princess;
		CBlob@ beholder;
		{
			CBlob@[] blobs;
			if (getBlobsByName("princess", @blobs))
			{
				@princess = blobs[0];
				if (princess.hasTag("dead"))
					@princess = null;
			}
		}
		{
			CBlob@[] blobs;
			if (getBlobsByName("beholder", @blobs))
			{
				@beholder = blobs[0];
				if (beholder.hasTag("dead"))
					@beholder = null;
			}
		}

		const bool princessAlive = (princess !is null) && !princess.hasTag("dead");
		CBlob@ localBlob = getLocalPlayerBlob();
		if (gameEndTime > 0 || (beholder is null && (princess is null || localBlob !is null && (princess.getPosition() - localBlob.getPosition()).getLength() < 25.0f)))
		{
			if (gameEndTime == 0)
			{
				gameEndTime = time + gameEndDuration;
			}

			{
				const f32 right = getScreenWidth();
				const f32 middle = right / 2.0f;
				const f32 bottom = getScreenHeight();
				const f32 timeRatio = 1.0f - (float(gameEndTime - time) / float(gameEndDuration));

				// black fade
				const uint alpha = 255 * timeRatio * timeRatio;
				GUI::DrawRectangle(Vec2f_zero, Vec2f(right, bottom),
				                   SColor(alpha, 0, 0, 0));

				Vec2f ul(middle - 170.0f, bottom + 0.0f - timeRatio * 700.0f);
				Vec2f lr(middle + 170.0f, bottom + 400.0f);

				GUI::SetFont("menu");
				GUI::DrawText(princessAlive ? getTranslatedString(OUTRO_TEXT) : getTranslatedString(OUTRO_TEXT_DEAD_PRINCESS),
				              ul, lr,
				              SColor(255, 255, 255, 255),
				              false, false, false);

				GUI::DrawIcon("GUI/BottomFade.png", 0, Vec2f(400, 256), Vec2f(0, bottom - 2 * 256 + 150.0f), getScreenWidth()/800.0f);
			}
		}

		if (getNet().isServer() && time == gameEndTime)
		{
			PrincessSaved(princessAlive);
			rules.set_bool("played fanfare", true); //
			DefaultWin(rules, "");
			MessageBox(getTranslatedString("The End."), getTranslatedString("The mod was developed by: LorderPlay, SkayMo. And also special thanks to Noah and GingerBeard."), true);
		}
	}
}
