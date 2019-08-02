--[[---------------------------------------------------------------------

  Animation Quantizer 1.0 for Aseprite (https://aseprite.org)
  Project page: https://github.org/BoThompson/animationquantizer.git)
   
    by Bo Thompson ( @AimlessZealot / @Joybane )
    Twitter: http://twitter.com/aimlesszealot
    Dribbble: http://twitch.com/joybane

  Copyright (c) 2019 Bo Thompson

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

  Purpose:
    Quantizes a range of animation frames, standardizing their duration while
	attempting to alter the visuals of the animation as little as possible.
  
  Requirements:
    + Aseprite 1.2.13 or newer
  
  Installation:
    + Open Aseprite
    + Go to `File → Scripts → Open Scripts Folder`
    + Place downloaded LUA script into opened directory
    + Restart Aseprite
  
  Usage:
    + Go to `File → Scripts → Animation Quantizer` to run the script
    + You can also setup a custom hotkey under `Edit → Keyboard Shortcuts`
    
-----------------------------------------------------------------------]]


local sprite = app.activeSprite

--The money maker -- Quantizes the range of frames based upon dialog settings
function quantize()
	
	local data = dlg.data
	local quantizedDuration = 1
	local maxFrames = #sprite.frames
	local i = 1
	local startFrameNum = tonumber(data.from)
	local endFrameNum = tonumber(data.to)
	
	--Sanity checks for frame length and quantized duration
	if(#sprite.frames < startFrameNum) then
		app.alert("ERROR: Starting frame is invalid.")
		return
	end
	if(#sprite.frames < endFrameNum) then
		app.alert("ERROR: Ending frame is invalid.")
	end
	if(endFrameNum < startFrameNum) then
		app.alert("ERROR: Frame range is invalid.")
		return
	else
		nextFrame = sprite.frames[data.from]
	end
	if(tonumber(data.mspf) == nil or data.mspf / 1000 <= 0) then
		app.alert("ERROR: Milliseconds per Frame is invalid.")
		return
	else
		quantizedDuration = data.mspf / 1000
	end
	
	local currentFrame = sprite.frames[startFrameNum]
	local nextFrame = sprite.frames[startFrameNum]
	local n = 1
	while(n <= maxFrames) do
		if(nextFrame == nil) then
			break
		end
		currentFrame = nextFrame
		if(i <= #sprite.frames) then
			nextFrame = sprite.frames[i]
		else
			nextFrame = nil
		end
		if(currentFrame.duration < quantizedDuration) then --Shorter frames are omitted or lengthened
			if(data.adjust == "Omission" or (data.adjust == "Rounding" and currentFrame.duration / quantizedDuration < 0.5)) then
				if(nextFrame) then
					nextFrame.duration = nextFrame.duration + currentFrame.duration
				--Add current frame length to next frame length
				end
				--Delete current frame
				sprite:deleteFrame(currentFrame)
			else
				--Set current frame length to Q-length
				currentFrame.duration = quantizedDuration
			end
			i = i + 1
		elseif(currentFrame.duration > quantizedDuration) then --Longer frames are chopped up
			local quantLength = currentFrame.duration / quantizedDuration
			--Round the number of frames
			if(data.adjust == "Omission" or (data.adjust == "Rounding" and quantLength % 1 < 0.5)) then
				quantLength = math.floor(quantLength)
			else
				quantLength = math.ceil(quantLength)
			end
			while(quantLength > 0) do
				-- -Insert copy of frame before current frame at quantizedDuration
				newFrame = sprite:newFrame(currentFrame)
				currentFrame = sprite.frames[i]
				newFrame.duration = quantizedDuration
				quantLength = quantLength - 1
				i=i+1
			end
			sprite:deleteFrame(i)
			
		else --Matching frames are skipped
			i = i + 1
		end
		if(#sprite.frames >= i) then
				nextFrame = sprite.frames[i]
			else
				nextFrame = nil
		end
		n = n + 1
	end
end

--Transacts the quantization
function quantizeOperation()
	app.transaction(quantize)
end


--The dialog settings
dlg = Dialog("Animation Quantizer")
dlg:separator{ text="Frames:" }
dlg:number{id="from", text="1", label="From",decimals=0}
dlg:number{id="to", text=tostring(#sprite.frames), label="To",decimals=0}
dlg:separator{ text="Settings:" }
dlg:number{id="mspf", label="Milliseconds per Frame",decimals=0}
dlg:combobox{id="adjust", label="Adjust short frames by ", option="Omission", options={"Omission", "Extension", "Rounding"}}
dlg:newrow{}
dlg:button{ id="quantize", text="Quantize", focus=true,
            onclick=quantizeOperation }
dlg:show{}

