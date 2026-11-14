-- this shows off every single thing nimbus can do
local Nimbus = loadstring(game:HttpGet("https://raw.githubusercontent.com/4er2/Nimbus/main/source.lua"))()

local Window = Nimbus:CreateWindow({
	Title = "Nimbus",
	Subtitle = "example script",
	Keybind = Enum.KeyCode.RightControl,
	Blur = true,
})

local Main = Window:AddTab("Main")
local Extra = Window:AddTab("Extra")

local Toggles = Main:AddSection("Toggles")
Toggles:AddToggle({ Name = "Basic toggle", Default = true, Flag = "Basic", Callback = function(v) print("toggle:", v) end })
Toggles:AddToggle({ Name = "With description", Description = "this one has a little line under it", Flag = "Desc" })
Toggles:AddKeybind({ Name = "Fly key", Default = Enum.KeyCode.F, Mode = "Toggle", Flag = "FlyKey", Callback = function(on) print("fly:", on) end })
Toggles:AddKeybind({ Name = "Hold key", Default = Enum.KeyCode.E, Mode = "Hold", Flag = "HoldKey" })

local Sliders = Main:AddSection("Sliders")
Sliders:AddSlider({ Name = "Walk speed", Min = 16, Max = 100, Default = 16, Flag = "Speed", Callback = function(v)
	local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = v end
end })
Sliders:AddSlider({ Name = "Field of view", Min = 30, Max = 120, Default = 70, Suffix = " deg", Flag = "FOV" })
Sliders:AddSlider({ Name = "Decimals", Min = 0, Max = 1, Default = 0.5, Increment = 0.05, Flag = "Dec" })

local Drops = Main:AddSection("Dropdowns")
Drops:AddDropdown({ Name = "Target part", Options = { "Head", "Torso", "Left Arm", "Right Arm", "Legs" }, Default = "Head", Flag = "Part" })
Drops:AddDropdown({ Name = "Show", Options = { "Players", "NPCs", "Items", "Cars" }, Multi = true, Default = { "Players", "Items" }, Flag = "Show" })
Drops:AddDropdown({ Name = "Player", Players = true, AllowNone = true, Flag = "Player" })

local Inputs = Main:AddSection("Inputs")
Inputs:AddInput({ Name = "Message", Placeholder = "type here", Flag = "Msg" })
Inputs:AddInput({ Name = "Numbers only", Numeric = true, Default = "10", Flag = "Num" })
Inputs:AddColorPicker({ Name = "ESP color", Default = Color3.fromRGB(56, 189, 248), Flag = "EspColor" })

local Buttons = Extra:AddSection("Buttons")
Buttons:AddButton("Send a notification", function()
	Nimbus:Notify({ Title = "hello", Content = "this is what notifications look like", Duration = 4 })
end)
Buttons:AddButton({ Name = "Success notification", Callback = function() Nimbus:Notify({ Title = "it worked", Content = "nice", Type = "Success" }) end })
Buttons:AddButton({ Name = "Error notification", Callback = function() Nimbus:Notify({ Title = "uh oh", Content = "something broke", Type = "Error" }) end })
Buttons:AddButton({ Name = "Dangerous button", Description = "asks you to click twice", Confirm = true, Callback = function() print("confirmed") end })

local Text = Extra:AddSection("Text")
Text:AddParagraph({ Title = "Paragraph", Content = "you can put longer text in here and it wraps onto more lines by itself." })
Text:AddDivider()
local lbl = Text:AddLabel("this is a label")
task.delay(3, function() lbl:Set("labels can change too") end)

Window:AddSettingsTab()

Nimbus:Notify({ Title = "Nimbus loaded", Content = "press RightControl to hide the menu", Duration = 5 })

-- you can read any value with Nimbus.Flags, like Nimbus.Flags.Speed
