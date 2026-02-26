local graph = require(script.Graph)
local parser = require(script.Parser)

local WIDTH = 16 * 10
local HEIGHT = 9 * 10
local MID_PIXEL_X = math.floor((WIDTH - 1) * 0.5)
local MID_PIXEL_Y = math.floor((HEIGHT - 1) * 0.5)

local backgroundColor = Color3.fromRGB(0, 0, 0)
local equationColor = Color3.fromRGB(255, 255, 255)

local ui = script.ScreenGui
local userInputService = game:GetService("UserInputService")

local pixels: { Part } = {}

local offsetX = (1 - WIDTH) * 0.5
local offsetY = (1 - HEIGHT) * 0.5
local scale = 0.1

local equationHistory: { string } = {}
local historySize = 0
local currentHistoryIndex = 1
local historyCursor = 0
local saveText = ""

local function putPixel(x: number, y: number, color: Color3)
	pixels[x + 1][y + 1].Color = color
end

local function refreshScreen()
	for x = 1, WIDTH, 1 do
		for y = 1, HEIGHT, 1 do
			pixels[x][y].Color = backgroundColor
		end
	end
end

local function handleEnterKey(name: string, inputState: Enum.UserInputState)
	if userInputService:GetFocusedTextBox() == nil then
		return
	end
	
	local splitStr = string.split(ui.TextBox.Text, "=")
	
	if #splitStr ~= 2 then
		return
	end
	
	graph.leftSymbolsCount = parser.load(graph.leftSymbols, graph.leftInputNumbers, splitStr[1])

	if not parser.success then
		return
	end

	graph.rightSymbolsCount = parser.load(graph.rightSymbols, graph.rightInputNumbers, splitStr[2])

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

local function handleUpKey(name: string, inputState: Enum.UserInputState)
	if userInputService:GetFocusedTextBox() == nil or historySize == 0 then
		return
	end
	
	if historyCursor < historySize then
		historyCursor += 1
	else
		historyCursor = 1
	end
	
	ui.TextBox.Text = equationHistory[historyCursor]
end

local function handleDownKey(name: string, inputState: Enum.UserInputState)
	if userInputService:GetFocusedTextBox() == nil or historySize == 0 then
		return
	end
	
	if historyCursor <= 1 then
		historyCursor = historySize
	else
		historyCursor -= 1
	end
	
	ui.TextBox.Text = equationHistory[historyCursor]
end

local function textBoxFocusEvent()
	ui.TextBox.Text = saveText
end

local function textBoxLostFocusEvent()
	saveText = ui.TextBox.Text
end

local function upatePixels()
	for x = 0, WIDTH - 1, 1 do
		for y = 0, HEIGHT - 1, 1 do				
			if graph.isInEquation((x + offsetX) * scale, (y + offsetY) * scale) then
				putPixel(x, y, equationColor)
			end
		end
	end
end

local function generateWorldPixels()
	local pixelsFolder = Instance.new("Folder")

	pixelsFolder.Name = "Pixels"
	pixelsFolder.Parent = workspace

	local partSize = Vector3.new(0.5, 0.5, 0.5)

	for x = 1, WIDTH, 1 do
		pixels[x] = {}

		for y = 1, HEIGHT, 1 do
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.CastShadow = false
			part.Position = Vector3.new((x - 1) * 0.5, (y + 1) * 0.5, 0)
			part.Size = partSize
			part.Color = backgroundColor
			part.Name = string.format("(%d, %d)", x, y)
			part.Parent = pixelsFolder
			pixels[x][y] = part	
		end
	end
end

local function main()
	generateWorldPixels()

	ui.TextBox.Focused:Connect(textBoxFocusEvent)
	ui.TextBox.FocusLost:Connect(textBoxLostFocusEvent)
	ui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	
	local contextActionService = game:GetService("ContextActionService")
	contextActionService:BindAction("enter", handleEnterKey, false, Enum.KeyCode.Return)
	contextActionService:BindAction("down", handleDownKey, false, Enum.KeyCode.Down)
	contextActionService:BindAction("up", handleUpKey, false, Enum.KeyCode.Up)

	local runService = game:GetService("RunService")

	local lineColor = Color3.fromRGB(123, 123, 255)

	local lastMousePos = userInputService:GetMouseLocation()
	local lastTime = os.clock()

	while true do
		runService.PreRender:Wait()
		
		local currentTime = os.clock()
		local deltaTime = currentTime - lastTime
		lastTime = currentTime
		
		refreshScreen()
		
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
			linePos = math.floor(linePos)
			
			for x = 0, WIDTH - 1, 1 do
				putPixel(x, linePos, lineColor)
			end
		end
		
		linePos = -offsetX
		
		if linePos >= 0 and linePos < WIDTH then
			linePos = math.floor(linePos)
			
			for y = 0, HEIGHT - 1, 1 do
				putPixel(linePos, y, lineColor)
			end
		end
		
		ui.Scale.Text = string.format("scale: %.2f (x/pixel)", scale)
		
		if parser.success then
			upatePixels()
		end
	end
end

main()