local module = {}
local parser = require(script.Parent.Parser)

module.threshold = 0
module.canRender = false

local leftSideEquation: parser.parsedEquation = {}
local rightSideEquation: parser.parsedEquation = {}

function module.loadEquation(leftText: string, rightText: string)
	module.canRender = parser.load(leftSideEquation, leftText) and parser.load(rightSideEquation, rightText)
end

function module.isInEquation(x: number, y: number): boolean	
	local left = parser.calculate(leftSideEquation, x, y)
	local right = parser.calculate(rightSideEquation, x, y)
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
