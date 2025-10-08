local module = {}

local sin, cos, tan = math.sin, math.cos, math.tan
local pow = math.pow
local log10 = math.log10
local toNumber = tonumber
local splitStr = string.split
local try = pcall

local params = {}

local operandOrder = {
	{
		op = "+",
		paramCount = 2,
		func = function()
			return params[1] + params[2]
		end,
	},
	{
		op = "-",
		paramCount = 2,
		func = function()
			return params[1] - params[2]
		end,
	},
	{
		op = "*",
		paramCount = 2,
		func = function()
			return params[1] * params[2]
		end,
	},
	{
		op = "/",
		paramCount = 2,
		func = function()
			return params[1] / params[2]
		end,
	},
	{
		op = "^",
		paramCount = 2,
		func = function()
			return pow(params[1], params[2])
		end,
	},
	{
		op = "sin",
		paramCount = 1,
		func = function()
			return sin(params[1])
		end,
	},
	{
		op = "log",
		paramCount = 1,
		func = function()
			return log10(params[1])
		end,
	},
	{
		op = "cos",
		paramCount = 1,
		func = function()
			return cos(params[1])
		end,		
	},
	{
		op = "tan",
		paramCount = 1,
		func = function()
			return tan(params[1])
		end,
	},
	{
		op = "mod",
		paramCount = 2,
		func = function()
			return params[1] % params[2]
		end,
	},
	{
		op = "abs",
		paramCount = 1,
		func = function()
			if params[1] < 0 then
				return -params[1]
			end
			
			return params[1]
		end,
	}
}

module.success = false

module.load = function(symbols: { number }, inputNumbers: { number }, input: string): number
	module.success = false
	
	local stringTokens = splitStr(input, " ")
	local inputNumberCount = 0
	local symbolCount = 0
	local resultStackCount = 0
	
	for i = 1, #stringTokens, 1 do
		if stringTokens[i] == "" then
			continue
		end 
		
		local success, num = try(toNumber, stringTokens[i])
		
		if not success then
			return 0
		end		
		
		if num == nil then
			if stringTokens[i] == "x" then
				symbolCount += 1
				symbols[symbolCount] = -1
				resultStackCount += 1
			elseif stringTokens[i] == "y" then
				symbolCount += 1
				symbols[symbolCount] = -2
				resultStackCount += 1
			else
				local found = false

				for j =  1, #operandOrder, 1 do
					if stringTokens[i] == operandOrder[j].op then
						symbolCount += 1
						symbols[symbolCount] = j
						found = true
						
						if resultStackCount < operandOrder[j].paramCount then
							return 0
						end
						
						resultStackCount -= (operandOrder[j].paramCount - 1)
						break
					end
				end

				if not found then
					return 0
				end
			end
		else
			symbolCount += 1
			symbols[symbolCount] = 0
			inputNumberCount += 1
			inputNumbers[inputNumberCount] = num
			resultStackCount += 1
		end			
	end
	
	if resultStackCount ~= 1 then
		return 0
	end
	
	module.success = true
	return symbolCount
end

module.calculate = function(symbols: { number }, symbolCount: number, inputNumbers: { number }, x: number, y: number): number	
	local resultStack = {}
	local resultStackSize = 0
	local symbolIndex = 1
	local inputNumberIndex = 1
	
	repeat
		local currentSymbol = symbols[symbolIndex]
		
		if currentSymbol == 0 then
			resultStackSize += 1
			resultStack[resultStackSize] = inputNumbers[inputNumberIndex]
			inputNumberIndex += 1
		elseif currentSymbol == -1 then
			resultStackSize += 1
			resultStack[resultStackSize] = x
		elseif currentSymbol == -2 then
			resultStackSize += 1
			resultStack[resultStackSize] = y
		else
			local operandData = operandOrder[currentSymbol]
			
			for i = 1, operandData.paramCount, 1 do
				params[i] = resultStack[resultStackSize - operandData.paramCount + i]
			end
			
			resultStack[resultStackSize - operandData.paramCount + 1] = operandData.func()
			resultStackSize -= (operandData.paramCount - 1)
		end
		
		symbolIndex += 1
	until symbolIndex > symbolCount
	
	return resultStack[1]
end

return module
