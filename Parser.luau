local module = {}

local NON_OP_SYMBOL = {
	NUMBER = 0,
	X = -1,
	Y = -2,
}

type operandData = {
	op: string,
	paramCount: number,
	func: () -> (number)
}

export type parsedEquation = {
	symbols: { number },
	numbers: { number },
	symbolCount: number
}

local params: { number } = {}

local operandOrder: { operandData } = {
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
			return math.pow(params[1], params[2])
		end,
	},
	{
		op = "sin",
		paramCount = 1,
		func = function()
			return math.sin(params[1])
		end,
	},
	{
		op = "log",
		paramCount = 1,
		func = function()
			return math.log10(params[1])
		end,
	},
	{
		op = "cos",
		paramCount = 1,
		func = function()
			return math.cos(params[1])
		end,		
	},
	{
		op = "tan",
		paramCount = 1,
		func = function()
			return math.tan(params[1])
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

local function getOperatorIndex(opName: string): number
	for i = 1, #operandOrder, 1 do
		if operandOrder[i].op == opName then
			return i
		end
	end
	
	return -1
end

local function addSymbolToParsed(resultParsed: parsedEquation, symbol: number)
	resultParsed.symbolCount += 1
	resultParsed.symbols[resultParsed.symbolCount] = symbol
end

function module.load(resultParsedEquation: parsedEquation, input: string): boolean
	resultParsedEquation.symbolCount = 0
	resultParsedEquation.symbols = {}
	resultParsedEquation.numbers = {}
	
	local stringTokens: { string } = string.split(input, " ")
	local inputNumberCount = 0
	local resultStackCount = 0
	
	for i = 1, #stringTokens, 1 do
		if stringTokens[i] == "" then
			continue
		end 
		
		local success, num = pcall(tonumber, stringTokens[i])
		
		if not success then
			return false
		end		
		
		if num == nil then
			if stringTokens[i] == "x" then
				addSymbolToParsed(resultParsedEquation, NON_OP_SYMBOL.X)
				resultStackCount += 1
			elseif stringTokens[i] == "y" then
				addSymbolToParsed(resultParsedEquation, NON_OP_SYMBOL.Y)
				resultStackCount += 1
			else
				local operatorIndex = getOperatorIndex(stringTokens[i])
				
				if operatorIndex == -1 or resultStackCount < operandOrder[operatorIndex].paramCount then
					return false
				end
				
				addSymbolToParsed(resultParsedEquation, operatorIndex)
				resultStackCount -= (operandOrder[operatorIndex].paramCount - 1)	
			end
		else
			addSymbolToParsed(resultParsedEquation, NON_OP_SYMBOL.NUMBER)
			
			inputNumberCount += 1
			resultParsedEquation.numbers[inputNumberCount] = num
			
			resultStackCount += 1
		end			
	end
	
	if resultStackCount ~= 1 then
		return false
	end
	
	return true
end

function module.calculate(resultParsedEquation: parsedEquation, x: number, y: number): number	
	local resultStack: { number } = {}
	local resultStackSize = 0
	local symbolIndex = 1
	local inputNumberIndex = 1
	
	repeat
		local currentSymbol = resultParsedEquation.symbols[symbolIndex]
		
		if currentSymbol == 0 then
			resultStackSize += 1
			resultStack[resultStackSize] = resultParsedEquation.numbers[inputNumberIndex]
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
	until symbolIndex > resultParsedEquation.symbolCount
	
	return resultStack[1]
end

return module
