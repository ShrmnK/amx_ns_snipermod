# SniperMod
SniperMod on NSMod: http://www.nsmod.org/forums/index.php?showtopic=9527

## Where to place files?

Everything in the "sound" folder goes into "<path_to_ns_server>/ns/sound/"
 -> sound/sfx/zoomin.mp3
 -> sound/sfx/zoomout.mp3
 -> sound/sfx/awp_shoot.wav

Everything in the "models" folder goes into "<path_to_ns_server>/ns/models/"
 -> models/v_awp.mdl
 -> models/p_awp.mdl

## Compilation

Compiling the plugin, by default, requires the Helper include, which can be found at
http://www.nsmod.org/forums/index.php?showtopic=3784

If you do not want Helper support, open up the SMA, and edit the defines.

Optionally, you can disallow Resupply by using Darkness' Resupply Emulator, and setting the define RESUPPLY to 1
This will require the resupply.inc include, which can be found at
http://www.nsmod.org/forums/index.php?showtopic=7212

Please ensure that your desired definitions are set accordingly before compiling!

## Credits
* peachy, for alot of help with the plugin
* gr1mre4p3r, for ideas
* The testers and bug-reporters: s095, +hairy+, Sgt.Riot, iBlank, Fixer
* steve, for his `ns_popup_var`
* Darkness, for helping with the getting of level, and zooming in/out
* Cheap_Suit(from AlliedModders forums) for his tutorial on Changing weapon models
* endgame, for his `#tryinclude` template
* Mini_Midget on AlliedModders, for his `public Event_WeaponFire( id )`
* FPSBanana.com, for the AWP models
* HL2:Substance GOLD, for the AWP sounds
* NSMod.org, for such a great community and website dedicated to NS and its mods!
