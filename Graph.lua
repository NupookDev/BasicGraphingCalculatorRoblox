local module = {}

local calculate = require(game:GetService("ReplicatedStorage").Parser).calculate

module.threshold = 0

module.leftSymbols = {}
module.leftSymbolsCount = 0
module.leftInputNumbers = {}
module.rightSymbols = {}
module.rightSymbolsCount = 0
module.rightInputNumbers = {}

module.isInEquation = function(x: number, y: number): boolean	
	local left = calculate(module.leftSymbols, module.leftSymbolsCount, module.leftInputNumbers, x, y)
	local right = calculate(module.rightSymbols, module.rightSymbolsCount, module.rightInputNumbers, x, y)
	local result = left - right
	
	if result < 0 then
		result = -result
	end
	
	if result <= module.threshold then
		return true
	end
	
	return false
end


return module
