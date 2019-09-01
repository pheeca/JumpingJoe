-- =============================================================
-- Copyright Roaming Gamer, LLC. 2008-2018 (All Rights Reserved)
-- =============================================================
-- =============================================================
local composer    = require "composer"
local scene       = composer.newScene()
local common      = require "scripts.common"
local utils       = require "scripts.utils"

-- =============================================================
-- Localizations
-- =============================================================
-- Commonly used Lua & Corona Functions
local getTimer = system.getTimer; local mRand = math.random
local mAbs = math.abs; local mFloor = math.floor; local mCeil = math.ceil
local strGSub = string.gsub; local strSub = string.sub
-- Common SSK Features
local newCircle = ssk.display.newCircle;local newRect = ssk.display.newRect
local newImageRect = ssk.display.newImageRect;local newSprite = ssk.display.newSprite
local quickLayers = ssk.display.quickLayers
local easyIFC = ssk.easyIFC;local persist = ssk.persist
local isValid = display.isValid;local isInBounds = ssk.easyIFC.isInBounds
local normRot = math.normRot;local easyAlert = ssk.misc.easyAlert
-- SSK 2D Math Library
local addVec = ssk.math2d.add;local subVec = ssk.math2d.sub;local diffVec = ssk.math2d.diff
local lenVec = ssk.math2d.length;local len2Vec = ssk.math2d.length2;
local normVec = ssk.math2d.normalize;local vector2Angle = ssk.math2d.vector2Angle
local angle2Vector = ssk.math2d.angle2Vector;local scaleVec = ssk.math2d.scale
local RGTiled = ssk.tiled; local files = ssk.files
local factoryMgr = ssk.factoryMgr; local soundMgr = ssk.soundMgr
-- =============================================================

----------------------------------------------------------------------
-- Forward Declarations
----------------------------------------------------------------------
local onSound
local onShare
local onFacebook
local onTwitter
local onRate
local onNoAds
local onPlay
local onAbout
local onAchievements
local onLeaderboard
local onShop

----------------------------------------------------------------------
-- Locals
----------------------------------------------------------------------
local content
local buttons
local diedCount = 0 
if( ssk.misc.countLocals ) then ssk.misc.countLocals(1) end

----------------------------------------------------------------------
-- Scene Methods
----------------------------------------------------------------------
function scene:create( event )
   local sceneGroup = self.view   
end

function scene:willShow( event )
   local sceneGroup = self.view
   --
   content = display.newGroup()
   sceneGroup:insert(content)
   --
   -- Draw background, title, etc.
   local back = newImageRect( content, centerX, centerY, 
                              "images/" .. common.theme .."/background.png",
                              { w = 720, h = 1386, rotation = (fullw>fullh) and 90 or 0 } )

   local title  =  easyIFC:quickLabel( content, common.gameTitle, centerX, centerY - fullh/4, _G.fontB, 50, common.textFill1 )

   local soundButton = easyIFC:presetToggle( content, "sound", 
                                             right - common.cornerOffsetX - 50, 
                                             top + common.cornerOffsetY + 50, 
                                             80, 80, "", onSound )

   local aboutButton = easyIFC:presetPush( content, "about", 
                                           left + common.cornerOffsetX + 50, 
                                           top + common.cornerOffsetY + 50, 
                                           80, 80, "", onAbout )
  

   if( persist.get( "settings.json", "sound_enabled" ) ) then
      soundButton:toggle(true)
   end

   local playButton = easyIFC:presetPush( content, "play", centerX, centerY, 100, 100, "", onPlay )
   
   -- Draw buttons we need (may change over time)
   buttons = {}   
   if( common.extras.rating_enabled and persist.get( "settings.json", "rated") == false ) then
      buttons[#buttons+1] = easyIFC:presetPush( content, "rate", centerX, centerY + fullh/4, 80, 80, "", onRate )
   end

   if( targetiOS and common.extras.sharing_enabled ) then
      buttons[#buttons+1] = easyIFC:presetPush( content, "share", centerX, centerY + fullh/4, 80, 80, "", onShare )
   end

   if( common.extras.facebook_enabled ) then   
      buttons[#buttons+1] = easyIFC:presetPush( content, "facebook", centerX, centerY + fullh/4, 80, 80, "", onFacebook )
   end

   if( common.extras.twitter_enabled ) then
      buttons[#buttons+1] = easyIFC:presetPush( content, "twitter", centerX, centerY + fullh/4, 80, 80, "", onTwitter )
   end
   
   -- Show 'no ads' option if user did not buy it already.
   if( common.extras.iap_enabled and common.extras.ads_enabled and ssk.persist.get( "settings.json", "ads_enabled" ) ) then
      buttons[#buttons+1] = easyIFC:presetPush( content, "noads", centerX, centerY + fullh/4, 80, 80, "", onNoAds )
   end

   -- NOT USED IN THIS GAME
   if( common.extras.achievements_enabled ) then
      buttons[#buttons+1] = easyIFC:presetPush( content, "achievements", centerX, centerY + fullh/4, 80, 80, "", onAchievements )
   end

   if( common.extras.leaderboard_enabled ) then
      buttons[#buttons+1] = easyIFC:presetPush( content, "leaderboard", centerX, centerY + fullh/4, 80, 80, "", onLeaderboard )   
   end

   if( common.extras.shop_enabled ) then
      buttons[#buttons+1] = easyIFC:presetPush( content, "shop", centerX, centerY + fullh/4, 80, 80, "", onShop )
   end

   utils.positionButtons( buttons )

   -- 
   -- If the 'high score' summary was requested, show it.
   --
   local params = event.params or {}
   --table.dump(params)
   if( params.showBestScore ) then
      local lastScore = params.lastScore or 0
      local bestScore = persist.get( "settings.json", "bestScore" )
      if( lastScore > bestScore ) then
         bestScore = lastScore
         persist.set( "settings.json", "bestScore", bestScore )
      end

      local lastLabel = easyIFC:quickLabel( content, "Last Score: " .. tostring( lastScore ) , centerX, title.y + 70, _G.fontN, 36, common.textFill1 )
      local lastLabel = easyIFC:quickLabel( content, "Best Score: " .. tostring( bestScore ) , centerX, title.y + 120, _G.fontN, 36, common.textFill1 )
   end   

end

function scene:didShow( event )
   local sceneGroup = self.view
   --
   if( ssk.persist.get( "settings.json", "ads_enabled" ) == false ) then return end
   --
   local adsHelper = require( "scripts.ads." .. common.extras.ads_provider .. "Ads" )
   -- 
   -- If the 'high score' summary was requested, it means we just died,
   -- so update died count.
   local params = event.params or {}
   if( params.showBestScore ) then
      diedCount = diedCount + 1
      -- Now, check to see if we should show a banner or an interstitial ad
      --   
      if( common.extras.ads_show_interstitials and ( diedCount % common.extras.ads_interstitial_frequency == 0 ) ) then
         adsHelper.hideBanner()
         adsHelper.showInterstitial( function() adsHelper.showBanner() end )
         return
      end
   end

   adsHelper.showBanner()
end

function scene:willHide( event )
   local sceneGroup = self.view
end

function scene:didHide( event )
   local sceneGroup = self.view
   --
   display.remove(content)
   content = nil
   buttons = nil
end

function scene:destroy( event )
   local sceneGroup = self.view
end

----------------------------------------------------------------------
--          Custom Scene Functions/Methods
----------------------------------------------------------------------

-- Sound Button Listener
onSound = function( event )
   if( event.phase == "moved" ) then return false end
   local target = event.target 
   persist.set( "settings.json", "sound_enabled", target:pressed() )
   soundMgr.enableSFX( persist.get( "settings.json", "sound_enabled" ) )
   post("onSound", { sound = "click" } )
end

-- Share Button Listener
onShare = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   require( "scripts.extras.sharing").showActivityDialog()
end

-- Facebook Button Listener
onFacebook = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   require( "scripts.extras.facebook").post()
end

-- Twitter Button Listener
onTwitter = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   require( "scripts.extras.twitter").sendTweet()
end

-- Rate Button Listener
onRate = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   local function onSuccess()
      persist.set( "settings.json", "rated", true )
      if( target ) then
         table.removeByRef( buttons, target )
         table.dump(buttons)
         utils.positionButtons( buttons, nil, { time = 500, transition = easing.outBack })
         display.remove(target)
      end
   end
   --
   require( "scripts.extras.rating").rate( onSuccess )
end


-- No Ads Button Listener
onNoAds = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   local function onSuccess( itemName, event )
      --[[
      print("purchaseListener() - itemName: " .. tostring( itemName ))
      for k,v in pairs( event ) do
         print( ">> " .. tostring(k) .. " = " .. tostring(v) )
      end
      --]]
      local adsHelper = require( "scripts.ads." .. common.extras.ads_provider .. "Ads" )
      --
      if( event.state == "purchased" and itemName == "noads" ) then
         if( target ) then
            table.removeByRef( buttons, target )
            table.dump(buttons)
            utils.positionButtons( buttons, nil, { time = 500, transition = easing.outBack })
            display.remove(target)
            
            -- Set persistent ads_enabled flag to false
            ssk.persist.set( "settings.json", "ads_enabled", false )

            -- Try to hide banner (just in case it is showing now)
            adsHelper.hideBanner()
           
            -- Disable the ads module and force it to clean up any 
            -- oustanding listeners.
            adsHelper.disableModule(true)
         end
      end

      -- Try to hide banner (just in case it is showing now)
      adsHelper.hideBanner()
   end
   --
   local easyIAP = require "scripts.iap.easyIAP"
   easyIAP.buy_noads( onSuccess )
end

-- Play Button Listener
onPlay = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   local params = {}
   composer.gotoScene( "scenes.play", { time = 500, effect = "crossFade", params = params } )
end

-- About Button Listener
onAbout = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   local params = {}
   composer.gotoScene( "scenes.about", { time = 500, effect = "crossFade", params = params } )
end


-- Achievements Button Listener
onAchievements = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   --require( "scripts.extras.gaming")
   --
end

-- Leaderboard Button Listener
onLeaderboard = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   --require( "scripts.extras.achievementsLeaderboards")
   --
end

-- Shop Button Listener
onShop = function( event )
   local target = event.target
   post("onSound", { sound = "click" } )
   --
   --require( "scripts.extras.shop")
   --
end

---------------------------------------------------------------------------------
-- Custom Dispatch Parser -- DO NOT EDIT THIS
---------------------------------------------------------------------------------
function scene.commonHandler( event )
   local willDid  = event.phase
   local name     = willDid and willDid .. event.name:gsub("^%l", string.upper) or event.name
   if( scene[name] ) then scene[name](scene,event) end
end
scene:addEventListener( "create",   scene.commonHandler )
scene:addEventListener( "show",     scene.commonHandler )
scene:addEventListener( "hide",     scene.commonHandler )
scene:addEventListener( "destroy",  scene.commonHandler )
return scene
