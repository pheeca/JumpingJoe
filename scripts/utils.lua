-- =============================================================
-- Copyright Roaming Gamer, LLC. 2008-2018 (All Rights Reserved)
-- =============================================================
local common = require "scripts.common"

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
-- Module Begins
-- =============================================================
local utils = {}

-- ==
-- (Re-) Position Buttons
-- If useTransitions is 'true', then move buttons with transition.* lib.
--
utils.positionButtons = function( buttons, tween, params )
	if( not buttons or #buttons == 0 ) then return end
	--
   local buttonW  = buttons[1].contentWidth
   if( not tween ) then
      local totalBW = #buttons * buttonW
      tween = math.floor( (fullw - totalBW )/(#buttons+1) )
   end
   
   local curX     = centerX - ((#buttons * buttonW) + ((#buttons-1) * tween))/2 + buttonW/2
   for i = 1, #buttons do
      local button = buttons[i]
      if( params ) then
         local function onComplete()
            button:resetStartPosition()
         end
         params.time       = params.time or 500
         params.transition   = params.transition or easing.outBack
         params.x          = curX
         params.onComplete = onComplete
         transition.to( button, params )
      else
         button.x = curX
         button:resetStartPosition()
      end
      curX = curX + buttonW + tween
   end
end

return utils
