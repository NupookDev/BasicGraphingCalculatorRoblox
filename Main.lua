local newInstance = Instance.new
local newVector = Vector3.new
local fromRGB = Color3.fromRGB
local formatStr, splitStr = string.format, string.split
local osClock = os.clock
local floor = math.floor

local repStore = game:GetService("ReplicatedStorage")
local graph = require(repStore.Graph)
local isInEquation = graph.isInEquation
local parser = require(repStore.Parser)
local tokenize = parser.load

local WIDTH = 16 * 10
local HEIGHT = 9 * 10
local MID_PIXEL_X = floor((WIDTH - 1) * 0.5)
local MID_PIXEL_Y = floor((HEIGHT - 1) * 0.5)

local pixels = {}

local function putPixel(x: number, y: number, color: Color3)
	pixels[x + 1][y + 1].Color = color
end

local backgroundColor = fromRGB(0, 0, 0)

local function refreshScreen()
	for x = 1, WIDTH, 1 do
		for y = 1, HEIGHT, 1 do
			pixels[x][y].Color = backgroundColor
		end
	end
end

local pixelsFolder = newInstance("Folder")

pixelsFolder.Name = "Pixels"
pixelsFolder.Parent = workspace

local partSize = newVector(0.5, 0.5, 0.5)

for x = 1, WIDTH, 1 do
	pixels[x] = {}
	
	for y = 1, HEIGHT, 1 do
		local part = newInstance("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Position = newVector((x - 1) * 0.5, (y + 1) * 0.5, 0)
		part.Size = partSize
		part.Color = backgroundColor
		part.Name = formatStr("(%d, %d)", x, y)
		part.Parent = pixelsFolder
		pixels[x][y] = part	
	end
end

local ui = repStore.ScreenGui

local userInputService = game:GetService("UserInputService")

local equationHistory = {}
local historySize = 0
local currentHistoryIndex = 1

local enterPressed = false

local function handleEnterKey()
	local splitStr = splitStr(ui.TextBox.Text, "=")
	
	if #splitStr ~= 2 then
		return
	end
	
	graph.leftSymbolsCount = tokenize(graph.leftSymbols, graph.leftInputNumbers, splitStr[1])

	if not parser.success then
		return
	end

	graph.rightSymbolsCount = tokenize(graph.rightSymbols, graph.rightInputNumbers, splitStr[2])

	if not parser.success then
		return
	end	
	
	for i = 1, historySize, 1 do
		if ui.TextBox.Text == equationHistory[i] then
			return
		end
	end
	
	equationHistory[currentHistoryIndex] = ui.TextBox.Text
	
	if historySize < 5 then
		historySize += 1
	end
	
	if currentHistoryIndex == 5 then
		currentHistoryIndex = 1
	else
		currentHistoryIndex += 1	
	end
end

local historyCursor = 0

local upKeyPressed = false

local function handleUpKey()
	if historySize == 0 or userInputService:GetFocusedTextBox() ~= ui.TextBox then
		return
	end
	
	if historyCursor < historySize then
		historyCursor += 1
	else
		historyCursor = 1
	end
	
	ui.TextBox.Text = equationHistory[historyCursor]
end

local downKeyPressed = false

local function handleDownKey()
	if historySize == 0 or userInputService:GetFocusedTextBox() ~= ui.TextBox then
		return
	end
	
	if historyCursor <= 1 then
		historyCursor = historySize
	else
		historyCursor -= 1
	end
	
	ui.TextBox.Text = equationHistory[historyCursor]
end

local saveText = ""

local function textBoxFocusEvent()
	ui.TextBox.Text = saveText
end

local function textBoxLostFocusEvent()
	saveText = ui.TextBox.Text
end

ui.TextBox.Focused:Connect(textBoxFocusEvent)
ui.TextBox.FocusLost:Connect(textBoxLostFocusEvent)
ui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local runService = game:GetService("RunService")

local equationColor = fromRGB(255, 255, 255)
local lineColor = fromRGB(123, 123, 255)

local offsetX = (1 - WIDTH) * 0.5
local offsetY = (1 - HEIGHT) * 0.5
local scale = 0.1

local lastMousePos = userInputService:GetMouseLocation()
local lastTime = osClock()

while true do
	runService.RenderStepped:Wait()
	refreshScreen()
	
	local deltaTime = osClock() - lastTime
	
	lastTime = osClock()
	
	if userInputService:IsKeyDown(Enum.KeyCode.Up) then
		if not upKeyPressed then
			handleUpKey()
			upKeyPressed = true
		end
	else
		upKeyPressed = false
	end
	
	if userInputService:IsKeyDown(Enum.KeyCode.Down) then
		if not downKeyPressed then
			handleDownKey()
			downKeyPressed = true
		end
	else
		downKeyPressed = false
	end
	
	if userInputService:IsKeyDown(Enum.KeyCode.Return) then
		if not enterPressed then
			handleEnterKey()
			enterPressed = true
		end
	else
		enterPressed = false
	end
	
	local currentMousePos = userInputService:GetMouseLocation()
	
	if userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		local mouseDelta = currentMousePos - lastMousePos
		local deltaMove = deltaTime * 15
		
		offsetX -= deltaMove * mouseDelta.X
		offsetY += deltaMove * mouseDelta.Y
	end
	
	lastMousePos = currentMousePos
	
	local deltaScale = deltaTime * 0.1
	local oldScale = scale
	
	if userInputService:IsKeyDown(Enum.KeyCode.R) then
		scale -= deltaScale
	end
	
	if userInputService:IsKeyDown(Enum.KeyCode.T) then
		scale += deltaScale
	end
	
	if scale < 0.01 then
		scale = 0.01
	end
	
	if scale ~= oldScale then
		local scaleRatio = oldScale / scale
		
		offsetX = (scaleRatio * (MID_PIXEL_X + offsetX)) - MID_PIXEL_X
		offsetY = (scaleRatio * (MID_PIXEL_Y + offsetY)) - MID_PIXEL_Y
	end
	
	graph.threshold = scale
	
	local linePos = -offsetY
	
	if linePos >= 0 and linePos < HEIGHT then
		linePos = floor(linePos)
		
		for x = 0, WIDTH - 1, 1 do
			putPixel(x, linePos, lineColor)
		end
	end
	
	linePos = -offsetX
	
	if linePos >= 0 and linePos < WIDTH then
		linePos = floor(linePos)
		
		for y = 0, HEIGHT - 1, 1 do
			putPixel(linePos, y, lineColor)
		end
	end
	
	ui.Scale.Text = formatStr("scale: %.2f (x/pixel)", scale)
	
	if not parser.success then
		continue
	end
	
	for x = 0, WIDTH - 1, 1 do
		for y = 0, HEIGHT - 1, 1 do			
			if isInEquation((x + offsetX) * scale, (y + offsetY) * scale) then
				putPixel(x, y, equationColor)
			end
		end
	end
end