 function init()
	saveVersion = GetInt("savegame.mod.molotovVersion")
	enableEmberFire = GetBool("savegame.mod.molotovEmberfire")
	maxMolotovCount = GetInt("savegame.mod.molotovMaxMolotovCount")
	emberCount = GetInt("savegame.mod.molotovEmberCount")
	maxWorldEmbers = GetInt("savegame.mod.molotovMaxWorldEmbers")
	silencedMolotov = GetBool("savegame.mod.molotovSilencedMolotov")
	unlimitedAmmo = GetBool("savegame.mod.molotovUnlimitedAmmo")
	breakWindows = GetBool("savegame.mod.molotovBreakGlass")
	
	if saveVersion == nil then saveVersion = 0 end
	
	if saveVersion < 3 then
		saveVersion = 3
		SetInt("savegame.mod.molotovVersion", 3)
		
		enableEmberFire = true
		SetBool("savegame.mod.molotovEmberfire", enableEmberFire)
		
		maxMolotovCount = 100
		SetInt("savegame.mod.molotovMaxMolotovCount", maxMolotovCount)
		
		emberCount = 15
		SetInt("savegame.mod.molotovEmberCount", emberCount)
		
		maxWorldEmbers = 100
		SetInt("savegame.mod.molotovMaxWorldEmbers", maxWorldEmbers)
	end
	
	if saveVersion < 4 then
		saveVersion = 4
		SetInt("savegame.mod.molotovVersion", 4)
		
		silencedMolotov = false
		SetBool("savegame.mod.molotovSilencedMolotov", silencedMolotov)
	end
	
	if saveVersion < 5 then
		saveVersion = 5
		SetInt("savegame.mod.molotovVersion", 5)
		DebugPrint("The molotov now has new sounds!")
		DebugPrint("If you wish to continue using silenced molotov, you can reenable it in the settings.")
		DebugPrint("This reset only happens once. This message will not appear again.")
		DebugPrint("And will go away when you enter the game or something uses the debug console.")
		
		silencedMolotov = false
		SetBool("savegame.mod.molotovSilencedMolotov", silencedMolotov)
	end
	
	if saveVersion < 6 then
		saveVersion = 6
		SetInt("savegame.mod.molotovVersion", 6)
		
		unlimitedAmmo = false
		SetBool("savegame.mod.molotovUnlimitedAmmo", unlimitedAmmo)
	end
	
	if saveVersion < 7 then
		breakWindows = true
		SetBool("savegame.mod.molotovBreakGlass", breakWindows)
	end
end

textboxClass = {
	inputNumbers = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"},
	inputLetters = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" },
	default = {
		name = "TextBox",
		value = "",
		width = 100,
		height = 40,
		limitsActive = false,
		numberMin = 0,
		numberMax = 1,
		inputActive = false,
		lastInputActive = false,
		
		render = (function(me)
		UiPop()
		
		UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
		UiTranslate(-me.width - #me.name * 2.7, 0)
		UiText(me.name .. ":")
		UiTranslate(me.width + #me.name * 2.7, 0)
		
		if me.checkMouseInRect(me) and not me.inputActive then
			UiColor(1,1,0)
		elseif me.inputActive then
			UiColor(0,1,0)
		else
			UiColor(1,1,1)
		end
		
		local tempVal = me.value
		
		if tempVal == "" then
			tempVal = " "
		end
		
		if UiTextButton(tempVal, me.width, me.height) then
			me.inputActive = not me.inputActive
		end
		
		UiColor(1,1,1)
		
		UiPush()
		end),
		
		checkMouseInRect = (function(me)
			return UiIsMouseInRect(me.width, me.height)
		end),
		
		setActiveState = (function(me, newState)
			me.inputActive = newState
			if not me.inputActive then
				if me.numbersOnly then
					if me.value == "" then
						me.value = me.numberMin .. ""
					end
					
					if me.limitsActive then
						local tempVal = tonumber(me.value)
						if tempVal < me.numberMin then
							me.value = me.numberMin .. ""
						elseif tempVal > me.numberMax then
							me.value = me.numberMax .. ""
						end
					end
				end
			end
		end),
		
		inputTick = (function(me)
			if me.inputActive ~= me.lastInputActive then
				me.lastInputActive = me.inputActive
			end
		
			if me.inputActive then
				if InputPressed("lmb") then
					me.setActiveState(me, me.checkMouseInRect(me))
				elseif InputPressed("return") then
					me.setActiveState(me, false)
				elseif InputPressed("backspace") then
					me.value = me.value:sub(1, #me.value - 1)
				else
					for j = 1, #textboxClass.inputNumbers do
						if InputPressed(textboxClass.inputNumbers[j]) then
							me.value = me.value .. textboxClass.inputNumbers[j]
						end
					end
					if not me.numbersOnly then
						for j = 1, #textboxClass.inputLetters do
							if InputPressed(textboxClass.inputLetters[j]) then
								me.value = me.value .. textboxClass.inputLetters[j]
							end
						end
					end
				end
			end
		end),
	},
	textboxes = {
	
	},
}

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function draw()
	UiPush()
	
		local textBox01, newBox01 = getTextBox(1) -- Max Active Molotov
		local textBox02, newBox02 = getTextBox(2) -- Ember Per molotov
		local textBox03, newBox03 = getTextBox(3) -- Max Active Embers
		--[[local mX, mY = UiGetMousePos()
		UiButtonImageBox("ui/common/box-solid-6.png", 6, 6)
		UiTranslate(mX, mY)
		UiRect(10, 10)
		UiTranslate(-mX, -mY)]]--

		UiWordWrap(400)
		
		UiTranslate(UiCenter(), 50)
		UiAlign("center middle")
		
		UiFont("bold.ttf", 48)
		UiTranslate(0, 50)
		UiText("Molotov Cocktail")
		
		UiFont("regular.ttf", 26)
		
		UiTranslate(0, 50)
		
		UiText("To backspace an input box press Backspace. (New!)")
		
		UiPush()
		
			UiTranslate(400, UiHeight() - 300)
			
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
			
			if UiTextButton("Reset to default", 200, 50) then
				textBox01.value = 100 .. ""
				textBox02.value = 100 .. ""
				textBox03.value = 15 .. ""
				enableEmberFire = true
				silencedMolotov = false
				unlimitedAmmo = false
				breakWindows = true
			end
			
			UiTranslate(0, 60)
			
			if UiTextButton("Save and exit", 200, 50) then
				SetInt("savegame.mod.molotovMaxMolotovCount", tonumber(textBox01.value))
				SetInt("savegame.mod.molotovMaxWorldEmbers", tonumber(textBox02.value))
				SetInt("savegame.mod.molotovEmbercount", tonumber(textBox03.value))
				SetBool("savegame.mod.molotovEmberfire", enableEmberFire)
				SetBool("savegame.mod.molotovSilencedMolotov", silencedMolotov)
				SetBool("savegame.mod.molotovUnlimitedAmmo", unlimitedAmmo)
				SetBool("savegame.mod.molotovBreakGlass", breakWindows)
				Menu()
			end
			
			UiTranslate(0, 60)
			
			if UiTextButton("Cancel", 200, 50) then
				Menu()
			end
		
		UiPop()
		
		UiTranslate(0, 50)
		
		UiPush()
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
			
			local statusText = "Disabled"
			
			if enableEmberFire then
				statusText = "Enabled"
			end
			
			if UiTextButton("Toggle ember fire: " .. statusText , 400, 40) then
				enableEmberFire = not enableEmberFire
			end
			
			UiTranslate(0, 70)
			
			UiText("Enabling this option will make the random embers that fly from an molotov start fires upon touching a wood surface.")
		UiPop()
		
		UiTranslate(0, 150)
		
		UiPush()
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
			
			local statusText = "Disabled"
			
			if unlimitedAmmo then
				statusText = "Enabled"
			end
			
			if UiTextButton("Toggle unlimtied ammo: " .. statusText , 400, 40) then
				unlimitedAmmo = not unlimitedAmmo
			end
			
			UiTranslate(0, 40)
			
			UiText("For when you need atleast 16 molotovs.")
		UiPop()
		
		UiTranslate(0, 100)
		
		UiPush()
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
			
			local statusText = "Disabled"
			
			if silencedMolotov then
				statusText = "Enabled"
			end
			
			if UiTextButton("Toggle silenced molotov: " .. statusText , 400, 40) then
				silencedMolotov = not silencedMolotov
			end
			
			UiTranslate(0, 40)
			
			UiText("For the sneaky arsonists.")
		UiPop()
		
		UiTranslate(0, 100)
		
		UiPush()
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
			
			local statusText = "Disabled"
			
			if breakWindows then
				statusText = "Enabled"
			end
			
			if UiTextButton("Toggle break windows: " .. statusText , 400, 40) then
				breakWindows = not breakWindows
			end
			
			UiTranslate(0, 40)
			
			UiText("Break windows when coming into contact.")
		UiPop()
		
		UiTranslate(0, 100)
		
		UiPush()
			if newBox01 then
				textBox01.name = "Max Active Molotovs"
				textBox01.value = maxMolotovCount .. ""
				textBox01.numbersOnly = true
				textBox01.limitsActive = true
				textBox01.numberMin = 1
				textBox01.numberMax = 1000
			end
			
			textBox01.render(textBox01)
			
			UiTranslate(0, 50)
			
			UiText("How many molotovs active at a time?")
		UiPop()
		
		UiTranslate(0, 100)
		
		UiPush()
			
			if newBox02 then
				textBox02.name = "Max Active Embers"
				textBox02.value = maxWorldEmbers .. ""
				textBox02.numbersOnly = true
				textBox02.limitsActive = true
				textBox02.numberMin = 0
				textBox02.numberMax = 1000
			end
			
			textBox02.render(textBox02)
			
			UiTranslate(0, 50)
			
			UiText("How many embers active at a time?")
		UiPop()
		
		UiTranslate(0, 100)
		
		UiPush()
			
			
			if newBox03 then
				textBox03.name = "Embers"
				textBox03.value = emberCount .. ""
				textBox03.numbersOnly = true
				textBox03.limitsActive = true
				textBox03.numberMin = 0
				textBox03.numberMax = 1000
			end
			
			textBox03.render(textBox03)
			
			UiTranslate(0, 50)
			
			UiText("How many embers will fly from a molotov explosion?")
		UiPop()
		
		
	UiPop()
end

function tick()
	for i = 1, #textboxClass.textboxes do
		local textBox = textboxClass.textboxes[i]
		textBox.inputTick(textBox)
	end
end

function getTextBox(id)
	if id <= -1 then
		id = #textboxes + 1
	end
	local textBox = textboxClass.textboxes[id]
	local newBox = false
	
	if textBox == nil then
		textboxClass.textboxes[id] = deepcopy(textboxClass.default)
		textBox = textboxClass.textboxes[id]
		newBox = true
	end
	
	return textBox, newBox
end