/**********************************************************************************
* SniperMod by KrX
* Converts Marine's pistol to a sniper rifle.
* Does a certain amount of damage(default 110) and has only 1 bullet in his clip.
* Reloads require 10 bullets, but will appear as one in his clip (definable by CVAR)
* Resupply can be blocked (definable) using Darkness' Resupply Emulator.
* 
* Special Thanks: peachy, for alot of help with the plugin
* 		  gr1mre4p3r, for ideas
*		  The many people who helped to test
*		  Xylith, for his AdminXP plugin (took his enums)
*		  Extralevels (Xylith took the enums from it. =X)
*		  steve, for his ns_popup_var
*		  Darkness, for helping with the getting of level.
*
* Changelog		v2.0
*			-> Fixed up most of the parts, with help from peachy
*			v2.1
*			-> Added the [SniperMod] prefix for messages
*			-> Made the /sniperhelp command
*			v2.2
*			-> peachy helped to clean up the code
*			-> Bullets will now be 1 in the clip, but the usual for the reserve
*			-> Reloads will take 10 bullets
*			-> No more resupply spamming bug
*			v2.3
*			-> Added the precaching to prepare for the next release
*			v2.4
*			-> Added the level requirement setting
*			v2.5
*			-> Added Helper support
*			-> Removed the /sniperhelp command
*			-> Initial Release on ModNS
*			v2.6
*			-> Fixed the current exp bug
*			v2.7
*			-> Changed exp to level
*			-> Added new defines, requiredlvl2 & announcetoall. See defines.
*			-> Switched to using ns_popups instead of client_prints. Except for announcements.
*			v2.8
*			-> Added the shooting sound (recorded =D)
*			-> Added the 2 defines, HELPER & RESUPPLY in the comments
*			-> Aliens can now use /sniperget to check Sniper's damage, and required level.
*			-> Internal Cleanup
*			v2.9
*			-> Done model change.
*			-> Added say_team commands
*			-> Added option of blocking Resupply (requires Resupply Emulator)
*			-> Made plugin pause on classic maps
*			-> Removed enums & major cleanup
*			-> Only requires one define for the requiredlvl (Now uses a formula. Thanks peachy!)
*			-> Thanks to peachy for help with fakemeta
*			-> Added zoomin/zoomout console commands.
*			v3.0 (MAJOR UPDATE)
*			-> Model bugs fixed
*			-> Uses fakemeta for model changing/event handling
*			-> zoomin/zoomout commands added a check if client is allowed to
*			-> Added info texts to print on server console
*			-> Sound temporarily removed, to be used for done for next release
*			-> Used static variables where needed
*			-> Cleaned up code, removed line breaks where not needed.
*			-> Commented future release(s) code
*
*
* CVARs: 		amx_smdmg (default:110) <- Change this for the amount of damage sniper does
*			amx_smclip (default:1)	<- Change this for the amount of bullets stored in clip
*
* Defines:		requiredlvl (default 4) <- Change this for the minimum level
*			announcetoall (default 1) <- Change to 0 if you want to disable announcing
*			HELPER (default 1) <- If you are using -mE-'s Helper, change this to 1, else 0.
*			RESUPPLY (default 0) <- If you are using Darkness's Resupply Emulator, change this to 1, else 0 (note this blocks resupply)
*
* Commands:		/sniperon	(Makes you a Sniper)
*			/sniperoff	(Makes you become normal again)
*			/sniperget	(Gets your current status)
*			/sniperhelp	(Shows Sniper help)
*			zoomin (Zooms in, fov 45)
*			zoomout (Zooms out, fov 0)
*
* Upcoming Releases:	-> To re-add awp sound
*			-> To fully implement Resupply Emulator
*			-> Glow Snipers (by cvar)
*			-> #pragma semicolon 1;
*
***********************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <ns>
#include <fakemeta>
#include <engine>

#define HELPER 1		// 1 if Helper is running, 0 if not.
#define RESUPPLY 0		// 1 if you want to block Resupply (requires Resupply Emulator by Darkness)

#if HELPER == 1			// if Helper is running, see define HELPER
#include <helper>
#endif
#if RESUPPLY == 1		// if Resupply Emulator is running, see define RESUPPLY
#include <resupply>
#endif

// Change the below define for the required level.
#define requiredlvl 4
// Below define defines whether to announce to all players that he is a Sniper.
#define announcetoall 1

static cvar_amx_smdmg, cvar_amx_smclip;
static plugin_version[] = "3.0";
new onsnipemode[33];
new pistolid[33];
new name[33];
new isusingpistol[33];

//static ShootSound[] = "sfx/awp_shoot.mp3";
static awp_viewModel[] = "models/v_awp.mdl";
static awp_weapModel[] = "models/p_awp.mdl";
//static awp_worldModel[] = "models/w_awp.mdl";
//static awp_prevWorldM[] = "models/w_hg.mdl";

public plugin_init()
{
	register_plugin("SniperMod", plugin_version, "KrX");
	register_cvar("KrX_snipermod",plugin_version,FCVAR_SERVER);
	
	if ( !ns_is_combat() )
	{
		pause("ad");
		server_print("[SniperMod v%s] Game is combat, disabling SniperMod.", plugin_version);
		return;
	}
	
	register_clcmd("say /sniperon", "set_sniper");
	register_clcmd("say /sniperoff", "stop_sniper");
	register_clcmd("say /sniperget", "get_status");
	register_clcmd("say /sniperhelp", "show_help");
	register_clcmd("say_team /sniperon", "set_sniper");
	register_clcmd("say_team /sniperoff", "stop_sniper");
	register_clcmd("say_team /sniperget", "get_status");
	register_clcmd("say_team /sniperhelp", "show_help");
	register_clcmd("zoomin", "zoomin");
	register_clcmd("zoomout", "zoomout");
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=6");
	//register_forward(FM_SetModel, "fw_SetModel");
	register_event("DeathMsg", "client_died", "ab");
	
	register_cvar("amx_smdmg", "110");
	register_cvar("amx_smclip", "1");
	cvar_amx_smdmg = get_cvar_pointer("amx_smdmg");
	cvar_amx_smclip = get_cvar_pointer("amx_smclip");
	
	server_print("[SniperMod v%s] Loaded Succesfully!", plugin_version);
}

public plugin_precache()
{
	//engfunc(EngFunc_PrecacheSound, ShootSound);
	engfunc(EngFunc_PrecacheModel, awp_viewModel);
	engfunc(EngFunc_PrecacheModel, awp_weapModel);
	//engfunc(EngFunc_PrecacheModel, awp_worldModel);
	server_print("[SniperMod v%s] Files precached", plugin_version);
}

public Event_CurWeapon(id) 
{
	if (onsnipemode[id] && pistolid[id])
	{
		// Get user's current weapon
		new weaponID = read_data(2) 
        
		// Not pistol? Continue
		if(weaponID != WEAPON_PISTOL) { return PLUGIN_HANDLED; }

		// Change models
		set_pev(id, pev_viewmodel2, awp_viewModel)
		set_pev(id, pev_weaponmodel2, awp_weapModel)
	
		ns_set_weap_dmg(pistolid[id], get_pcvar_float(cvar_amx_smdmg))
		
		pistolid[id] = find_ent_by_owner(0, "weapon_pistol", id)
		if (ns_get_weap_clip(pistolid[id]) > 1)
		{
			set_ammo(id)
		} 
		else if (ns_get_weap_clip(pistolid[id]) == 0)
		{
			//emit_sound(id, CHAN_STATIC, ShootSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM ) 
		}
	}
	return PLUGIN_CONTINUE 
}

/*public fw_SetModel(entity, model[])
{
    // check if its a valid entity or else we get errors
    if(!pev_valid(entity)) 
        return FMRES_IGNORED

    // checks if its the model we want to change
    if(!equali(model, awp_prevWorldM)) 
        return FMRES_IGNORED

    new className[33]
    pev(entity, pev_classname, className, 32)
    
    //            dropped weapons                    map weapons                       c4 + grenades
    if(equal(className, "weaponbox") || equal(className, "armoury_entity") || equal(className, "WEAPON_GRENADE"))
    {
        engfunc(EngFunc_SetModel, entity, awp_worldModel)
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}*/

// Client just spawned
public client_spawn(id)
{
	if (onsnipemode[id])
	{
		pistolid[id] = find_ent_by_owner(0, "weapon_pistol", id)
		if (pistolid[id])
		{
			set_ammo(id)
		}
	}
}

// Client changed team, so revert back.
public client_changeteam(id, newteam, oldteam)
{
	onsnipemode[id] = 0
}

// Client has died
public client_died(id)
{
	new victim = read_data(2)
	if (pistolid[victim])
	{
		pistolid[victim] = 0
	}
	return PLUGIN_CONTINUE
}

// Zoom in
public zoomin(id)
{
	isusingpistol[id] = (read_data(1) == 6 && read_data(2) == WEAPON_PISTOL) ? 1 : 0
	if (onsnipemode[id] && isusingpistol[id] && pistolid[id])
	{
		ns_set_fov(id, Float:45.0)
	}
}

// Zoom out
public zoomout(id)
{
	isusingpistol[id] = (read_data(1) == 6 && read_data(2) == WEAPON_PISTOL) ? 1 : 0
	if (onsnipemode[id] && isusingpistol[id] && pistolid[id])
	{
		ns_set_fov(id, Float:0.0)
	}
}

// Set player to be a Sniper
public set_sniper(id)
{
	if (pev(id, pev_team) & 1)
	{
		
		if ( onsnipemode[id] )
		{
			ns_popup_var(id, "[SniperMod] You already are a Sniper.")
		}
		else
		{
			new level = floatround(floatsqroot(ns_get_exp(id) / 25 + 2.21) - 1)
			if ( level >= requiredlvl )
			{
				onsnipemode[id] = 1
				ns_set_weap_dmg(pistolid[id], get_pcvar_float(cvar_amx_smdmg))
				set_ammo(id)
				ns_popup_var(id, "[SniperMod] You will be a Sniper on your next spawn.")
#if announcetoall == 1
				new name[33]
				get_user_name(id, name, 32)
				client_print(0, print_chat, "[SniperMod] %s is now a Sniper", name)
#endif
			}
			else
			{
				client_print(id, print_chat, "[SniperMod] You need to be at least level %d to be a Sniper", requiredlvl)
			}
		}
	}
	return PLUGIN_HANDLED
}

// Set player to revert
public stop_sniper(id)
{
	if (pev(id, pev_team) & 1)
	{
		if ( onsnipemode[id] )
		{
			get_user_name(id, name, 32)
			onsnipemode[id] = 0
			ns_set_weap_dmg(pistolid[id], 30.0)
			ns_popup_var(id, "[SniperMod] You are no longer a sniper.")
#if announcetoall == 1
			client_print(0, print_chat, "[SniperMod] %s is no longer a Sniper", name)
#endif
		}
		else
		{
			ns_popup_var(id, "[SniperMod] You are not even a sniper...")
		}
	}
	return PLUGIN_HANDLED
}

// Get current status
public get_status(id)
{
	new dmg = get_cvar_num("amx_smdmg")
	if (pev(id, pev_team) & 1)
	{
		if (onsnipemode[id])
		{
			ns_popup_var(id, "[SniperMod] You are a Sniper.^nSniper's Damage: %d, Required Level: %d.^nYour Level: %d", dmg, requiredlvl, floatround(floatsqroot(ns_get_exp(id) / 25 + 2.21) - 1))
		}
		else
		{
			ns_popup_var(id, "[SniperMod] You are NOT a Sniper.^nSniper's Damage: %d, Required Level: %d.^nYour Level: %d", dmg, requiredlvl, floatround(floatsqroot(ns_get_exp(id) / 25 + 2.21) - 1))
		}
	}
	else 
	{
		ns_popup_var(id, "[SniperMod] Sniper's Damage: %d, Required Level: %d.^nNote: for Marines only.", dmg, requiredlvl)
	}
	return PLUGIN_HANDLED
}

public show_help(id)
{
#if HELPER == 1
	ns_popup_var(id, "[SniperMod] Helper is enabled. Say /help and select the SniperMod option to view help.")
#else
	ns_popup_var(id, "[SniperMod] Say /sniperon to be a sniper, /sniperoff to stop being a sniper. /sniperget to view requirements.")
#endif
	return PLUGIN_HANDLED
}

stock ns_popup_var(id, const msg[], ...)
{
	static temp[180];
	vformat(temp,sizeof(temp)-1,msg,3);
	ns_popup(id,temp);
}

// Set ammo stock
stock set_ammo(id)
{
	ns_set_weap_clip(pistolid[id], get_pcvar_num(cvar_amx_smclip))
	ns_set_weap_reserve(id, WEAPON_PISTOL, 10)
}

stock getModName(modNum)
{
	new tempGot[10]
	switch(modNum)
	{
		case 1:
		tempGot = "kn";
		
		case 2:
		tempGot = "hg";
		
		case 3:
		tempGot = "mg";
		
		case 4:
		tempGot = "shotgun";
		
		case 5:
		tempGot = "hmg";
		
		case 6:
		tempGot = "welder";
		
		case 7:
		tempGot = "mine";
		
		case 8:
		tempGot = "gg";
		
		case 9:
		tempGot = "gr";
	}
	return tempGot;
}

// Only block resupply when we want it to
#if RESUPPLY == 1
public nshook_Resupply(id, iStage)
{
	if ( onsnipemode[id] )
	{
		ns_popup_var(id, "[SniperMod] Resupply is not allowed when you are a Sniper.")
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}
#endif

// Helper Info
#if HELPER == 1					// if helper is running, see define HELPER
/************************************************
client_help( id )
Public Help System
************************************************/

public client_help(id)
{
  help_add("Information","This plugin allows Marines to be Snipers.")
  help_add("Commands","/sniperon^n/sniperoff^n/sniperget")
  help_add("About","/sniperon: Makes the player a sniper on next spawn.^n/sniperoff: Makes player revert to a normal Marine^n/sniperget: Get player's current Sniper status")
  help_add("Note","Only marines are able to use /sniperon and /sniperoff. /sniperget can be used by aliens too.")
}

public client_advertise(id)
{
	return PLUGIN_CONTINUE
}

#endif
