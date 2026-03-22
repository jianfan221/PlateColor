local addonName, ns = ...
local L = ns.L

--序列化C_EncodingUtil.SerializeJSON
--序列化解码C_EncodingUtil.DeserializeJSON


-- 校验并合并导入的配置（缺少的key用默认值补全）
-- 返回: mergedDB, missingKeys, errMsg
function ns.ValidateAndMergeImport(importDB)
	if type(importDB) ~= "table" then
		return nil, nil, L["导入格式错误"]
	end

	-- 检查是否有基本字段（至少包含一个默认DB里的key）
	local hasAny = false
	for k in pairs(ns.PlateColorDB) do
		if importDB[k] ~= nil then
			hasAny = true
			break
		end
	end
	if not hasAny then
		return nil, nil, L["导入格式不匹配"]
	end

	local missingKeys = {}

	-- 按照DefaultDB的合并逻辑补全缺失的字段，同时记录缺失项
	for k, v in pairs(ns.PlateColorDB) do
		if type(v) == "table" then
			if importDB[k] == nil then
				importDB[k] = {}
				table.insert(missingKeys, tostring(k) .. " (" .. L["整个表缺失"] .. ")")
			else
				local subMissing = {}
				for k2, v2 in pairs(v) do
					if type(k2) ~= "number" and importDB[k][k2] == nil then
						importDB[k][k2] = v2
						table.insert(subMissing, tostring(k2))
					end
				end
				if #subMissing > 0 then
					table.insert(missingKeys, tostring(k) .. ".{" .. table.concat(subMissing, ", ") .. "}")
				end
			end
		else
			if importDB[k] == nil then
				importDB[k] = v
				table.insert(missingKeys, tostring(k))
			end
		end
	end

	return importDB, missingKeys, nil
end

-- 临时存储变量
local PCPendingImportDB = nil

function ns.SetImportDB(text)
	local retOK, ret1 =  pcall(C_EncodingUtil.DeserializeJSON, text)
	if not retOK then
		print("|cffff0000[PlateColor]|r " .. L["字符串解析失败"] .. tostring(ret1))
		return
	else
		local mergedDB, missingKeys, mergeErr = ns.ValidateAndMergeImport(ret1)
		if not mergedDB then
			print("|cffff0000[PlateColor]|r " .. L["配置校验失败"] .. tostring(mergeErr))
			return
		end
		if missingKeys and #missingKeys > 0 then
			print("|cffffff00[PlateColor]|r " .. L["以下配置项缺失"])
			for _, key in ipairs(missingKeys) do
				print("|cffffff00  - " .. key .. "|r")
			end
			PCPendingImportDB = mergedDB
			StaticPopup_Show("PLATECOLOR_IMPORT_CONFIRM")
		else
			PlateColorDB = mergedDB
			print("|cff00ff00[PlateColor]|r " .. L["配置已导入"])
			ReloadUI()
		end
	end
end

StaticPopupDialogs["PLATECOLOR_IMPORT_CONFIRM"] = {
	text = L["缺失配置确认"],
	button1 = HUD_EDIT_MODE_IMPORT_LAYOUT,
	button2 = CANCEL,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self)
		if PCPendingImportDB then
			PlateColorDB = PCPendingImportDB
			PCPendingImportDB = nil
			print("|cff00ff00[PlateColor]|r " .. L["配置已导入"])
			ReloadUI()
		end
	end,
	OnCancel = function(self)
		PCPendingImportDB = nil
	end,
}

StaticPopupDialogs["PLATECOLOR_REDB"] = {
	text = L["继续执行将失去现有的配置\n是否需要恢复默认"],
	button1 = OKAY,
	button2 = CANCEL,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self)
		PlateColorDB = ns.PlateColorDB
		ReloadUI()
	end,
	OnCancel = function() end,
}