-- IGA - In-Game AddOns
-- Lightweight addon enable/disable manager for Vanilla WoW 1.12.1

IGA = {}
IGA.version = "1.1.0"
IGA.rows = {}
IGA.items = {}
IGA.filtered = {}
IGA.offset = 0
IGA.visibleRows = 17
IGA.changed = false
IGA.selfName = "IGA"

local function IGA_CreateBackdrop(frame, bgAlpha)
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0.05, 0.05, 0.05, bgAlpha or 0.95)
  frame:SetBackdropBorderColor(0.55, 0.55, 0.55, 1)
end

local function IGA_SetStatus(text, r, g, b)
  if not IGA.status then return end
  IGA.status:SetText(text or "")
  IGA.status:SetTextColor(r or 0.75, g or 0.75, b or 0.75)
end

local function IGA_GetSearchText()
  if not IGA.search then return "" end
  return string.lower(IGA.search:GetText() or "")
end

local function IGA_ItemMatches(item, query)
  if query == "" then
    return true
  end

  local title = string.lower(item.title or "")
  local name = string.lower(item.name or "")
  local author = string.lower(item.author or "")
  local notes = string.lower(item.notes or "")

  if string.find(title, query, 1, true) then return true end
  if string.find(name, query, 1, true) then return true end
  if string.find(author, query, 1, true) then return true end
  if string.find(notes, query, 1, true) then return true end

  return false
end

function IGA:BuildAddonList()
  self.items = {}

  local count = GetNumAddOns()
  local i
  for i = 1, count do
    local name, title, notes, enabled, loadable, reason = GetAddOnInfo(i)
    local author = GetAddOnMetadata(name, "Author")
    local version = GetAddOnMetadata(name, "Version")

    local item = {
      index = i,
      name = name,
      title = title or name,
      notes = notes or "",
      author = author or "",
      version = version or "",
      enabled = enabled and true or false,
      loadable = loadable and true or false,
      reason = reason
    }

    table.insert(self.items, item)
  end

  table.sort(self.items, function(a, b)
    return string.lower(a.title or a.name) < string.lower(b.title or b.name)
  end)

  self:ApplyFilter()
end

function IGA:ApplyFilter()
  self.filtered = {}
  local query = IGA_GetSearchText()

  local i
  for i = 1, table.getn(self.items) do
    local item = self.items[i]
    if IGA_ItemMatches(item, query) then
      table.insert(self.filtered, item)
    end
  end

  self.offset = 0
  self:UpdateScroll()
  self:RefreshRows()
end

function IGA:UpdateScroll()
  if not self.scrollbar then return end

  local maxOffset = table.getn(self.filtered) - self.visibleRows
  if maxOffset < 0 then maxOffset = 0 end

  self.scrollbar:SetMinMaxValues(0, maxOffset)
  self.scrollbar:SetValueStep(1)

  if self.offset > maxOffset then
    self.offset = maxOffset
  end

  self.scrollbar:SetValue(self.offset)

  if maxOffset == 0 then
    self.scrollbar:Hide()
  else
    self.scrollbar:Show()
  end
end

function IGA:RefreshRows()
  if not self.frame then return end

  local total = table.getn(self.filtered)
  local i

  for i = 1, self.visibleRows do
    local row = self.rows[i]
    local item = self.filtered[self.offset + i]

    if item then
      row.item = item
      row:Show()

      row.check:SetScript("OnClick", nil)
      row.check:SetChecked(item.enabled and 1 or nil)

      if item.name == self.selfName then
        row.check:Disable()
        row.title:SetText(item.title .. " |cff888888(required)|r")
      else
        row.check:Enable()
        row.title:SetText(item.title)
      end

      if item.enabled then
        row.title:SetTextColor(1, 0.82, 0)
      else
        row.title:SetTextColor(0.55, 0.55, 0.55)
      end

      row.meta:SetText("")

      row.check:SetScript("OnClick", function()
        IGA:ToggleItem(row.item, this:GetChecked())
      end)
    else
      row.item = nil
      row:Hide()
    end
  end

  if self.countText then
    self.countText:SetText(total .. " AddOns")
  end
end

function IGA:ToggleItem(item, checked)
  if not item then return end

  if item.name == self.selfName then
    item.enabled = true
    self:RefreshRows()
    return
  end

  if checked then
    EnableAddOn(item.index)
    item.enabled = true
  else
    DisableAddOn(item.index)
    item.enabled = false
  end

  self.changed = true
  IGA_SetStatus("Changes pending - Reload UI to apply", 1, 0.82, 0)
  self:RefreshRows()
end

function IGA:SetAll(enable)
  local i
  for i = 1, table.getn(self.items) do
    local item = self.items[i]

    if item.name ~= self.selfName then
      if enable then
        EnableAddOn(item.index)
        item.enabled = true
      else
        DisableAddOn(item.index)
        item.enabled = false
      end
    else
      item.enabled = true
    end
  end

  self.changed = true
  IGA_SetStatus("Changes pending - Reload UI to apply", 1, 0.82, 0)
  self:RefreshRows()
end

function IGA:Scroll(delta)
  local maxOffset = table.getn(self.filtered) - self.visibleRows
  if maxOffset < 0 then maxOffset = 0 end

  self.offset = self.offset - delta * 3

  if self.offset < 0 then self.offset = 0 end
  if self.offset > maxOffset then self.offset = maxOffset end

  if self.scrollbar then
    self.scrollbar:SetValue(self.offset)
  end

  self:RefreshRows()
end

local function IGA_RowOnEnter()
  if not this.item then return end

  this:SetBackdropBorderColor(1, 0.82, 0, 0.8)

  GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
  GameTooltip:SetText(this.item.title or this.item.name, 1, 0.82, 0)

  if this.item.version ~= "" then
    GameTooltip:AddDoubleLine("Version", this.item.version, 1,1,1, .8,.8,.8)
  end

  if this.item.author ~= "" then
    GameTooltip:AddDoubleLine("Author", this.item.author, 1,1,1, .8,.8,.8)
  end

  if this.item.notes ~= "" then
    GameTooltip:AddLine(this.item.notes, .85,.85,.85, 1)
  end

  GameTooltip:Show()
end

local function IGA_RowOnLeave()
  this:SetBackdropBorderColor(0.22, 0.22, 0.22, 1)
  GameTooltip:Hide()
end

function IGA:CreateWindow()
  if self.frame then return end

  local f = CreateFrame("Frame", "IGAFrame", UIParent)
  self.frame = f
  f:SetWidth(520)
  f:SetHeight(520)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 15)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:EnableMouseWheel(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  f:SetScript("OnMouseWheel", function()
    IGA:Scroll(arg1)
  end)
  f:SetScript("OnShow", function()
    IGA:BuildAddonList()
    if IGA.changed then
      IGA_SetStatus("Changes pending - Reload UI to apply", 1, 0.82, 0)
    else
      IGA_SetStatus("Enable or disable AddOns, then reload the UI.", .75, .75, .75)
    end
  end)
  f:Hide()

  IGA_CreateBackdrop(f, 0.96)
  table.insert(UISpecialFrames, "IGAFrame")

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", f, "TOP", 0, -18)
  title:SetText("In-Game AddOn Manager")
  title:SetTextColor(1, 0.82, 0)

  local version = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  version:SetPoint("TOPRIGHT", f, "TOPRIGHT", -18, -20)
  version:SetText("v" .. self.version)
  version:SetTextColor(.55, .55, .55)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 1)
  close:SetScript("OnClick", function() IGA.frame:Hide() end)

  local searchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  searchLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -52)
  searchLabel:SetText("Search")
  searchLabel:SetTextColor(.75, .75, .75)

  local search = CreateFrame("EditBox", "IGASearchBox", f, "InputBoxTemplate")
  self.search = search
  search:SetWidth(265)
  search:SetHeight(24)
  search:SetPoint("TOPLEFT", f, "TOPLEFT", 62, -46)
  search:SetAutoFocus(false)
  search:SetScript("OnTextChanged", function()
    IGA:ApplyFilter()
  end)
  search:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)

  local countText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  self.countText = countText
  countText:SetPoint("TOPRIGHT", f, "TOPRIGHT", -40, -53)
  countText:SetTextColor(.65, .65, .65)

  local list = CreateFrame("Frame", nil, f)
  self.list = list
  list:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -82)
  list:SetWidth(470)
  list:SetHeight(350)
  IGA_CreateBackdrop(list, 0.45)

  local i
  for i = 1, self.visibleRows do
    local row = CreateFrame("Button", nil, list)
    self.rows[i] = row

    row:SetWidth(438)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", list, "TOPLEFT", 8, -8 - ((i - 1) * 20))
    row:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    row:SetBackdropColor(.08, .08, .08, .55)
    row:SetBackdropBorderColor(.22, .22, .22, 1)
    row:SetScript("OnEnter", IGA_RowOnEnter)
    row:SetScript("OnLeave", IGA_RowOnLeave)
    row:SetScript("OnClick", function()
      if not this.item or this.item.name == IGA.selfName then return end
      this.check:Click()
    end)

    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check = check
    check:SetWidth(24)
    check:SetHeight(24)
    check:SetPoint("LEFT", row, "LEFT", 1, 0)

    local titleText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title = titleText
    titleText:SetPoint("LEFT", row, "LEFT", 28, 0)
    titleText:SetWidth(385)
    titleText:SetJustifyH("LEFT")

    local metaText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.meta = metaText
    metaText:SetText("")
    metaText:Hide()
  end

  local scrollbar = CreateFrame("Slider", "IGAScrollBar", list)
  self.scrollbar = scrollbar
  scrollbar:SetOrientation("VERTICAL")
  scrollbar:SetWidth(16)
  scrollbar:SetHeight(330)
  scrollbar:SetPoint("TOPRIGHT", list, "TOPRIGHT", -5, -10)
  scrollbar:SetValueStep(1)
  scrollbar:SetMinMaxValues(0, 0)
  scrollbar:SetValue(0)
  scrollbar:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })

  local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
  thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
  thumb:SetWidth(32)
  thumb:SetHeight(32)
  scrollbar:SetThumbTexture(thumb)

  scrollbar:SetScript("OnValueChanged", function()
    local value = math.floor(this:GetValue() + .5)
    if value ~= IGA.offset then
      IGA.offset = value
      IGA:RefreshRows()
    end
  end)

  local enableAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  enableAll:SetWidth(105)
  enableAll:SetHeight(24)
  enableAll:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 48)
  enableAll:SetText("Enable All")
  enableAll:SetScript("OnClick", function() IGA:SetAll(true) end)

  local disableAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  disableAll:SetWidth(105)
  disableAll:SetHeight(24)
  disableAll:SetPoint("LEFT", enableAll, "RIGHT", 8, 0)
  disableAll:SetText("Disable All")
  disableAll:SetScript("OnClick", function() IGA:SetAll(false) end)

  local reload = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  reload:SetWidth(115)
  reload:SetHeight(24)
  reload:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 48)
  reload:SetText("Reload UI")
  reload:SetScript("OnClick", function()
    ReloadUI()
  end)

  local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  self.status = status
  status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 20)
  status:SetWidth(480)
  status:SetJustifyH("LEFT")
  status:SetText("Enable or disable AddOns, then reload the UI.")
  status:SetTextColor(.75, .75, .75)
end

function IGA:CreateGameMenuButton()
  if GameMenuButtonIGA then return end
  if not GameMenuFrame then return end

  local button = CreateFrame("Button", "GameMenuButtonIGA", GameMenuFrame, "GameMenuButtonTemplate")
  self.menuButton = button
  button:SetText("AddOn Manager")

  -- Rebuild the visible Escape menu into one compact stack.
  -- AddOns is placed third: Video, Sound, AddOns, Interface, Key Bindings...
  local buttons = {
    GameMenuButtonOptions,
    GameMenuButtonSoundOptions,
    button,
    GameMenuButtonUIOptions,
    GameMenuButtonKeybindings,
    GameMenuButtonMacros,
    GameMenuButtonLogout,
    GameMenuButtonQuit
  }

  -- Include third-party menu buttons that are already attached to GameMenuFrame,
  -- but avoid duplicates and Return to Game. This keeps things like MoveAnything!
  -- in the normal stack without introducing gaps.
  local known = {}
  local i
  for i = 1, table.getn(buttons) do
    if buttons[i] then known[buttons[i]] = true end
  end
  if GameMenuButtonContinue then known[GameMenuButtonContinue] = true end

  local child = { GameMenuFrame:GetChildren() }
  for i = 1, table.getn(child) do
    local b = child[i]
    if b and b.GetObjectType and b:GetObjectType() == "Button" and not known[b] then
      local text = b.GetText and b:GetText()
      if text and text ~= "" then
        -- Insert custom buttons before Logout if possible.
        local inserted = false
        local j
        for j = 1, table.getn(buttons) do
          if buttons[j] == GameMenuButtonLogout then
            table.insert(buttons, j, b)
            inserted = true
            break
          end
        end
        if not inserted then
          table.insert(buttons, b)
        end
        known[b] = true
      end
    end
  end

  local topY = -42
  local gap = 3
  local buttonHeight = 21

  local visibleCount = 0
  for i = 1, table.getn(buttons) do
    local b = buttons[i]
    if b and b:IsShown() then
      visibleCount = visibleCount + 1
      b:ClearAllPoints()
      b:SetPoint("TOP", GameMenuFrame, "TOP", 0, topY - ((visibleCount - 1) * (buttonHeight + gap)))
    end
  end

  -- Return to Game stays at the bottom, but now always remains inside the border.
  local bottomPadding = 30
  local continueGap = 12
  local frameHeight = 54 + (visibleCount * (buttonHeight + gap)) + continueGap + buttonHeight + bottomPadding

  GameMenuFrame:SetHeight(frameHeight)

  if GameMenuButtonContinue then
    GameMenuButtonContinue:ClearAllPoints()
    GameMenuButtonContinue:SetPoint("BOTTOM", GameMenuFrame, "BOTTOM", 0, 18)
  end

  button:SetScript("OnClick", function()
    HideUIPanel(GameMenuFrame)
    IGA.frame:Show()
  end)
end

function IGA:ToggleWindow()
  if not self.frame then
    self:CreateWindow()
  end

  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
  IGA:CreateWindow()
  IGA:CreateGameMenuButton()
end)

SLASH_IGA1 = "/iga"
SlashCmdList["IGA"] = function()
  IGA:ToggleWindow()
end
