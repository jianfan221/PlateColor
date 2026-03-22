local addonName,ns = ...
local L = ns.L

local ImportDialog = CreateFrame("Frame", "PlateColorBox", UIParent, "EditModeLayoutDialogTemplate")
ImportDialog:SetSize(400, 400) -- Set the size of the dialog
ImportDialog:ClearAllPoints()
ImportDialog:SetPoint("CENTER",0,100)
ImportDialog:SetFrameStrata("DIALOG")
ImportDialog:SetMovable(true)
ImportDialog:EnableMouse(true)
ImportDialog:RegisterForDrag("LeftButton")
ImportDialog:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
ImportDialog:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)
ImportDialog.ExportText = ""
ImportDialog.ScriptTrue = false
ImportDialog.Title:SetText(ns.RCTexts(addonName))
ImportDialog.Title:SetScale(2)
ImportDialog.Title:SetPoint("TOP", 0, -5)
ImportDialog.LayoutNameEditBox:Disable()
ImportDialog.LayoutNameEditBox:Hide()
ImportDialog.CharacterSpecificLayoutCheckButton:EnableMouse(false)
ImportDialog.CharacterSpecificLayoutCheckButton:Hide()
ImportDialog.AcceptButton:SetText(HUD_EDIT_MODE_IMPORT_LAYOUT)
ImportDialog.AcceptButton:EnableMouse(true)
ImportDialog.CancelButton:SetText(CANCEL)
ImportDialog.CancelButton:SetScript("OnClick", function()
    ImportDialog:Hide()
end)

ImportDialog.InputBox = CreateFrame("ScrollFrame", nil, ImportDialog, "InputScrollFrameTemplate")
ImportDialog.InputBox:SetPoint("TOPLEFT", ImportDialog, "TOPLEFT", 20, -50)
ImportDialog.InputBox:SetPoint("BOTTOMRIGHT", ImportDialog, "BOTTOMRIGHT", -20, 60)
ImportDialog.InputBox.CopyHint = ImportDialog.InputBox.EditBox:CreateFontString(nil, "OVERLAY")
ImportDialog.InputBox.CopyHint:SetPoint("CENTER", ImportDialog.InputBox, "CENTER", -20, 0)
ImportDialog.InputBox.CopyHint:SetFont(GameFontHighlightLarge:GetFont(), 150, "OUTLINE")
ImportDialog.InputBox.CopyHint:SetVertexColor(0,1,0,1)
ImportDialog.InputBox.CopyHint:SetText("Ctrl+C")
ImportDialog.InputBox.CopyHint:Hide()
ImportDialog.InputBox.EditBox:SetSize(ImportDialog.InputBox:GetWidth()-20, ImportDialog.InputBox:GetHeight())
ImportDialog.InputBox.EditBox:SetTextInsets(0, 0, 5, 0) 
ImportDialog.InputBox.EditBox:SetFontObject(GameFontHighlightSmall)
ImportDialog.InputBox.EditBox:SetAutoFocus(false)
ImportDialog.InputBox.EditBox:SetMultiLine(true)
ImportDialog.InputBox.EditBox:SetMaxLetters(0)
ImportDialog.InputBox.EditBox:SetText(ImportDialog.ExportText)
ImportDialog.InputBox.EditBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
end)
ImportDialog.InputBox.EditBox:SetScript("OnKeyDown", function(self, key)
    if not ImportDialog.ScriptTrue then return end
    if IsControlKeyDown() and (key == "X" or key == "C") then
        C_Timer.After(0.1, function()
            ImportDialog:Hide()
            UIErrorsFrame:AddExternalWarningMessage(L["复制完成"])
            UIErrorsFrame:AddExternalWarningMessage(L["复制完成"])
            UIErrorsFrame:AddExternalWarningMessage(L["复制完成"])
        end)
    end
end)
ImportDialog.InputBox.EditBox:SetScript("OnTextChanged", function(self)
    if not ImportDialog.ScriptTrue then return end
    if self:GetText() ~= ImportDialog.ExportText then
        self:SetText(ImportDialog.ExportText)
        self:HighlightText()
    end
end)

ImportDialog.InputBox.EditBox:SetScript("OnEditFocusLost", function(self)
    self:HighlightText(0, 0)
end)

ImportDialog.InputBox.EditBox:SetScript("OnHide", function(self)
    ImportDialog.ExportText = ""
    ImportDialog.InputBox.CopyHint:Hide()
    ImportDialog.ScriptTrue = false
end)

function ns.ShowBox(text)
    if text == nil then--目前只有导入需要用到
        ImportDialog:Show()
        ImportDialog:ClearAllPoints()
        ImportDialog:SetPoint("CENTER",0,100)
        ImportDialog.ExportText = ""
        ImportDialog.ScriptTrue = false
        ImportDialog.InputBox.EditBox:SetText("")
        ImportDialog.InputBox.EditBox:SetFocus(true)
        ImportDialog.InputBox.CopyHint:Hide()
        ImportDialog.CancelButton:Show()
        ImportDialog.CancelButton:SetText(CANCEL)
        ImportDialog.CancelButton:ClearAllPoints()
        ImportDialog.CancelButton:SetPoint("BOTTOMRIGHT", ImportDialog, "BOTTOMRIGHT", -25, 25)
        ImportDialog.AcceptButton:Show()
        ImportDialog.AcceptButton:SetText(HUD_EDIT_MODE_IMPORT_LAYOUT)
        ImportDialog.AcceptButton:SetScript("OnClick", function()
            local text = ImportDialog.InputBox.EditBox:GetText()
            ns.SetImportDB(text)
        end)
    else
        ImportDialog:Show()
        ImportDialog:ClearAllPoints()
        ImportDialog:SetPoint("CENTER",0,100)
        ImportDialog.ExportText = text
        ImportDialog.ScriptTrue = true
        ImportDialog.InputBox.CopyHint:Show()
        ImportDialog.CancelButton:Show()
        ImportDialog.CancelButton:SetText(OKAY)
        ImportDialog.CancelButton:ClearAllPoints()
        ImportDialog.CancelButton:SetPoint("BOTTOM", ImportDialog, "BOTTOM", 0, 25)
        ImportDialog.InputBox.EditBox:SetText(text)
        ImportDialog.InputBox.EditBox:SetFocus(true)
        ImportDialog.AcceptButton:Hide()
    end
end