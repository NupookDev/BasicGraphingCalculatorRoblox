local module = {}

local MAX_SIZE = 5

type historyContext = {
	equations: { string },
	size: number,
	currentIndex: number,
	cursorIndex: number
}

local historyContext: historyContext = {
	equations = {},
	size = 0,
	currentIndex = 1,
	cursorIndex = 0
}

function module.saveText(text: string)
	for i = 1, historyContext.size, 1 do
		if historyContext.equations[i] == text then
			return
		end
	end
	
	if historyContext.size < MAX_SIZE then
		historyContext.size += 1
	end	
	
	historyContext.equations[historyContext.currentIndex] = text
	
	if historyContext.currentIndex == MAX_SIZE then
		historyContext.currentIndex = 1
	else
		historyContext.currentIndex += 1
	end
	
	historyContext.cursorIndex = 1
end

function module.getNextText(): string
	if historyContext.size == 0 then
		return nil
	end
	
	if historyContext.cursorIndex < historyContext.size then
		historyContext.cursorIndex += 1
	else
		historyContext.cursorIndex = 1
	end
	
	return historyContext.equations[historyContext.cursorIndex]
end

function module.getPreviousText(): string
	if historyContext.size == 0 then
		return nil
	end
	
	if historyContext.cursorIndex > 1 then
		historyContext.cursorIndex -= 1
	else
		historyContext.cursorIndex = historyContext.size
	end
	
	return historyContext.equations[historyContext.cursorIndex]
end

return module
