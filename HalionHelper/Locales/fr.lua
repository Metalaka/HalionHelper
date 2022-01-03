if GetLocale() ~= "frFR" then return end

local name = ...

local L = LibStub("AceLocale-3.0"):NewLocale(name, "frFR")

-- Blizzard strings
L["ZoneName"] = "Le sanctum Rubis"
L["Yell_Phase2"] = "Vous ne trouverez que souffrance au royaume du Crépuscule ! Entrez si vous l'osez !"
L["Yell_Phase3"] = "Je suis la lumière et l'ombre ! Tremblez, mortels, devant le héraut d'Aile-de-mort !"
L["Announce_TwilightCutter"] = "Les sphères volantes rayonnent d'énergie noire !"

-- Addon strings
L["AddonName"] = "Halion Helper"
L["Settings"] = "Options de Halion Helper"
L["Loaded"] = "Chargé - Bon jeu !"
L["NewVersion"] = "Une nouvelle version est disponnible: %s"
L["UpdateRequired"] = "Addon désactivé! La version est trop ancienne. Télécharger la dernière version: %s"
L["AnnounceTwilightBossEngaged"] = "Halion ombre engagé, passer le portail !"
L["Twilight"] = "OMBRE"
L["Physical"] = "LUMIÈRE"
L["AnnounceStop"] = "%s - STOP DPS"

-- Options
L["option_header_desc"] = "Configuration général de Halion Helper."
L["option_enable_name"] = "Active l'addon"
L["option_enable_desc"] = "Active ou désactive l'addon."
L["option_move_name"] = "Déverouille les fenêtres"
L["option_move_desc"] = "Permet de déplacer la fenêtre principale de l'addon. Les autres bars sont repositionnée lors du verrouillage."
L["option_cutter_name"] = "Active le module \"cutter\""
L["option_cutter_desc"] = "Indique où doivent être les orbe pour le prochain cutter. "..
        "Prévu pour permettre aux tanks d'anticiper le placement du premier cutter."
L["option_texture_name"] = "Texture des bars"
L["option_texture_desc"] = "Modifie la texture de toutes les bars de l'addon."
L["option_texture_error"] = "Impossible de modifier la texture en %s."
L["option_announceOpenPhase2_name"] = "Active l'annonce au pull d'Halion ombre"
L["option_announceOpenPhase2_desc"] = "Envoie un avertissement raid quand un des tanks aggro Halion ombre. "..
        "Le tank ombre doit avoir l'addon activé. Permet de savoir quand le tank ombre est placé et à prise l'aggro."
