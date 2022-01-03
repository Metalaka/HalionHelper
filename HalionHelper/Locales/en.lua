-- default locale

local name = ...

local L = LibStub("AceLocale-3.0"):NewLocale(name, "enUS", true)

-- Blizzard strings
L["ZoneName"] = "The Ruby Sanctum"
L["Yell_Phase2"] = "You will find only suffering within the realm of twilight! Enter if you dare!"
L["Yell_Phase3"] = "I am the light and the darkness! Cower, mortals, before the herald of Deathwing!"
L["Announce_TwilightCutter"] = "The orbiting spheres pulse with dark energy!"

-- Addon strings
L["AddonName"] = "Halion Helper"
L["Settings"] = "Halion Helper Settings"
L["Loaded"] = "loaded - Have fun!"
L["NewVersion"] = "New version available. Download update at: %s"
L["UpdateRequired"] = "Addon disabled. Version too old. Download latest version at: %s"
L["AnnounceTwilightBossEngaged"] = "Twilight Halion engaged, pass through the portal!"
L["Twilight"] = "Twilight Realm"
L["Physical"] = "Physical Realm"
L["AnnounceStop"] = "%s - STOP DPS"

-- Options
L["option_header_desc"] = "General settings for Halion Helper."
L["option_enable_name"] = "Enable addon"
L["option_enable_desc"] = "Enable or disable the addon."
L["option_move_name"] = "Enable move mode"
L["option_move_desc"] = "Unlock main frame to allow being dragged. Locking will refresh others frames."
L["option_cutter_name"] = "Enable cutter frame"
L["option_cutter_desc"] = "This feature indicate where the orbs must be positioned to be safe when the next cutter will spawn. "..
        "Designed for tanks, it allow to anticipate the position of the first cutter."
L["option_texture_name"] = "Bar Texture"
L["option_texture_desc"] = "Texture of every bar of the addon."
L["option_texture_error"] = "Can't set texture to %s."
L["option_announceOpenPhase2_name"] = "Enable announce on aggro Twilight Halion"
L["option_announceOpenPhase2_desc"] = "Send a raid warning when the Main Tank or Main Assist first hit Twilight Halion. "..
        "The Twilight Tank must have the addon. Allow to know when Twilight Halion is tanked."
