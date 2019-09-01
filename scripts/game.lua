-- =============================================================
-- Copyright Roaming Gamer, LLC. 2008-2018 (All Rights Reserved)
-- =============================================================
-- game.lua - Game Module
-- =============================================================
local common   = require "scripts.common"
local composer = require "composer"

-- =============================================================
-- Localizations
-- =============================================================
-- Commonly used Lua Functions
local getTimer          = system.getTimer
local mRand             = math.random
local mAbs              = math.abs
local mFloor            = math.floor
local mCeil             = math.ceil
local strGSub           = string.gsub
local strSub            = string.sub
local strMatch          = string.match
--
-- Common SSK Display Object Builders
local newCircle = ssk.display.newCircle;local newRect = ssk.display.newRect
local newImageRect = ssk.display.newImageRect;local newSprite = ssk.display.newSprite
local quickLayers = ssk.display.quickLayers
--
-- Common SSK Helper Modules
local easyIFC = ssk.easyIFC;local persist = ssk.persist
--
-- Common SSK Helper Functions
local isValid = display.isValid;local isInBounds = ssk.easyIFC.isInBounds
local normRot = math.normRot;local easyAlert = ssk.misc.easyAlert
--
-- SSK 2D Math Library
local addVec = ssk.math2d.add;local subVec = ssk.math2d.sub;local diffVec = ssk.math2d.diff
local lenVec = ssk.math2d.length;local len2Vec = ssk.math2d.length2;
local normVec = ssk.math2d.normalize;local vector2Angle = ssk.math2d.vector2Angle
local angle2Vector = ssk.math2d.angle2Vector;local scaleVec = ssk.math2d.scale

local RGTiled = ssk.tiled; local files = ssk.files
local factoryMgr = ssk.factoryMgr; local soundMgr = ssk.soundMgr
local newText = display.newText

--if( ssk.misc.countLocals ) then ssk.misc.countLocals(1) end

-- =============================================================
-- Locals
-- =============================================================
local layers
--
local scale          = fullw/1140

--
-- These variables control the sizing of the platforms. 
-- If you change them, you may need to adjust your art.
local platW          = 240
local platH          = 60

-- This variable controls player jump height/dist + placement of the platforms.
local jumpDist       = 200

-- These variables are used to track the platform position values.
local curY           = bottom - jumpDist * 2
local x0             = left + platW/2 
local x1             = right - platW/2

-- Initial lava movement rate and min/maximum movement rate
local minLavaRate    = 0.2
local maxLavaRate    = 5.3
local lavaRate       = minLavaRate

-- Lava rate increase: Every jump lavaRate becomes -> lavaRate * lavaMult
-- i.e. The more you jump the faster it goes, till hit hits max rate.
local lavaMult       = 1.1

-- This flag gates logic, making it wait till the player begins to jump.
local startedJumping = false

-- Score / Jump Count
local jumpCount      = 0

-- Jump Factor and Mult control jump times, but slowly increasing the speed
-- of jumps.
-- Jump Factor decreas
local minJumpFactor   = 0.2
local maxJumpFactor   = 1
local jumpFactor      = maxJumpFactor
local jumpFactorMult  = 0.98

-- Image sheet used for player.
local options = { width = 128, height = 128, numFrames = 2,
    sheetContentWidth = 256, sheetContentHeight = 128 }
local playerSheet = graphics.newImageSheet( "images/" .. common.theme .. "/player.png", options )


-- =============================================================
-- Forward Declarations
-- =============================================================
-- none

-- =============================================================
-- Module Begins
-- =============================================================
local game = {}

-- ==
--    create() - Create game content and start game running.
-- ==
function game.create( group, params )
   group = group or display.currentStage
	params = params or {}
   
   -- Always calls destroy to ensure the game is in 'clean' state
   game.destroy() 
   
   -- Set up rendering layers to keep things nicely organized.
   -- Uses world sub-grouping concept to make 'camera' code simple. 
   layers = ssk.display.quickLayers( group, 
      "underlay", 
      "world", 
         { "content", "lava", "player"  },
      "interfaces" )
   

   -- Create the background and lava pool
   local scale = fullw/1280
   --local back = newRect( layers.underlay, centerX, centerY, { size = 10000, fill = hexcolor("#002a3e") } )   
   local back = newImageRect( layers.underlay, centerX, centerY, "images/" .. common.theme .. "/background.png",
                             { w = 720, h = 1386 } )   
   local ground = newImageRect( layers.content, centerX, bottom - jumpDist, "images/" .. common.theme .. "/ground.png",
                                 { w = 1280 * scale, h = 255 * scale, anchorY = 0 } )
   local lava = newImageRect( layers.lava, centerX, bottom - jumpDist/2, "images/" .. common.theme .. "/lava.png",
                                 { w = 1280 * scale, h = 600 * scale, anchorY = 0, 
                                   fill = _O_ } )


   -- Create the player   
   local player = newImageRect( layers.player, left+platW/2, bottom - jumpDist - 30, "images/fillW.png",
                                { size = 60, side = 0 } )
   player.fill = { type = "image", sheet = playerSheet, frame = 2 }
   player.jumping = false

   -- Create our 'score' label
   local jumpLabel = easyIFC:quickLabel( layers.interfaces, jumpCount, centerX, top + 120, _G.fontB, 60, common.textFill1 )

   -- Define a local function for creating platforms
   -- We could move this outside of the create() function, but because this is a small game
   -- and the mechanics are simple, this is the easiest way to do it.
   -- This function ra
   local plats = {}
   local function addPlatform( anchor )
      if( not common.gameIsRunning ) then return end
      anchor = anchor or 1
      anchor = anchor - 1
      local x = (anchor == 0) and left or right

      local plat = newRect( layers.content, x, curY, 
                           { w = platW, h = platH, anchorX = anchor, anchorY = 0 } )

      -- Use a fill trick to make platforms more interesting using the same texture
      display.setDefault( "textureWrapX", "repeat" )
      plat.fill = { type = "image", filename = "images/" .. common.theme .. "/plat.png" }
      local fillX = {0,0.25,0.5,0.75}
      plat.fill.x = fillX[mRand(1,4)]
      display.setDefault( "textureWrapX", "clampToEdge" )
      plat.side = anchor

      plats[plat] = plat
      curY = curY - jumpDist
   end


   -- Add an 'onComplete' listener to the player that is called at the end of a jump transition.
   -- It does the following for us:
   --
   -- 1 Sets the 'starteJumping' flag to true.  Once this is true, the lava starts to move upward.
   -- 2 Updates the player image fill to reflect the landing orientation we want
   -- 3 Increases the lava movement rate and decrease the jump factor (speed up jumps).
   -- 4 Destroys all platforms that are too far below the player.
   -- 5 Checks for a failed jump and kills the player, otherwise:
   -- 6 Updates the 'score' label (jump count)
   --
   function player.onComplete( self )
      self.jumping = false
      player.rotation = 0

      -- 1
      startedJumping = true

      -- 2
      self.fill = { type = "image", sheet = playerSheet, frame = 2 }
      self.xScale = (self.anchorX == 0) and 1 or -1

      -- 3
      lavaRate = lavaRate * lavaMult      
      lavaRate = (lavaRate > maxLavaRate) and maxLavaRate or lavaRate
      --
      jumpFactor = jumpFactor * jumpFactorMult
      jumpFactor = (jumpFactor > minJumpFactor) and jumpFactor or minJumpFactor

      -- 4
      for k,v in pairs(plats) do
         if( mAbs(v.y - player.y) > 2 * fullh ) then 
            display.remove(v)
            plats[k] = nil
         end
      end
      --print( "#plats ", table.count( plats ) )

      -- 5
      local onPlat = false
      for k,v in pairs(plats) do
         local dy = mAbs(player.y - v.y)
         if( player.side == v.side and dy <= 40 ) then
            onPlat = true
         end
      end
      
      if( onPlat ) then 
         -- 6
         jumpCount = jumpCount + 1
         jumpLabel.text = jumpCount
      else      
         self:die()
      end
   end

   -- Set up an 'enterFrame' listener that does the following for us:
   --
   -- 1 Forces the lava not to fall too far behind the player.  This is more of an issue
   --   in the beginning when the lava is slow.
   -- 2 Updates the position of they lava (raises it).
   -- 3 Kills the player if the lava hits his feet or higher.
   --
   local lavaFill = { type = "image", filename = "images/" .. common.theme .. "/plat_lava.png" }
   function player.enterFrame( self )
      if( not common.gameIsRunning ) then return end
      if( not startedJumping ) then return end
      
      local dy = lava.y - player.y
      lava.y = lava.y - lavaRate

      -- 1
      if( self.jumping == false and dy > jumpDist * 1.1 ) then 
         lava.y = player.y + jumpDist * 1.1
      end

      -- 2
      --print( "Lava: dy ", dy )    
      for k,v in pairs(plats) do          
         if( lava.y - v.y < 80 ) then
            display.setDefault( "textureWrapX", "repeat" )
            v.fill = lavaFill
            display.setDefault( "textureWrapX", "clampToEdge" )
            v.lava = true
         end
      end

      -- 3
      if( dy <= 30 ) then
         self:die()
         post( "onSound", { sound = "gameOver" })
      end
   end; listen("enterFrame", player)

   -- This is a helper method we created to allow us to kill the player in different circumstances:
   -- >> Missed platform.
   -- >> Lava too high
   --
   -- It does the following for us:
   --
   -- 1 Marks player object as 'isDead'.  We use this to prevent some logic from executing once the player is 'dead'.
   -- 2 Marks the game as not running. Another gate. 
   --   (We could probably collapse these gates into just one variable, but this is OK too.)
   -- 3 Do the 'death fall' animation using a transition
   -- 4 Stop listening for all Runtime events we set up previously.
   -- 5 Play the 'gameOver' sound.
   -- 6 Wait 1/2 second, then go back to 'home' scene and request 'best score' overlay
   --
   function player.die( self )
      if( self.isDead ) then return end
      -- 1
      self.isDead = true

      -- 2
      common.gameIsRunning = false

      -- 3
      transition.to( player, { y = player.y + jumpDist * 3, rotation = 180, time = 500, transition = easing.linear })

      -- 4
      ignoreList( { "enterFrame", "onTwoTouchLeft", "onTwoTouchRight"  }, self  )

      -- 5
      post( "onSound", { sound = "gameOver" })

      -- 6
      timer.performWithDelay( 500,
         function()
            local params = { showBestScore = true, lastScore = jumpCount }
            composer.gotoScene( "scenes.home", { time = 500, effect = "crossFade", params = params } )
         end )
   end

   -- These are player jump helper functions: jumpUp, jumpLeft, and JumpRight
   -- They handle the three possible jump types.
   --
   -- Essentially, they combine a set of overlapping transitions to make the player look like he is jumping in an arc.
   -- If you are not happy with them, you should play with the timings in these transitions (carefully) to get 
   -- the look and feel you want.  You can also adjust the easings to change the shape of the jump path.
   --
   function player.jumpUp( self )
      self.fill = { type = "image", sheet = playerSheet, frame = 1 }
      self.jumping = true
      local jumpPeak = self.y -jumpDist * 1.5
      local jumpDest = self.y -jumpDist
      --
      local time1 = mFloor(500 * jumpFactor)
      local time2 = mFloor(100 * jumpFactor)
      local time3 = time1-time2      
      --
      transition.to( self, { y = jumpPeak, time = time1, trasition = easing.linear } )
      transition.to( self, { y = jumpDest, delay = time1, time = time2, transition = easing.linear, onComplete = self } )
      transition.to( layers.world, { y = layers.world.y + jumpDist, time = time3 } )
   end
   function player.jumpLeft( self )
      self.fill = { type = "image", sheet = playerSheet, frame = 1 }
      self.xScale = -1
      self.jumping = true
      self.side = 0
      --
      local time1 = mFloor(500 * jumpFactor)
      local time2 = mFloor(100 * jumpFactor)
      local time3 = time1-time2
      local time4 = mFloor(50 * jumpFactor)
      local time5 = mFloor(300 * jumpFactor)
      local time6 = mFloor(600 * jumpFactor)
      --
      transition.to( self, { x = x0, time = time6, transition = easing.linear } )
      local jumpPeak = self.y -jumpDist * 1.5
      local jumpDest = self.y -jumpDist
      -- Kenney art should not rotate in jump
      if( common.theme ~= "kenney"  and common.theme ~= "jumper" ) then
         transition.to( self, { rotation = -360, delay = time4, time = time5 })
      end
      transition.to( self, { y = jumpPeak, time = time1, trasition = easing.inCirc } )
      transition.to( self, { y = jumpDest, delay = time1, time = time2, transition = easing.linear, onComplete = self } )
      transition.to( layers.world, { y = layers.world.y + jumpDist, time = time3 } )
   end
   function player.jumpRight( self )
      self.fill = { type = "image", sheet = playerSheet, frame = 1 }
      self.xScale = 1
      self.jumping = true
      self.side = 1
      --
      local time1 = mFloor(500 * jumpFactor)
      local time2 = mFloor(100 * jumpFactor)
      local time3 = time1-time2
      local time4 = mFloor(50 * jumpFactor)
      local time5 = mFloor(300 * jumpFactor)
      local time6 = mFloor(600 * jumpFactor)
      --
      transition.to( self, { x = x1, time = time6, transition = easing.linear } )
      local jumpPeak = self.y -jumpDist * 1.5
      local jumpDest = self.y -jumpDist
      -- Kenney art should not rotate in jump
      if( common.theme ~= "kenney" and common.theme ~= "jumper" ) then
         transition.to( self, { rotation = 360, delay = time4, time = time5 })
      end
      transition.to( self, { y = jumpPeak, time = time1, trasition = easing.inCirc } )
      transition.to( self, { y = jumpDest, delay = time1, time = time2, transition = easing.linear, onComplete = self } )
      transition.to( layers.world, { y = layers.world.y + jumpDist, time = time3 } )
   end

   -- These two functions are helpers that listen for the custom Runtime events generated by the 'twoTouch' easyInputs
   -- helper.
   --
   -- They call the appropriate jump function from our three above.
   --
   function player.onTwoTouchLeft( self, event )
      if( player.jumping ) then return end
      post( "onSound", { sound = "jump" })
      addPlatform( mRand(1,2) )      
      if( self.side == 0 ) then
         self:jumpUp()
      else
         self:jumpLeft()
      end
   end; listen( "onTwoTouchLeft", player )
   function player.onTwoTouchRight( self, event )
      if( player.jumping ) then return end
      post( "onSound", { sound = "jump" })
      addPlatform( mRand(1,2) )
      if( self.side == 0 ) then
         self:jumpRight()
      else
         self:jumpUp()
      end
   end; listen( "onTwoTouchRight", player )

   -- This is a fail-safe helper to make sure that all Runtime listers are removed from
   -- the player object when it is destroyed.  They should be gone already, but we are
   -- just being safe.
   function player.finalize( self )
      ignoreList( { "enterFrame", "onTwoTouchLeft", "onTwoTouchRight"  }, self  )
   end; player:addEventListener("finalize")


   -- Create Easy Inputs - Two-touch helper object
   -- Setting 'keyboardEn' allow you to test in the simulator with the a/d or left/right buttons.
   ssk.easyInputs.twoTouch.create(layers.underlay, { debugEn = false, keyboardEn = true } )


   -- Mark game as 'running' so when we call the 'addPlatform' function in a moment it
   -- will produce platforms.
   common.gameIsRunning = true

   -- Create an initial set of platforms (enough to fill worst-case/iPhoneX height)
   addPlatform( mRand(1,2), true )
   addPlatform( mRand(1,2) )
   addPlatform( mRand(1,2) )
   addPlatform( mRand(1,2) )
   addPlatform( mRand(1,2) )
   addPlatform( mRand(1,2) )
   addPlatform( mRand(1,2) )
   addPlatform( mRand(1,2) )
end

-- ==
--    destroy() - Remove all game content and set local variables to defaults.
-- ==
function game.destroy()
   common.gameIsRunning    = false
   --
   display.remove( layers )
   layers = nil
   --
   curY           = bottom - jumpDist * 2
   lavaRate       = minLavaRate
   jumpFactor     = maxJumpFactor
   startedJumping = false
   jumpCount      = 0
end

return game