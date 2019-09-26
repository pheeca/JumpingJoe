-- =============================================================
-- Copyright Roaming Gamer, LLC. 2008-2018 (All Rights Reserved)
-- =============================================================
local common = {}

-- =============================================================
-- Game Title
-- =============================================================
common.gameTitle = "Jumping Joe!"

-- =============================================================
-- Select an art theme for the game.
-- =============================================================
--common.theme = "ansimuz" -- casual flat medieval prototype ansimuz kenney
common.theme = "jumper" -- casual flat medieval prototype ansimuz kenney jumper

common.textFill1 = _W_
common.textFill2 = _W_
if( common.theme == "kenney" or common.theme == "jumper" ) then
	common.textFill1 = hexcolor("#f0721e")
	common.textFill2 = hexcolor("#73ad19")

elseif(common.theme == "ansimuz" ) then
	common.textFill1 = hexcolor("#f0721e")
	common.textFill2 = hexcolor("#4a847c")	
end

-- On an iPhoneX or another device with a notch at the top? Adjust for that.
local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()
common.titleOffsetY 	= topInset or 0
common.cornerOffsetX = _G.oniPhoneX and 20 or 0
common.cornerOffsetY = _G.oniPhoneX and 20 or 0


-- =============================================================
-- Extras Settings 
-- =============================================================
local extras = {}
common.extras = extras

--
-- Achievements & Leaderboards
--
common.extras.achievements_enabled 					= false 
common.extras.leaderboard_enabled 					= false

--
-- Ads
--
common.extras.ads_enabled 								= false --false 
common.extras.ads_show_interstitials				= false
-- 
common.extras.ads_provider 							= "appodeal" -- applovin or appodeal
common.extras.ads_interstitial_frequency			= 5 
common.extras.ads_request_gdpr_permission			= false

--
-- Facebook
--
common.extras.facebook_enabled 						= false 

--
-- IAP
--
common.extras.iap_enabled 								= false
-- 
common.extras.iap_test_mode							= true
common.extras.iap_do_not_load_inventory			= false

--
-- Rating
--
common.extras.rating_enabled 							= false 

--
-- Sharing
--
common.extras.sharing_enabled 						= false 

--
-- Shop ('iap_enabled' must be 'true' to use this feature.)
--
common.extras.shop_enabled 							= false 

--
-- Twitter 
--
common.extras.twitter_enabled 						= false 

return common
