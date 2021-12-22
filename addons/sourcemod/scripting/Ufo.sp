#include <sourcemod>
#include <sdktools>
#include <warden>

#pragma semicolon 1
#pragma newdecls required

int g_BeamSprite = -1, g_HaloSprite = -1;

bool Olecek[65] = { false, ... };

public Plugin myinfo = 
{
	name = "[JB] - Ufo", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_ufo", Command_Ufo, "");
	RegAdminCmd("flagufo", Flag_Ufo, ADMFLAG_ROOT, "");
}

public void OnMapStart()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	char Filename[256];
	GetPluginFilename(INVALID_HANDLE, Filename, 256);
	if (strncmp(map, "workshop/", 9, false) == 0)
	{
		if (StrContains(map, "/jb_", false) == -1 && StrContains(map, "/jail_", false) == -1 && StrContains(map, "/ba_jail", false) == -1)
			ServerCommand("sm plugins unload %s", Filename);
	}
	else if (strncmp(map, "jb_", 3, false) != 0 && strncmp(map, "jail_", 5, false) != 0 && strncmp(map, "ba_jail", 3, false) != 0)
		ServerCommand("sm plugins unload %s", Filename);
	
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	
	AddFileToDownloadsTable("materials/models/bydexter/ufo/texture.vmt");
	AddFileToDownloadsTable("materials/models/bydexter/ufo/texture.vtf");
	AddFileToDownloadsTable("materials/models/bydexter/ufo/texture_n.vtf");
	
	AddFileToDownloadsTable("models/bydexter/ufo/ufo.dx90.vtx");
	AddFileToDownloadsTable("models/bydexter/ufo/ufo.mdl");
	AddFileToDownloadsTable("models/bydexter/ufo/ufo.vvd");
	
	PrecacheModel("models/bydexter/ufo/ufo.mdl");
}

public Action Flag_Ufo(int client, int args)
{
	ReplyToCommand(client, "[SM] !ufo komutuna erişimin var.");
	return Plugin_Handled;
}

public Action Command_Ufo(int client, int args)
{
	if (warden_iswarden(client) || CheckCommandAccess(client, "flagufo", ADMFLAG_ROOT))
	{
		if (args != 1)
		{
			ReplyToCommand(client, "[SM] Kullanım: !ufo <Ölecek Kişi>");
			return Plugin_Handled;
		}
		
		char arg1[20];
		GetCmdArg(1, arg1, 20);
		if (StringToInt(arg1) < 1)
		{
			ReplyToCommand(client, "[SM] 1'den büyük bir sayı belirmelisin!");
			return Plugin_Handled;
		}
		
		int Ab = 0;
		for (int player = 1; player <= MaxClients; player++)if (IsValidClient(player) && IsPlayerAlive(player) && GetClientTeam(player) == 2)
		{
			Olecek[player] = false;
			Ab++;
		}
		
		if (StringToInt(arg1) >= Ab)
		{
			ReplyToCommand(client, "[SM] Belirlediğiniz oyuncu sayısı çok fazla.");
			return Plugin_Handled;
		}
		
		int Olen = StringToInt(arg1);
		PrintToChatAll("[SM] \x10%N\x01, uzaylılarla anlaşma yaptı. \x06%d oyuncu ölecek!", client, Olen);
		
		for (int i = 1; i <= Olen; i++)
		{
			CreateTimer(3.0, UfoylaAl, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

public Action UfoylaAl(Handle timer, any data)
{
	int Sayi = 0;
	int Say[65] = { 0, ... };
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !Olecek[i])
	{
		Sayi++;
		Say[i] = Sayi;
	}
	int RandomSayi = GetRandomInt(1, Sayi);
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !Olecek[i])
	{
		if (Say[i] == RandomSayi)
		{
			Olecek[i] = true;
			UfoTasi(i);
		}
	}
	return Plugin_Stop;
}

void UfoTasi(int client)
{
	if (IsValidClient(client))
	{
		float location[3];
		GetClientAbsOrigin(client, location);
		SetEntityMoveType(client, MOVETYPE_NONE);
		
		float pointPos[3];
		float vAngles[3] = { -90.0, 0.0, 0.0 };
		Handle trace = TR_TraceRayFilterEx(location, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		if (TR_DidHit(trace))
			TR_GetEndPosition(pointPos, trace);
		trace.Close();
		pointPos[2] -= 32.0;
		
		char Modelname[128];
		GetClientName(client, Modelname, 128);
		
		int ufo = CreateEntityByName("prop_dynamic");
		DispatchKeyValue(ufo, "model", "models/bydexter/ufo/ufo.mdl");
		SetEntPropString(ufo, Prop_Data, "m_iName", Modelname);
		DispatchSpawn(ufo);
		TeleportEntity(ufo, pointPos, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(0.1, Ucur, client, TIMER_REPEAT);
	}
}

public Action Ucur(Handle timer, int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	float location[3];
	GetClientAbsOrigin(client, location);
	float pointPos[3];
	float vAngles[3] = { -90.0, 0.0, 0.0 };
	Handle trace = TR_TraceRayFilterEx(location, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace))
		TR_GetEndPosition(pointPos, trace);
	trace.Close();
	pointPos[2] -= 64.0;
	
	location[2] += 4.0;
	TeleportEntity(client, location, NULL_VECTOR, NULL_VECTOR);
	TE_SetupBeamPoints(location, pointPos, g_BeamSprite, g_HaloSprite, 0, 60, 1.0, 20.0, 20.0, 1, 0.0, { 255, 147, 0, 255 }, 450);
	TE_SendToAll();
	
	if (location[2] >= pointPos[2])
	{
		ForcePlayerSuicide(client);
		char sPath[128];
		char Modelname[128];
		GetClientName(client, Modelname, 128);
		for (int i = MaxClients; i < GetMaxEntities(); i++)
		{
			if (IsValidEdict(i) && IsValidEntity(i))
			{
				GetEntPropString(i, Prop_Data, "m_iName", sPath, 128);
				if (strcmp(sPath, Modelname, false) == 0)
					RemoveEntity(i);
			}
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
} 