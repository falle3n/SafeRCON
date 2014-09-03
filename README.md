/*

================================================================================
							SafeRCON - v1
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
  
  
================================================================================        */
