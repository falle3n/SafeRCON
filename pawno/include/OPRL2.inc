/*______________________________________________________________________________

						OPRL.inc - OnPlayerRconLogin
						        By Lordz.
							Version : 1.2

	"OPRL" AKA "OnPlayerRconLogin" is an include which procies a callback called
	OnPlayerRconLogin which gets called when a player logins as RCON. This is
	called only when a player ID logs in, not if an IP does.



      This Source Code Form is subject to the
      terms of the Mozilla Public License, v.
      2.0. If a copy of the MPL was not
      distributed with this file, You can
      obtain one at
      http://mozilla.org/MPL/2.0/.

      Thanks to :
	  Konstantinos for showing a better method in calling OPRL. (Based on v1.2)
	  SA-MP Team for SA-MP.

Author : Lordz™ AKA Lordzy.

Changelogs:
v1.0

01-02-2014

• Initial Release.

v1.2

02-02-2014

• Include has been optimized! Thanks to Konstantinos for showing a better method
  to callout "OnPlayerRconLogin"

Callbacks:
OnPlayerRconLogin(playerid);

______________________________________________________________________________*/

#if defined _OnPlayerRconLogin_included
	#endinput
#endif

#define _OnPlayerRconLogin_included




static
	bool:OPRL_IsPlayerAdmin[MAX_PLAYERS];

static stock OPRL_CheckRCONAdmin(playerid) {
	if(IsPlayerAdmin(playerid) && OPRL_IsPlayerAdmin[playerid] == false) {
		OPRL_IsPlayerAdmin[playerid] = true;
		CallLocalFunction("OnPlayerRconLogin", "i", playerid);
	}
	else if(!IsPlayerAdmin(playerid) && OPRL_IsPlayerAdmin[playerid] == true) {
	    OPRL_IsPlayerAdmin[playerid] = false;
	}
	return 1;
}


#if defined FILTERSCRIPT
public OnFilterScriptInit() {
	for(new i; i< GetMaxPlayers(); i++) {
	    if(IsPlayerAdmin(i)) OPRL_IsPlayerAdmin[i] = true;
	    else OPRL_IsPlayerAdmin[i] = false;
	}
	#if defined OPRL_USE_TIMER
	    OPRL_LTimer = SetTimer("OPRL_OnUpdate", 600, 1);
	#endif
	#if defined OPRL_OnFilterScriptInit
	    OPRL_OnFilterScriptInit();
	#endif
	return 1;
}


#else

public OnGameModeInit() {
	for(new i; i< GetMaxPlayers(); i++) {
	    if(IsPlayerAdmin(i)) OPRL_IsPlayerAdmin[i] = true;
	    else OPRL_IsPlayerAdmin[i] = false;
	}
	#if defined OPRL_USE_TIMER
	    SetTimer("OPRL_OnUpdate", 600, 1);
	#endif
	#if defined ORPL_OnGameModeInit
	    OPRL_OnGameModeInit();
	#endif
	return 1;
}

#endif

#if defined FILTERSCRIPT

	#if defined _ALS_OnFilterScriptInit
	    #undef OnFilterScriptInit
	#else
	    #define _ALS_OnFilterScriptInit
	#endif

	#define OnFilterScriptInit OPRL_OnFilterScriptInit

	#if defined OPRL_OnFilterScriptInit
	forward OPRL_OnFilterScriptInit();
	#endif


#else

	#if defined _ALS_OnGameModeInit
		#undef OnGameModeInit
	#else
	    #define _ALS_OnGameModeInit
	#endif

	#define OnGameModeInit OPRL_OnGameModeInit

	#if defined OPRL_OnGameModeInit
	forward OPRL_OnGameModeInit();
	#endif
#endif

public OnRconLoginAttempt(ip[], password[], success) {
	if(success) SetTimerEx("OPRL_GetRconPlayer", 1000, false, "s", ip);
	#if defined OPRL_OnRconLoginAttempt
		OPRL_OnRconLoginAttempt(ip, password, success);
	#endif
	return 1;
}

#if defined _ALS_OnRconLoginAttempt
	#undef OnRconLoginAttempt
#else
	#define _ALS_OnRconLoginAttempt
#endif

#define OnRconLoginAttempt OPRL_OnRconLoginAttempt

#if defined OPRL_OnRconLoginAttempt
forward OPRL_OnRconLoginAttempt(ip[], password[], success);
#endif

forward OPRL_GetRconPlayer(ip[]);

public OPRL_GetRconPlayer(ip[]) {
	new OPRL_IP[16];
	for(new i; i< GetMaxPlayers(); i++) {
		if(IsPlayerAdmin(i) && !OPRL_IsPlayerAdmin[i]) {
			GetPlayerIp(i, OPRL_IP, sizeof(OPRL_IP));
			if(!strcmp(ip, OPRL_IP, false)) {
			    OPRL_CheckRCONAdmin(i);
			    break;
			}
		}
	}
	return 1;
}

forward OnPlayerRconLogin(playerid);

/* Copyright(c) 2014 - "OPRL.inc" */
