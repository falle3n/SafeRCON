/*

================================================================================
							SafeRCON - v1.1
							 By fall3n
							 
SafeRCON ensures that your RCON is protected well enough. This filterscript
uses 'OnPlayerRconLogin' include of Lordzy in support of second RCON. In short,
this script provides the following features:

- Checking of main rcon password, in case if it's complex enough.
(Your rcon_password on server.cfg must contain atleast one captial alphabet,
	one small letter and one number. The rcon_password length should be a minimum
	of the value defined as "MIN_RCONPASS_LENGTH" on script.)
	
- Whitelisting IP addresses for RCON logins.

	If someone without the IP address specified logs in, then that player will
	get kicked.

- Whitelisting Nick names for RCON logins.

	Only the specified player names are accessable to RCON logins.
	
- Second RCON system

	This requests an extra RCON login, it also ensures if the login is evaded or
	not. In case if evaded, the script would directly kick.

- A command called "/safercon" in-game which provides GUI to control the features.

- Console / RCON commands for quick purposes. Every commands start with "safercon"

Usage:

For console users:

safercon [command] [params]

For in-game users:

/rcon safercon [command] [params]

Commands:

safercon reloadips
safercon reloadnicks
safercon list whitelistip
safercon list whitelistnick
safercon whitelistip [ip]
safercon whitelistnick [nick]


Credits:

fall3n - For the complete filterscript.
Lordzy - For OPRL include, GetRandomizedChars function, Securing RCON tutorial
	and for some help in regarding the development of this include.
ZeeX - For zcmd.
Y_Less - For sscanf.
SA-MP Team - For SA-MP!


NOTES:

- This filterscript is easy to use. Get to configuration defines section to
  toggle IP/Nick whitelisting, complex password checks etc.
- Also to change second RCON password, go through the configuration defines
  below the script.
  

GitHub release link:
https://github.com/falle3n/SafeRCON

Changelogs:

v1.1

- Added : Timer to check if player has logged in as second RCON or not within
		  the given time.


v1.0

- Initial release.
  
================================================================================        */


#define FILTERSCRIPT

//==============================================================================
//                          Includes
//==============================================================================

#include <a_samp>
#include <OPRL2>
#include <zcmd>
#include <sscanf2>


//==============================================================================
//                          Dialog IDS
//              (change these ids in case if it collides)
//==============================================================================

#define     DIALOG_SECOND_RCON      		1126
#define     DIALOG_SAFERCON_MAIN    		1127
#define     DIALOG_SAFERCON_WHITELISTIP     1128
#define     DIALOG_SAFERCON_WHITELISTNICK   1129


//==============================================================================
//                          Array sizes
//==============================================================================

#define     MAX_WHITELISTED_IP      100 //Increase or decrease according to the number of whitelisted ips.
#define     MAX_WHITELISTED_NICK   	50 // "                                                         " nicks.


//==============================================================================
//                          Configuration defines
//==============================================================================

#define		MAX_SECONDRCON_WAIT_SEC 40 //Maximum SECONDS to wait for the second RCON password to be given once if requested. 40 is actually more, set it according to the complexity of your pass.
#define     SECOND_RCON_PASS        "pleaSeChangeThisPassword123" //The second RCON pass.

//Set to "false" to disable the feature, "true" to enable.

#define COMPLEX_RCON_CHECK          true
#define WHITELISTED_IP_CHECK        true
#define WHITELISTED_NICK_CHECK      true

#if COMPLEX_RCON_CHECK == true
	#define     MIN_RCONPASS_LENGTH     12
#endif

//==============================================================================
//                          File Path locations
//==============================================================================
#define SAFERCON_WHITELISTED_IP_PATH    "SafeRCON/WhitelistedIps.txt"
#define SAFERCON_WHITELISTED_NICK_PATH  "SafeRCON/WhitelistedNicks.txt"
#define NICK_KICK_LOG                   "SafeRCON/NickKickLog.txt"
#define IP_KICK_LOG                     "SafeRCON/IpKickLog.txt"
#define WRONG_RCON_LOGIN_LOG            "SafeRCON/WrongRCONLogins.txt"



#define strcpy(%0,%1,%2) \
	strcat((%0[0] = '\0', %0), %1, %2)

new
	#if WHITELISTED_IP_CHECK == true
	g_WhiteListedIps[MAX_WHITELISTED_IP][16],
	bool:g_WhiteListIpCheck,
	g_WhiteListIpCount = 0,
	#endif
	
	#if WHITELISTED_NICK_CHECK == true
	g_WhiteListedNicks[MAX_WHITELISTED_NICK][MAX_PLAYER_NAME],
	bool:g_WhiteListNickCheck,
	g_WhiteListNickCount = 0,
	#endif
	
	bool:g_IsPlayerRconEx[MAX_PLAYERS],
	SR_pDialog[MAX_PLAYERS],
	SR_pWrongLogins[MAX_PLAYERS],
	SR_pTimer[MAX_PLAYERS];
	

public OnPlayerConnect(playerid)
{
	g_IsPlayerRconEx[playerid] = false;
	SR_pDialog[playerid] = -1;
	SR_pWrongLogins[playerid] = 0;
	SR_pTimer[playerid] = -1;
	return 1;
}


stock IsPlayerRconEx(playerid)
{
	if(IsPlayerAdmin(playerid) && g_IsPlayerRconEx[playerid]) return true;
	else return false;
}

#if COMPLEX_RCON_CHECK == true

new
	random_Text[] = "0123456789aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ",
	chars[] = "abcdefghijklmnopqrstuvwxyz",
	nums[] = "0123456789";

//Thanks to Lordzy for the randomizing function.
stock GetRandomizedChars(const rchar_array[], trchars[], size = sizeof(trchars),
    rsize = sizeof(rchar_array))
{
    new
        temp_rchar;
    for(new i; i< size; i++)
    {
        temp_rchar = rchar_array[random(rsize)];
        trchars[i] = temp_rchar;
    }
    return 1;
}

stock SetRandomRCONPassword()
{

	new
	    s_Pass[MIN_RCONPASS_LENGTH+3];
	GetRandomizedChars(random_Text, s_Pass, MIN_RCONPASS_LENGTH);

	new
		bool:isValid[3] = {false, ...};

	for(new i, j = strlen(s_Pass); i< j; i++)
	{
	    if(!isValid[0] || !isValid[1] || !isValid[2])
	    {
			for(new a; a< sizeof(chars); a++)
			{
			    if(s_Pass[i] != chars[a]) continue;
				isValid[0] = true;
				break;
			}
			for(new b; b< sizeof(chars); b++)
			{
			    if(s_Pass[i] != toupper(chars[b])) continue;
			    isValid[1] = true;
			    break;
			}
			for(new c; c< sizeof(nums); c++)
			{
			    if(s_Pass[i] != nums[c]) continue;
			    isValid[2] = true;
			    break;
			}
		}
	}
	if(!isValid[0] || !isValid[1] || !isValid[2])
	{
	    new
	        randomDest = random(strlen(s_Pass) - 1);

	    strdel(s_Pass, randomDest, randomDest+1);
		s_Pass[randomDest] = random(9);

		randomDest = random(strlen(s_Pass) - 1);
		
		strdel(s_Pass, randomDest, randomDest+1);
		s_Pass[randomDest] = toupper(chars[random(sizeof(chars))]);
		
		randomDest = random(strlen(s_Pass) - 1);
		
		strdel(s_Pass, randomDest, randomDest+1);
		s_Pass[randomDest] = chars[random(sizeof(chars))];
	}

	new
		str[60];
		
	format(str, sizeof(str), "rcon_password %s", s_Pass);
	SendRconCommand(str);

	return 1;
}

#endif



//Main function of this filterscript!
stock SafeRCONInit()
{

	print("_________________________________________");
	printf("");
	print("\tSafeRCON loading...");
	print("_________________________________________");

	#if COMPLEX_RCON_CHECK == true

	new
	    s_Pass[60];
	GetServerVarAsString("rcon_password", s_Pass, sizeof(s_Pass));
	
	if(strlen(s_Pass) < MIN_RCONPASS_LENGTH)
	{
	    print("SafeRCON : changing password automatically as it is shorter than 10.");
		SetRandomRCONPassword();
	}
	
	new
		bool:isValid[3] = {false, ...};
	for(new i, j = strlen(s_Pass); i< j; i++)
	{
	    if(!isValid[0] || !isValid[1] || !isValid[2])
	    {
			for(new a; a< sizeof(chars); a++)
			{
			    if(s_Pass[i] != chars[a]) continue;
				isValid[0] = true;
				break;
			}
			for(new b; b< sizeof(chars); b++)
			{
			    if(s_Pass[i] != toupper(chars[b])) continue;
			    isValid[1] = true;
			    break;
			}
			for(new c; c< sizeof(nums); c++)
			{
			    if(s_Pass[i] != nums[c]) continue;
			    isValid[2] = true;
			    break;
			}
		}
	}
	if(!isValid[0] || !isValid[1] || !isValid[2])
	{
		SetRandomRCONPassword();
		print("SafeRCON : changing password automatically as it don't seem to be complex!");
	}
	else print("SafeRCON : server is currently running with it's own complex RCON password.");

	#else
	
	print("SafeRCON : server is currently running with it's own RCON password.");

	#endif

 	#if WHITELISTED_IP_CHECK == true
	if(!fexist(SAFERCON_WHITELISTED_IP_PATH))
	{
	    printf("SafeRCON : Warning! File or folder not found : \n%s", SAFERCON_WHITELISTED_IP_PATH);
	    g_WhiteListIpCheck = false;
	}
	else
	{
		new
		    File:fHandle = fopen(SAFERCON_WHITELISTED_IP_PATH, io_read),
			string[32];
			
		g_WhiteListIpCount = 0;

		while(fread(fHandle, string, sizeof(string), false))
		{
			if(g_WhiteListIpCount >= MAX_WHITELISTED_IP)
			{
			    printf("SafeRCON : Warning! More than %d IPs found at %s\n\
					Increase MAX_WHITELISTED_IP on the script.", MAX_WHITELISTED_IP, SAFERCON_WHITELISTED_IP_PATH);
				break;
			}
		    for(new i, j = strlen(string); i< j; i++)
		    {
		        if(string[i] == '\n' || string[i] == '\r')
		            string[i] = '\0';
			}
			
			strcpy(g_WhiteListedIps[g_WhiteListIpCount], string, 16);
			g_WhiteListIpCount++;
	  		g_WhiteListIpCheck = true;

		}
		printf("SafeRCON : %d whitelisted ip's loaded!", g_WhiteListIpCount);
	}
	#endif
	
	#if WHITELISTED_NICK_CHECK == true
	if(!fexist(SAFERCON_WHITELISTED_NICK_PATH))
	{
	    printf("SafeRCON : Warning! File or folder not found : \n%s", SAFERCON_WHITELISTED_NICK_PATH);
	    g_WhiteListNickCheck = false;
	}
	else
	{
	    new
	        File:fHandle = fopen(SAFERCON_WHITELISTED_NICK_PATH, io_read),
	        string[32];

		g_WhiteListNickCount = 0;
		
		while(fread(fHandle, string, sizeof(string), false))
		{
		    if(g_WhiteListNickCount >= MAX_WHITELISTED_NICK)
		    {
		        printf("SafeRCON : Warning! More than %d names found at %s\n\
		            Increase MAX_WHITELISTED_NICK on the script.", MAX_WHITELISTED_NICK, SAFERCON_WHITELISTED_NICK_PATH);
				break;
			}
		    for(new i = 0, j = strlen(string); i< j; i++)
		    {
		        if(string[i] == '\n' || string[i] == '\r')
		            string[i] = '\0';
			}
			strcpy(g_WhiteListedNicks[g_WhiteListNickCount], string, MAX_PLAYER_NAME);
			g_WhiteListNickCount++;
			g_WhiteListNickCheck = true;

		}
		printf("SafeRCON : %d whitelisted names loaded!", g_WhiteListNickCount);
	}
	#endif
	
	for(new i, j = GetMaxPlayers(); i< j; i++)
	    OnPlayerConnect(i);

	printf("SafeRCON : successfully loaded!");
	return 1;
}

public OnPlayerRconLogin(playerid)
{
	new
	    string[256],
		H, M, S,
		Day, Mon, Year,
		pName[MAX_PLAYER_NAME],
		pIp[16];
 
    gettime(H, M, S);
    getdate(Year, Mon, Day);
	GetPlayerName(playerid, pName, sizeof(pName));
	GetPlayerIp(playerid, pIp, 16);
    
    #if WHITELISTED_NICK_CHECK == true

	if(g_WhiteListNickCheck)
	{
	    new
			bool:sRChecks = false;

		for(new i; i< g_WhiteListNickCount; i++)
		{
		    if(strcmp(pName, g_WhiteListedNicks[i], false))
		        continue;
			sRChecks = true;
		}
		if(!sRChecks)
		{
		    Kick(playerid); //Not delaying the kick, you can delay if you want to add any message. But this one's better!

			new
			    File:fHandle = fopen(NICK_KICK_LOG, io_append);

			if(fHandle)
			{
				format(string, sizeof(string), "[%d/%d/%d | %d:%d:%d] %s (ID:%d) (IP:%s) kicked! (Name doesn't match)\r\n",
			    	Year, Mon, Day, H, M, S, pName, playerid, pIp);
				fwrite(fHandle, string);
				fclose(fHandle);
				return 1;
			}
		}
	}
	#endif
	
	#if WHITELISTED_IP_CHECK == true
	
	if(g_WhiteListIpCheck)
	{
	    new
	        bool:sRChecks = false;

	    for(new i; i< g_WhiteListIpCount; i++)
	    {
	        if(strcmp(pIp, g_WhiteListedIps[i], false))
	            continue;
			sRChecks = true;
		}
		if(!sRChecks)
		{
		    Kick(playerid);
		    
		    new
		        File:fHandle = fopen(IP_KICK_LOG, io_append);

			if(fHandle)
			{
				format(string, sizeof(string), "[%d/%d/%d | %d:%d:%d] %s (ID:%d) (IP:%s) kicked! (IP doesn't match)\r\n",
			    	Year, Mon, Day, H, M, S, pName, playerid, pIp);
				fwrite(fHandle, string);
				fclose(fHandle);
				return 1;
			}
		}
	}
	#endif
	
	format(string, sizeof(string), "Hello %s,\n\
	This server uses second RCON feature and you're asked to\n\
	type in the second RCON password to continue.", pName);
	ShowPlayerDialog(playerid, DIALOG_SECOND_RCON, DIALOG_STYLE_PASSWORD, "SafeRCON - Second RCON", string, "Login", "Quit");
	SR_pDialog[playerid] = DIALOG_SECOND_RCON;
	SR_pTimer[playerid] = SetTimerEx("SRIsSecondRconLoggedIn", MAX_SECONDRCON_WAIT_SEC*1000, false, "d", playerid);
	return 1;
}

forward SRIsSecondRconLoggedIn(playerid);
public SRIsSecondRconLoggedIn(playerid)
{
	if(IsPlayerAdmin(playerid))
	{
	    if(IsPlayerRconEx(playerid))
	    {
			SR_pTimer[playerid] = -1;
		}
		else
		{
			SR_pTimer[playerid] = -1;
			Kick(playerid);
		}
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(SR_pTimer[playerid] != -1)
	{
	    KillTimer(SR_pTimer[playerid]);
	    SR_pTimer[playerid] = -1;
	}
	return 1;
}


public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{

	if(dialogid == DIALOG_SECOND_RCON && SR_pDialog[playerid] == dialogid) //To avoid collisions
	{
	    SR_pDialog[playerid] = -1;
	    new
	        pName[MAX_PLAYER_NAME],
	        pIp[16],
	        H, M, S,
	        Year, Mon, Day,
			string[256];
	        
		GetPlayerName(playerid, pName, sizeof(pName));
		GetPlayerIp(playerid, pIp, sizeof(pIp));
		gettime(H, M, S);
		getdate(Year, Mon, Day);
		
	    if(!response)
	    {
	        new
	            File:fHandle = fopen(WRONG_RCON_LOGIN_LOG, io_append);
	            
			if(fHandle)
			{
		        format(string, sizeof(string), "[%d/%d/%d | %d:%d:%d] %s (ID:%d) (IP:%s) kicked for wrong second RCON login! <QUIT>\r\n",
		            Year, Mon, Day, H, M, S, pName, playerid, pIp);
				fwrite(fHandle, string);
				fclose(fHandle);
			}
			return Kick(playerid);
		}
		else if(response)
		{
		    if(!strlen(inputtext) || strcmp(inputtext, SECOND_RCON_PASS, false))
		    {
				SR_pWrongLogins[playerid]++;
				
				if(SR_pWrongLogins[playerid] >= 3)
				{
				    new
				        File:fHandle = fopen(WRONG_RCON_LOGIN_LOG, io_append);

					if(fHandle)
					{
					    format(string, sizeof(string), "[%d/%d/%d | %d:%d:%d] %s (ID:%d) (IP:%s) kicked for wrong second RCON login! (Last Wrong Pass : %s)\r\n",
					        Year, Mon, Day, H, M, S, pName, playerid, pIp, inputtext);
						fwrite(fHandle, string);
						fclose(fHandle);
					}
					return Kick(playerid);
				}
				
				format(string, sizeof(string), "%s,\n\
				The previous second RCON password typed in was incorrect!\n\
				Re-type the correct second RCON password to continue.\n\
				Wrong logins : %d/3", pName, SR_pWrongLogins[playerid]);
				ShowPlayerDialog(playerid, DIALOG_SECOND_RCON, DIALOG_STYLE_PASSWORD, "SafeRCON - Second RCON", string, "Login", "Quit");
				SR_pDialog[playerid] = DIALOG_SECOND_RCON;
				return 1;
			}
			g_IsPlayerRconEx[playerid] = true;

			SendClientMessage(playerid, -1, "SafeRCON : You have successfully logged in as full RCON administrator!");
			GameTextForPlayer(playerid, "~R~~H~~H~SAFERCON~N~~G~~H~~H~FULL RCON ADMINISTRATOR", 2000, 3);

			PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
			return 1;
		}
	}
	if(dialogid == DIALOG_SAFERCON_MAIN && SR_pDialog[playerid] == dialogid)
	{
	    SR_pDialog[playerid] = -1;
	    
	    if(response)
	    {
			if(listitem == 0)
			{
			    #if WHITELISTED_IP_CHECK == true

			    if(g_WhiteListIpCheck)
			        g_WhiteListIpCheck = false;
				else
				    g_WhiteListIpCheck = true;
				return cmd_safercon(playerid, "");

				#else

				SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");
				return cmd_safercon(playerid, "");

				#endif
			}
			if(listitem == 1)
			{
			    #if WHITELISTED_IP_CHECK == true

				new
				    dStr[2048];
				for(new i; i< g_WhiteListIpCount; i++)
				{
				    strins(dStr, g_WhiteListedIps[i], strlen(dStr));
				    strins(dStr, "\r\n", strlen(dStr));
				}
				new
				    minstr[5];
				valstr(minstr, g_WhiteListIpCount);
				strins(dStr, "There are a total of ", strlen(dStr));
				strins(dStr, minstr, strlen(dStr));
				strins(dStr, " ips whitelisted!", strlen(dStr));
				return ShowPlayerDialog(playerid, DIALOG_SAFERCON_MAIN, DIALOG_STYLE_MSGBOX, "SafeRCON - Whitelisted Ips", dStr, "Okay", "");
				//Won't collide because I haven't set the dialog pVar
				
				#else
				
				SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");
				return cmd_safercon(playerid, "");
				
				#endif
				
			}
			if(listitem == 2)
			{
			    #if WHITELISTED_IP_CHECK == true
			    
				SR_pDialog[playerid] = DIALOG_SAFERCON_WHITELISTIP;
				return ShowPlayerDialog(playerid, DIALOG_SAFERCON_WHITELISTIP, DIALOG_STYLE_INPUT, "SafeRCON - WhiteList IP",
				    "Administrator,\nType in the IP address to be whitelisted for RCON logins.", "Confirm", "Back");

				#else
				
				SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");
				return cmd_safercon(playerid, "");
				
				#endif
			}
			if(listitem == 3)
			{
			    #if WHITELISTED_NICK_CHECK == true
			    
			    if(g_WhiteListNickCheck)
			        g_WhiteListNickCheck = false;
				else
				    g_WhiteListNickCheck = true;
				return cmd_safercon(playerid, "");

				#else
				
				SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");
				return cmd_safercon(playerid, "");
				
				#endif
			}
			if(listitem == 4)
			{
			    #if WHITELISTED_NICK_CHECK == true
			    
			    new
			        dStr[2048];
				for(new i; i< g_WhiteListNickCount; i++)
				{
				    strins(dStr, g_WhiteListedNicks[i], strlen(dStr));
				    strins(dStr, "\r\n", strlen(dStr));
				}
				new
				    minstr[5];
				valstr(minstr, g_WhiteListNickCount);
				strins(dStr, "There are a total of ", strlen(dStr));
				strins(dStr, minstr, strlen(dStr));
				strins(dStr, " names whitelisted!", strlen(dStr));
				//SR_pDialog[playerid] = DIALOG_SAFERCON_MAIN; //DialogID with no response is what meant here.
				return ShowPlayerDialog(playerid, DIALOG_SAFERCON_MAIN, DIALOG_STYLE_MSGBOX, "SafeRCON - WhiteListed Nicks", dStr, "Okay", "");

				#else
				
				SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");
				return cmd_safercon(playerid, "");
				
				#endif
			}
			if(listitem == 5)
			{
			    #if WHITELISTED_NICK_CHECK == true
			    
			    SR_pDialog[playerid] = DIALOG_SAFERCON_WHITELISTNICK;
			    return ShowPlayerDialog(playerid, DIALOG_SAFERCON_WHITELISTNICK, DIALOG_STYLE_INPUT, "SafeRCON - Whitelist Nick",
			        "Administrator,\n\
			        Type in the nick name to be whitelisted for RCON logins.", "Confirm", "Back");
				#else
				
				SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");
				return cmd_safercon(playerid, "");
				
				#endif
				
			}
			if(listitem == 6)
			{
				#if WHITELISTED_IP_CHECK == true
				if(!fexist(SAFERCON_WHITELISTED_IP_PATH))
				{
				    printf("SafeRCON : Warning! File or folder not found : \n%s", SAFERCON_WHITELISTED_IP_PATH);
				    SendClientMessage(playerid, 0xFF0000FF, "Execution failed!");
				    g_WhiteListIpCheck = false;
				}
				else
				{
					new
					    File:fHandle = fopen(SAFERCON_WHITELISTED_IP_PATH, io_read),
						string[32];

					g_WhiteListIpCount = 0;

					while(fread(fHandle, string, sizeof(string), false))
					{
						if(g_WhiteListIpCount >= MAX_WHITELISTED_IP)
						{
						    printf("SafeRCON : Warning! More than %d IPs found at %s\n\
								Increase MAX_WHITELISTED_IP on the script.", MAX_WHITELISTED_IP, SAFERCON_WHITELISTED_IP_PATH);
							SendClientMessage(playerid, 0xFF0000FF, "Execution failed!");
							break;
						}
					    for(new i, j = strlen(string); i< j; i++)
					    {
					        if(string[i] == '\n' || string[i] == '\r')
					            string[i] = '\0';
						}

						strcpy(g_WhiteListedIps[g_WhiteListIpCount], string, 16);
						g_WhiteListIpCount++;
						g_WhiteListIpCheck = true;

					}
					printf("SafeRCON : %d whitelisted ip's loaded!", g_WhiteListIpCount);
					SendClientMessage(playerid, 0xFF0000, "SafeRCON : Whitelisted IPs successfully reloaded!");
					return cmd_safercon(playerid, "");
				}
				#else
				
				SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");
				return cmd_safercon(playerid, "");
				
				#endif
			}
			if(listitem == 7)
			{
			    #if WHITELISTED_NICK_CHECK == true
				if(!fexist(SAFERCON_WHITELISTED_NICK_PATH))
				{
				    printf("SafeRCON : Warning! File or folder not found : \n%s", SAFERCON_WHITELISTED_NICK_PATH);
				    SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : Execution failed!");
				    g_WhiteListNickCheck = false;
				}
				else
				{
				    new
				        File:fHandle = fopen(SAFERCON_WHITELISTED_NICK_PATH, io_read),
				        string[32];

					g_WhiteListNickCount = 0;

					while(fread(fHandle, string, sizeof(string), false))
					{
					    if(g_WhiteListNickCount >= MAX_WHITELISTED_NICK)
					    {
					        printf("SafeRCON : Warning! More than %d names found at %s\n\
					            Increase MAX_WHITELISTED_NICK on the script.", MAX_WHITELISTED_NICK, SAFERCON_WHITELISTED_NICK_PATH);
							SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : Execution failed!");
							break;
						}
					    for(new i = 0, j = strlen(string); i< j; i++)
					    {
					        if(string[i] == '\n' || string[i] == '\r')
					            string[i] = '\0';
						}
						strcpy(g_WhiteListedNicks[g_WhiteListNickCount], string, MAX_PLAYER_NAME);
						g_WhiteListNickCount++;
     					g_WhiteListNickCheck = true;

					}
					printf("SafeRCON : %d whitelisted names loaded!", g_WhiteListNickCount);
					SendClientMessage(playerid, 0xFF0000, "SafeRCON : Whitelisted names successfully reloaded!");
					return cmd_safercon(playerid, "");
				}
				
				#else
				
				SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");
				return cmd_safercon(playerid, "");
				
				#endif
			}
		}
	}
	if(dialogid == DIALOG_SAFERCON_WHITELISTIP && SR_pDialog[playerid] == dialogid)
	{
	    SR_pDialog[playerid] = -1;

		#if WHITELISTED_IP_CHECK == false
		
		return SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");
		
		#else
		
		if(response)
		{
		    if(!strlen(inputtext))
		    {
		    
		        SendClientMessage(playerid, 0xFF0000FF, "ERROR : No input was given!");
		        return cmd_safercon(playerid, "");
			}
			else
			{
			    new
					iStr[16];

				strcpy(iStr, inputtext, sizeof(iStr));
			    SafeRCON_WhiteList(0, iStr);
				SendClientMessage(playerid, 0xFF0000, "SafeRCON : The given IP address have been whitelisted, reload the IP list to refresh the list.");
				return cmd_safercon(playerid, "");
			}
		}
		if(!response) return cmd_safercon(playerid, "");
		
		#endif
	}
	if(dialogid == DIALOG_SAFERCON_WHITELISTNICK && SR_pDialog[playerid] == dialogid)
	{
	    SR_pDialog[playerid] = -1;
	    
	    #if WHITELISTED_NICK_CHECK == false
	    
	    return SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : This feature is currently disabled.");

		#else
		
		if(response)
		{
		    if(!strlen(inputtext))
		    {
		        SendClientMessage(playerid, 0xFF0000FF, "ERROR : No input was given!");
				return cmd_safercon(playerid, "");
			}
			else
			{
			    new
			        nStr[MAX_PLAYER_NAME];
			        
				strcpy(nStr, inputtext, sizeof(nStr));
			    SafeRCON_WhiteList(1, nStr);
			    SendClientMessage(playerid, 0xFF0000, "SafeRCON : The given nick name have been whitelisted, reload the nick list to refresh the list.");
				return cmd_safercon(playerid, "");
			}
		}
		if(!response) return cmd_safercon(playerid, "");
		
		#endif
	}
	return 1;
}

public OnRconCommand(cmd[])
{
 	#if WHITELISTED_IP_CHECK == true
 	
 	if(!strcmp(cmd, "safercon reloadips", true))
 	{
		if(!fexist(SAFERCON_WHITELISTED_IP_PATH))
		{
		    printf("SafeRCON : Warning! File or folder not found : \n%s", SAFERCON_WHITELISTED_IP_PATH);
		    g_WhiteListIpCheck = false;
		}
		else
		{
			new
			    File:fHandle = fopen(SAFERCON_WHITELISTED_IP_PATH, io_read),
				string[32];

			g_WhiteListIpCount = 0;

			while(fread(fHandle, string, sizeof(string), false))
			{
				if(g_WhiteListIpCount >= MAX_WHITELISTED_IP)
				{
				    printf("SafeRCON : Warning! More than %d IPs found at %s\n\
						Increase MAX_WHITELISTED_IP on the script.", MAX_WHITELISTED_IP, SAFERCON_WHITELISTED_IP_PATH);
					break;
				}
			    for(new i, j = strlen(string); i< j; i++)
			    {
			        if(string[i] == '\n' || string[i] == '\r')
			            string[i] = '\0';
				}

				strcpy(g_WhiteListedIps[g_WhiteListIpCount], string, 16);
				g_WhiteListIpCount++;
				g_WhiteListIpCheck = true;

			}
			printf("SafeRCON : %d whitelisted ip's loaded!", g_WhiteListIpCount);
		}
		return 1;
	}
	
	if(!strcmp(cmd, "safercon list whitelistip", true))
	{
	    print("SafeRCON - Whitelisted IP Addresses");
	    for(new i; i< g_WhiteListIpCount; i++)
	    {
			printf("%s", g_WhiteListedIps[i]);
		}
		printf("");
		printf("There are %d ips whitelisted!", g_WhiteListIpCount);
		return 1;
	}
		
	#endif
	
	#if WHITELISTED_NICK_CHECK == true
	
	if(!strcmp(cmd, "safercon reloadnicks", true))
	{
		if(!fexist(SAFERCON_WHITELISTED_NICK_PATH))
		{
		    printf("SafeRCON : Warning! File or folder not found : \n%s", SAFERCON_WHITELISTED_NICK_PATH);
		    g_WhiteListNickCheck = false;
		}
		else
		{
		    new
		        File:fHandle = fopen(SAFERCON_WHITELISTED_NICK_PATH, io_read),
		        string[32];

			g_WhiteListNickCount = 0;

			while(fread(fHandle, string, sizeof(string), false))
			{
			    if(g_WhiteListNickCount >= MAX_WHITELISTED_NICK)
			    {
			        printf("SafeRCON : Warning! More than %d names found at %s\n\
			            Increase MAX_WHITELISTED_NICK on the script.", MAX_WHITELISTED_NICK, SAFERCON_WHITELISTED_NICK_PATH);
					break;
				}
			    for(new i = 0, j = strlen(string); i< j; i++)
			    {
			        if(string[i] == '\n' || string[i] == '\r')
			            string[i] = '\0';
				}
				strcpy(g_WhiteListedNicks[g_WhiteListNickCount], string, MAX_PLAYER_NAME);
				g_WhiteListNickCount++;
	   			g_WhiteListNickCheck = true;

			}
			printf("SafeRCON : %d whitelisted names loaded!", g_WhiteListNickCount);
		}
		return 1;
	}
	

	if(!strcmp(cmd, "safercon list whitelistnick", true))
	{
	    print("SafeRCON - Whitelisted Nick Names");
	    for(new i; i< g_WhiteListNickCount; i++)
	    {
	        printf("%s", g_WhiteListedNicks[i]);
		}
		printf("");
		printf("There are %d nicks whitelisted!", g_WhiteListNickCount);
		return 1;
	}
	
	#endif
	if(strcmp(cmd, "safercon", true, 8)) return 0;

	new
		sfcmd[10],
		sfoption[15],
		params[32];

	if(sscanf(cmd, "s[10]s[15]s[32]", sfcmd, sfoption, params))
	    return print("SafeRCON : Wrong Syntax! Usage : safercon [command] [params]");

	#if WHITELISTED_IP_CHECK == true

	if(!strcmp(sfoption, "whitelistip", true))
	{
	    if(!strlen(params)) return print("SafeRCON : No params entered!");
		SafeRCON_WhiteList(0, params);
		printf("SafeRCON : %s IP address have been white listed!", params);
		return 1;
	}
	
	#endif
	
	#if WHITELISTED_NICK_CHECK == true

	if(!strcmp(sfoption, "whitelistnick", true))
	{
	    if(!strlen(params)) return print("SafeRCON : No params entered!");
	    SafeRCON_WhiteList(1, params);
		printf("SafeRCON : %s nick name have been white listed!", params);
		return 1;
	}
	
	#endif
	return 1;
}

stock SafeRCON_WhiteList(type, addr[], size = sizeof(addr))
{
	#if WHITELISTED_IP_CHECK == true

	if(type == 0)
	{

	    if(g_WhiteListIpCount >= MAX_WHITELISTED_IP)
	        return printf("SafeRCON : Warning! IP list count exceeded %d value.\n\
	        Increase the value of MAX_WHITELISTED_IP on the script.", MAX_WHITELISTED_IP);

		new
		    File:fHandle = fopen(SAFERCON_WHITELISTED_IP_PATH, io_append);

		if(fHandle)
		{
			strins(addr, "\r\n", 0, size);
			fwrite(fHandle, addr);
			fclose(fHandle);
		}
		strcpy(g_WhiteListedIps[g_WhiteListIpCount], addr, 16);
		return 1;
	}
	
	#endif
	
	#if WHITELISTED_NICK_CHECK == true

	if(type == 1)
	{
	    if(g_WhiteListNickCount >= MAX_WHITELISTED_NICK)
			return printf("SafeRCON : Warning! Nick list count exceeded %d value.\n\
			Increase the value of MAX_WHITELISTED_NICK on the script.", MAX_WHITELISTED_NICK);
			
		new
		    File:fHandle = fopen(SAFERCON_WHITELISTED_NICK_PATH, io_append);
		    
		if(fHandle)
		{
		    strins(addr, "\r\n", 0, size);
		    fwrite(fHandle, addr);
		    fclose(fHandle);
		}
		strcpy(g_WhiteListedNicks[g_WhiteListNickCount], addr, MAX_PLAYER_NAME);
		return 1;
	}

	#endif
	
	return 1;
}

public OnPlayerText(playerid, text[])
{
	if(IsPlayerAdmin(playerid) && !IsPlayerRconEx(playerid))
	{
	    Kick(playerid);
	    return 0;
	}
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(IsPlayerAdmin(playerid) && !IsPlayerRconEx(playerid))
	{
	    Kick(playerid);
	    return 0;
	}
	return 1;
}

#if WHITELISTED_IP_CHECK == true || WHITELISTED_NICK_CHECK == true

CMD:safercon(playerid, params[])
{
	if(!IsPlayerRconEx(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "SafeRCON : Only RCON administrators are allowed to use this feature!");
	new
	    string[500];
	
	#if WHITELISTED_IP_CHECK == true
	
	if(g_WhiteListIpCheck)
	    strins(string, "Whitelist IP Detection      [{0EF071}Enabled{FFFFFF}]", strlen(string));
	else
	    strins(string, "Whitelist IP Detection      [{FF0000}Disabled{FFFFFF}]", strlen(string));
	    
	#else
	
	strins(string, "Whitelist IP Detection [{FF0000}Disabled{FFFFFF}]", strlen(string));
	
	#endif
	    
	strins(string, "\nView Whitelisted IP addresses", strlen(string));
	strins(string, "\nWhitelist IP address", strlen(string));

	#if WHITELISTED_NICK_CHECK == true
	if(g_WhiteListNickCheck)
	    strins(string, "\nWhitelist Nick Detection		[{0EF071}Enabled{FFFFFF}]", strlen(string));
	else
	    strins(string, "\nWhitelist Nick Detection        [{FF0000}Disabled{FFFFFF}]", strlen(string));
	    
	#else
	
	strins(string, "\nWhitelist Nick Detection [{FF0000}Disabled{FFFFFF}]", strlen(string));
	
	#endif
	
	strins(string, "\nView Whitelisted Nick names", strlen(string));
	strins(string, "\nWhitelist Nick name", strlen(string));
	strins(string, "\nReload Whitelisted IP Addresses", strlen(string));
	strins(string, "\nReload Whitelisted Nick Names", strlen(string));

	ShowPlayerDialog(playerid, DIALOG_SAFERCON_MAIN, DIALOG_STYLE_LIST, "SafeRCON - Main Panel",
		string, "Select", "Cancel");
	SR_pDialog[playerid] = DIALOG_SAFERCON_MAIN;
	return 1;
}

#else

CMD:safercon(playerid, params[])
{
	return 1;
}

#endif

public OnFilterScriptInit()
{

	SafeRCONInit();
	return 1;
}


