# DWPlus
DWPlus is RP**(Roll points)** system written with intent to track all aspects of Roll/Consul/DKP and looting within WoW. Every member of the guild can have it and have full access to real-time RP values as well as loot and RP history.
This is my first official go at writting an addon despite 15 years of playing the game. So if any bugs or errors show their face, please let me know. Any suggestions or requests are also welcome!  
  
**Features**  
	- RP Table entries provide a tooltip showing the players recently spent and earned RP.  
	- Filter the table by certain classes or show only those in your party / raid. Table columns can also be sorted by Player, Class or DKP.  
	- Loot history. What item was won, by whom, from what boss/zone, and how much they spent on it. Can be filtered by player.  
	- RP history. Comprehensive list of all players that received (or lost) rp for each event.  
	- Bid timer displaying what is currently up for bid as well as it's minimum bid.  
  
**Officer only features**  
	- Bid window (opened by SHIFT+ALT clicking an item in the loot window or by typing /rp bid [item link]) that starts bidding, collects all bids submitted, and awards the item. NOTE: Shift+Alt clicking an item only works if the item in in one of the first 4 slots of the loot window due to restrictions at the moment. If the item you wish to bid on isn't on the first page, either loot all items on that first page, close and reopen window. Or simply use /rp bid [item link]  
	- Adjust RP tab (awarding RP). Also includes a RP Decay option that reduces all entries by X% (default set in options or change on the fly in the Adjust RP tab).  
	- Manage Tab. Used to broadcast complete tables to everyone in the guild if required as well as add/remove player entries.  
	- Shift+Click entries in the table to select multiple players to modify.  
	- Right click context menu in Loot History to reassign items (if minds are changed after awarding) which will subsequently give the RP cost back to the initial owner and charge it to the new recipient.  
	- Boss Kill Bonus auto selects the last killed boss/zone.  
	- Options window has additional fields to set bonus defaults (On time bonus, boss kill bonus etc).  
  
**Redundencies**
	- All entries can only be edited / added by officers in the guild (this is determined by checking Officer Note Writing permissions).  
	- If the addon is modified to grant a player access to the options available only to officers, attempting to broadcast a modified table will notify officers of this action.  
	- Every time an officer adds an entry or modifies a RP value, the public note of the Guild Leader is changed to a time stamp. That time stamp is used to notify other users if they do or do not have the most up-to-date tables.  
  
**Commands**  
	/rp ?  	- Lists all available commands  
	/rp 		- Opens Main GUI.  
	/rp timer	- Starts a raid timer (Officers Only) IE: /rp timer 120 Pizza Break!  
	/rp reset 	- Resets GUI position.  
	/rp export  - Exports all entries to HTML (To avoid crashing this will only export the most recent 200 loot history items and 200 RP history items).  
	/rp bid 	- Opens Bid Window. If you include an item link (/rp bid [item link]) it will include that item for bid information.  
	/rp mmb     - Show/Hide minimap icon.  
	/rp changelog - Show changelog window.
  
**Recommendations**  
	- Due to the volatile nature of WoW Addons and saved variables, it's recommended you back up your SavedVariables file located at "WTF\Accounts\ACCOUNT_NAME\SavedVariables\DWPlus.lua" at the end of every raid week to ensure all data
	  isn't lost due to somehow losing your WTF folder.  
	- Export RP to HTML at the end of a raid week and paste into an HTML file and keep a week by week log in Discord for players to view outside of the game. This will also give you a backup of the data to reapply in the event data is lost.  
