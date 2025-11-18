local LSM = LibStub("LibSharedMedia-3.0")
local koKR, ruRU, zhCN, zhTW, western = LSM.LOCALE_BIT_koKR, LSM.LOCALE_BIT_ruRU, LSM.LOCALE_BIT_zhCN, LSM.LOCALE_BIT_zhTW, LSM.LOCALE_BIT_western

local MediaType_BACKGROUND = LSM.MediaType.BACKGROUND or "background"
local MediaType_BORDER = LSM.MediaType.BORDER or "border"
local MediaType_FONT = LSM.MediaType.FONT or "font"
local MediaType_STATUSBAR = LSM.MediaType.STATUSBAR or "statusbar"
local MediaType_SOUND = LSM.MediaType.SOUND or "sound"


-- --------------
-- Wildu's (1)
-- --------------
-- LSM:Register(MediaType_STATUSBAR, "WildArrow", [[Interface\AddOns\!WilduTools\Media\Icons\Arrow.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildCombat", [[Interface\AddOns\!WilduTools\Media\Icons\Combat.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildCombatMaterial", [[Interface\AddOns\!WilduTools\Media\Icons\CombatMaterial.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildCombatStylized", [[Interface\AddOns\!WilduTools\Media\Icons\CombatStylized.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildMaterialDPS", [[Interface\AddOns\!WilduTools\Media\Icons\MaterialDPS.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildMaterialHeal", [[Interface\AddOns\!WilduTools\Media\Icons\MaterialHeal.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildMaterialTank", [[Interface\AddOns\!WilduTools\Media\Icons\MaterialTank.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildNewDPS", [[Interface\AddOns\!WilduTools\Media\Icons\NewDPS.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildNewHeal", [[Interface\AddOns\!WilduTools\Media\Icons\NewHeal.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildNewSmallDPS", [[Interface\AddOns\!WilduTools\Media\Icons\NewSmallDPS.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildNewSmallHeal", [[Interface\AddOns\!WilduTools\Media\Icons\NewSmallHeal.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildNewSmallTank", [[Interface\AddOns\!WilduTools\Media\Icons\NewSmallTank.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildNewTank", [[Interface\AddOns\!WilduTools\Media\Icons\NewTank.tga]])
-- LSM:Register(MediaType_STATUSBAR, "Wildquest", [[Interface\AddOns\!WilduTools\Media\Icons\quest.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildResting", [[Interface\AddOns\!WilduTools\Media\Icons\Resting.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildResting2", [[Interface\AddOns\!WilduTools\Media\Icons\Resting2.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildStylizedDPS", [[Interface\AddOns\!WilduTools\Media\Icons\StylizedDPS.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildStylizedHeal", [[Interface\AddOns\!WilduTools\Media\Icons\StylizedHeal.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildStylizedTank", [[Interface\AddOns\!WilduTools\Media\Icons\StylizedTank.blp]])
-- LSM:Register(MediaType_STATUSBAR, "WildWhiteDPS", [[Interface\AddOns\!WilduTools\Media\Icons\WhiteDPS.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildWhiteHeal", [[Interface\AddOns\!WilduTools\Media\Icons\WhiteHeal.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildWhiteTank", [[Interface\AddOns\!WilduTools\Media\Icons\WhiteTank.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildBlizzDPS", [[Interface\AddOns\!WilduTools\Media\Icons\dps.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildBlizzHeal", [[Interface\AddOns\!WilduTools\Media\Icons\heal.tga]])
-- LSM:Register(MediaType_STATUSBAR, "WildBlizzTank", [[Interface\AddOns\!WilduTools\Media\Icons\tank.tga]])


-- ----------
-- BORDER (19)
-- ----------

-- LSM:Register(MediaType_BORDER, "Ferous 1", [[Interface\AddOns\!WilduTools\Media\Border\Ferous1.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 2", [[Interface\AddOns\!WilduTools\Media\Border\Ferous2.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 3", [[Interface\AddOns\!WilduTools\Media\Border\Ferous3.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 4", [[Interface\AddOns\!WilduTools\Media\Border\Ferous4.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 5", [[Interface\AddOns\!WilduTools\Media\Border\Ferous5.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 6", [[Interface\AddOns\!WilduTools\Media\Border\Ferous6.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 7", [[Interface\AddOns\!WilduTools\Media\Border\Ferous7.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 8", [[Interface\AddOns\!WilduTools\Media\Border\Ferous8.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 9", [[Interface\AddOns\!WilduTools\Media\Border\Ferous9.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 10", [[Interface\AddOns\!WilduTools\Media\Border\Ferous10.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 11", [[Interface\AddOns\!WilduTools\Media\Border\Ferous11.tga]])
-- LSM:Register(MediaType_BORDER, "Ferous 12", [[Interface\AddOns\!WilduTools\Media\Border\Ferous12.tga]])
LSM:Register(MediaType_BORDER, "Ferous 13", [[Interface\AddOns\!WilduTools\Media\Border\Ferous13.tga]])
LSM:Register(MediaType_BORDER, "Raeli Glow", [[Interface\AddOns\!WilduTools\Media\Border\RaeliGlow.tga]])
LSM:Register(MediaType_BORDER, "Raeli Glow Small", [[Interface\AddOns\!WilduTools\Media\Border\RaeliGlowSmall.tga]])

-- ----------
-- FONT (107)
-- ----------
LSM:Register(MediaType_FONT, "FiraCode Regular", [[Interface\AddOns\!WilduTools\Media\Fonts\FiraCode-Regular.ttf]])
LSM:Register(MediaType_FONT, "FiraCode Semi", [[Interface\AddOns\!WilduTools\Media\Fonts\FiraCode-SemiBold.ttf]])
LSM:Register(MediaType_FONT, "FiraCode Bold", [[Interface\AddOns\!WilduTools\Media\Fonts\FiraCode-Bold.ttf]])
LSM:Register(MediaType_FONT, "Wildu", [[Interface\AddOns\!WilduTools\Media\Fonts\Wildu.ttf]])


-- --------------
-- STATUSBAR (120)
-- --------------
LSM:Register(MediaType_STATUSBAR, "Melli Dark", [[Interface\AddOns\!WilduTools\Media\Statusbar\MelliDark]])
LSM:Register(MediaType_STATUSBAR, "Melli", [[Interface\AddOns\!WilduTools\Media\Statusbar\Melli]])
LSM:Register(MediaType_STATUSBAR, "ToxiUI Clean", [[Interface\AddOns\!WilduTools\Media\Statusbar\ToxiUI-clean]])
LSM:Register(MediaType_STATUSBAR, "ToxiUI Dark", [[Interface\AddOns\!WilduTools\Media\Statusbar\ToxiUI-dark]])
LSM:Register(MediaType_STATUSBAR, "ToxiUI Half", [[Interface\AddOns\!WilduTools\Media\Statusbar\ToxiUI-half]])
LSM:Register(MediaType_STATUSBAR, "ToxiUI Tx Left", [[Interface\AddOns\!WilduTools\Media\Statusbar\ToxiUI-g1]])
LSM:Register(MediaType_STATUSBAR, "ToxiUI Tx Mid", [[Interface\AddOns\!WilduTools\Media\Statusbar\ToxiUI-grad]])
LSM:Register(MediaType_STATUSBAR, "ToxiUI Tx Right", [[Interface\AddOns\!WilduTools\Media\Statusbar\ToxiUI-g2]])

-- -----------
-- SOUNDS (24)
-- -----------
LSM:Register(MediaType_SOUND, "|cff00ff98Incoming|r", [[Interface\AddOns\!WilduTools\Media\Sound\Incoming.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Run|r", [[Interface\AddOns\!WilduTools\Media\Sound\Run.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Forward|r", [[Interface\AddOns\!WilduTools\Media\Sound\Forward.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Now|r", [[Interface\AddOns\!WilduTools\Media\Sound\Now.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Sides|r", [[Interface\AddOns\!WilduTools\Media\Sound\Sides.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Go To Mark|r", [[Interface\AddOns\!WilduTools\Media\Sound\Go To Mark.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Position|r", [[Interface\AddOns\!WilduTools\Media\Sound\Position.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Targeted By Private Aura|r", [[Interface\AddOns\!WilduTools\Media\Sound\Targeted By Private Aura.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Go To Position|r", [[Interface\AddOns\!WilduTools\Media\Sound\Go To Position.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Private Aura|r", [[Interface\AddOns\!WilduTools\Media\Sound\Private Aura.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Watch Out|r", [[Interface\AddOns\!WilduTools\Media\Sound\Watch Out.ogg]])

LSM:Register(MediaType_SOUND, "|cff00ff98Beep|r", [[Interface\AddOns\!WilduTools\Media\Sound\Beep_TR.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Beep Detector|r", [[Interface\AddOns\!WilduTools\Media\Sound\Beep Detector.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Beep one|r", [[Interface\AddOns\!WilduTools\Media\Sound\Beep one.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Beep two|r", [[Interface\AddOns\!WilduTools\Media\Sound\Beep two.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Beep three|r", [[Interface\AddOns\!WilduTools\Media\Sound\Beep three.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Beep stop|r", [[Interface\AddOns\!WilduTools\Media\Sound\Beep stop.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Beep low|r", [[Interface\AddOns\!WilduTools\Media\Sound\Beep low.ogg]])
LSM:Register(MediaType_SOUND, "|cff00ff98Beep high|r", [[Interface\AddOns\!WilduTools\Media\Sound\Beep high.ogg]])