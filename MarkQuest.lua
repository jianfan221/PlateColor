local _, ns = ...
--任务标记
local NameQuestTable = {}
function ns.CteatNameQuest(unitFrame)
	if not unitFrame then return end
	if not unitFrame.unit then return end
	if PlateColorDB.nameQuestPos == 0 then return end

	if not unitFrame.NameQuest then
		unitFrame.NameQuest = unitFrame:CreateTexture(nil, "OVERLAY")
		unitFrame.NameQuest:SetTexture("Interface\\Addons\\PlateColor\\texture\\questicon")
		unitFrame.NameQuest:SetSize(22,22)
	end
	
	unitFrame.NameQuest:ClearAllPoints()
	if PlateColorDB.nameQuestPos == 2 and unitFrame.healthBar:IsShown() then
		unitFrame.NameQuest:SetPoint("LEFT",unitFrame.healthBar,"RIGHT",8,0)
	elseif unitFrame.name then
		unitFrame.NameQuest:SetPoint("BOTTOMLEFT",unitFrame.name,"BOTTOMRIGHT",-4,0)
	else
		unitFrame.NameQuest:SetPoint("TOP",unitFrame,"TOP",0,0)
	end
	if not ns.MM(UnitGUID(unitFrame.unit)) then
		local tooltipData = C_TooltipInfo.GetUnit(unitFrame.unit)
		if tooltipData and tooltipData.lines then
			unitFrame.NameQuest:Hide()
			local lines = tooltipData.lines
			local playerGUID = UnitGUID("player")
			for i = 2, #lines do -- ipairs 从 1 开始，但我们从 2 开始，因为第一行通常是 NPC 名字，不包含任务信息
				local line = lines[i]
				local text = line.leftText
				-- 1. 匹配任务名
				if text and not ns.MM(text) and NameQuestTable[text] then
					local nextIndex = i + 1
					local nextLine = lines[nextIndex]
					-- 2. 处理队伍中的 GUID 行：如果是自己，就看再下一行
					if nextLine and nextLine.guid == playerGUID then
						nextIndex = nextIndex + 1
						nextLine = lines[nextIndex]
					end
					-- 3. 判断任务是否未完成
					-- 注意：直接判断 .completed 属性，不要把 table 传给 ns.MM
					if nextLine and nextLine.completed == false then
						unitFrame.NameQuest:Show()
						break -- 找到一个未完成的任务就立刻退出循环
					end
				end
			end
		end
	else
		unitFrame.NameQuest:SetShown(C_QuestLog.UnitIsRelatedToActiveQuest and C_QuestLog.UnitIsRelatedToActiveQuest(unitFrame.unit))
	end

end



local  function QuestMarkEvent(event, IDs)
	if PlateColorDB.nameQuestPos == 0 then return end
	
	if event == "NAME_PLATE_UNIT_ADDED" then
		local namePlate = C_NamePlate.GetNamePlateForUnit(IDs,false)
		if not namePlate then return end
		local unitFrame = namePlate.UnitFrame
		if PlateColorDB.nameQuestPos ~= 0 then
			ns.CteatNameQuest(unitFrame)
		end
	end
		--进入游戏获取任务
	if event == "PLAYER_ENTERING_WORLD" then
		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local info = C_QuestLog.GetInfo(i); 
			if info and not info.isHeader and (info.isTask or not info.isHidden) then
				NameQuestTable[info.title] = not C_QuestLog.IsComplete(info.questID)
			end 
		end
		C_Timer.After(2,function()
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				ns.CteatNameQuest(namePlate.UnitFrame)
			end
		end)
	end
	--任务进度更新
	if event == "QUEST_WATCH_UPDATE" then
		C_Timer.After(0.5,function()
			local title = C_QuestLog.GetTitleForQuestID(IDs)
			if not title then return end
			if not NameQuestTable[title] then return end
			NameQuestTable[title] = not C_QuestLog.IsComplete(IDs)
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				ns.CteatNameQuest(namePlate.UnitFrame)
			end
		end)
	end
	if event == "QUEST_ACCEPTED" then
		C_Timer.After(0.5,function()
			if not C_QuestLog.GetLogIndexForQuestID(IDs) then return end
			local info = C_QuestLog.GetInfo(C_QuestLog.GetLogIndexForQuestID(IDs))
			if info and not info.isHeader and (info.isTask or not info.isHidden) then
				NameQuestTable[info.title] = not C_QuestLog.IsComplete(IDs)
				for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
					ns.CteatNameQuest(namePlate.UnitFrame)
				end
			end
		end)
		
	end
	if event == "QUEST_REMOVED" then
		C_Timer.After(0.5,function()
			local title = C_QuestLog.GetTitleForQuestID(IDs)
			if not title then return end
			NameQuestTable[title] = nil
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				ns.CteatNameQuest(namePlate.UnitFrame)
			end
		end)
	end
end

ns.event("NAME_PLATE_UNIT_ADDED", QuestMarkEvent)
ns.event("PLAYER_ENTERING_WORLD", QuestMarkEvent)
ns.event("QUEST_WATCH_UPDATE", QuestMarkEvent)
ns.event("QUEST_ACCEPTED", QuestMarkEvent)
ns.event("QUEST_REMOVED", QuestMarkEvent)