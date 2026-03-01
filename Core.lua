local Cellular = CreateFrame("Frame", "Cellular", UIParent)
local a = Cellular
local smed = LibStub("LibSharedMedia-3.0")

local _G = _G
local format, gsub, strmatch, gmatch = format, gsub, strmatch, gmatch
--local cfeb, ChatFrame_GetMessageEventFilters = ChatFrame10EditBox or ChatFrame1EditBox, ChatFrame_GetMessageEventFilters
local cfeb = ChatEdit_GetActiveWindow() or DEFAULT_CHAT_FRAME.editBox
local GetMessageEventFilters = C_ChatInfo and C_ChatInfo.GetMessageEventFilters

local db, svar
local you, attached, lastwindow, currenttab, eb
local nwin = 0
local base, tabs, usedtabs, recentw, taborder = {}, {}, {}, {}, {}
local l_p, l_rt, l_rp, l_x, l_y, r_p, r_rt, r_rp, r_x, r_y

local MinimizeWindow, GetWindow, CloseWindow, ShowOptions
local realmName = GetRealmName()


a:SetScript("OnEvent", function(this, event, ...)
  a[event](a, ...)
end)
a:RegisterEvent("ADDON_LOADED")
---------------------------
function a:ADDON_LOADED(a1)
---------------------------
  if a1 ~= "Cellular" then return end
  a:UnregisterEvent("ADDON_LOADED")
  a.ADDON_LOADED = nil

  CellularDB = CellularDB or {}
  if CellularDB.char then
    CellularCharDB = CellularCharDB or (CellularDB.profiles and CellularDB.profiles.Default) or CellularDB
    db = CellularCharDB
  else
    db = (CellularDB.profiles and CellularDB.profiles.Default) or CellularDB
  end

  if db.dbinit ~= 2 then
    db.dbinit = 2
    for k, v in pairs({
      width = 340, height = 160,
      pos = { },
      alpha = 0.9,
      bglist = "background",
      bg = "Tooltip",
      bgcolor = { 0, 0, 0, 1, },
      border = "Blizzard Tooltip",
      bordercolor = { 0.7, 0.7, 0.7, 1, },
      incolor = { 1, 0, 1, 1, },
      outcolor = { 0, 1, 1, 1, },
      busymessage = "Sorry, I'm busy right now...I'll chat with you later.",
      history = true, enabletabs = false, char = false,
      maxwindows = 8,
      fade = true,
      automin = false, autominalways = false,
      showname = true, showtime = true, showside = true,
      fontmsg = "Arial Narrow", fonttitle = "Arial Narrow", fontsize = 12,
    }) do
      db[k] = (db[k] ~= nil and db[k]) or v
    end
  end
  db.border = (type(db.border) == "string" and db.border) or (db.border and "Blizzard Tooltip") or "None"
  a:SetAlpha(db.alpha)

  Cellular_History = Cellular_History or { }  -- saved history per char
  svar = Cellular_History

  SlashCmdList.CELLULAR = ShowOptions
  SLASH_CELLULAR1, SLASH_CELLULAR2 = "/cellular", "/cell"
  local panel = CreateFrame("Frame")
  panel.name = "Cellular"
  panel:SetScript("OnShow", function(this)
    local t1 = this:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    t1:SetJustifyH("LEFT")
    t1:SetJustifyV("TOP")
    t1:SetPoint("TOPLEFT", 16, -16)
    t1:SetText(this.name)

    local t2 = this:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    t2:SetJustifyH("LEFT")
    t2:SetJustifyV("TOP")
    t2:SetHeight(43)
    t2:SetPoint("TOPLEFT", t1, "BOTTOMLEFT", 0, -8)
    t2:SetPoint("RIGHT", this, "RIGHT", -32, 0)
    t2:SetNonSpaceWrap(true)
    t2:SetFormattedText( "Notes: %s\nAuthor: %s\nVersion: %s",
        C_AddOns.GetAddOnMetadata("Cellular", "Notes"),
        C_AddOns.GetAddOnMetadata("Cellular", "Author"),
        C_AddOns.GetAddOnMetadata("Cellular", "Version") )

    local b = CreateFrame("Button", nil, this, "UIPanelButtonTemplate")
    b:SetWidth(120)
    b:SetHeight(20)
    b:SetText("Options Menu")
    b:SetScript("OnClick", ShowOptions)
    b:SetPoint("TOPLEFT", t2, "BOTTOMLEFT", -2, -8)
    this:SetScript("OnShow", nil)
  end)
  --InterfaceOptions_AddCategory(panel)
  local category = Settings.RegisterCanvasLayoutCategory(panel, "Cellular")
  Settings.RegisterAddOnCategory(category)

  local cevents = { "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_AFK", "CHAT_MSG_DND", "CHAT_MSG_IGNORED", }
  if not db.nobn then
    tinsert(cevents, "CHAT_MSG_BN_WHISPER")
    tinsert(cevents, "CHAT_MSG_BN_WHISPER_INFORM")
  end
  for _, v in ipairs(cevents) do
    a:RegisterEvent(v)
  end
  you = UnitName("player")
  a.pratloaded = select(4, C_AddOns.GetAddOnInfo("Prat-3.0"))

  CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {}
  CONFIGMODE_CALLBACKS.Cellular = function(action, mode)
    if action == "ON" then
      print("|cff00ff00Cellular|r: Entering config mode.")
    end
  end

  if not db.chatshow then  -- don't display some messages to the chat frame
    local _G = getfenv(0)
    local function Unreg(frame)
      if type(frame) ~= "table" then return end
      for _, v in ipairs(cevents) do
        frame:UnregisterEvent(v)
      end
    end
    for i = 1, NUM_CHAT_WINDOWS, 1 do
      Unreg(_G["ChatFrame"..i])
    end
    hooksecurefunc("ChatFrame_AddMessageGroup", Unreg)
    hooksecurefunc("ChatFrame_RegisterForMessages", Unreg)
  end
end

--------------------------------------
--- EVENTS
local function Filter(event, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14)
  local cfilter = GetMessageEventFilters and GetMessageEventFilters(event)
  if cfilter then  -- filter
    for _, filterFunc in next, cfilter do
      local filter, n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14 = filterFunc(a, event, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14)
      if filter then
        return true
      elseif n1 and n2 then
        a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14 = n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14
      end
    end
  end
  if a7 < 1 or (a7 >= 1 and (_G.CHAT_SHOW_ICONS == nil or _G.CHAT_SHOW_ICONS ~= "0")) then  -- chat icons
    for tag in gmatch(a1, "%b{}") do
      --local termlist = ICON_TAG_LIST[ strlower(gsub(tag, "[{}]", "")) ]
      --local icon = termlist and ICON_LIST[termlist]
      --if icon then
      --  a1 = gsub(a1, tag, icon.."0|t")
      --end
      a1 = C_ChatInfo.ReplaceIconTags(a1)
    end
  end
  return a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14
end
--------------------------------
function a:CHAT_MSG_WHISPER(...)
--------------------------------
  local a1,a2,_,_,_,a6,_,_,_,_,a11,a12 = Filter("CHAT_MSG_WHISPER", ...)
  if a2 and a6 ~= "GM" then
    a:IncomingMessage(a2, a1, a6, nil, a11, a12)
    FlashClientIcon();
  end
end
-----------------------------------
function a:CHAT_MSG_BN_WHISPER(...)  -- battle.net incoming whisper
-----------------------------------
  local a1,a2,_,_,_,a6,_,_,_,_,a11,a12,a13 = Filter("CHAT_MSG_BN_WHISPER", ...)
  if a2 then
    a:IncomingMessage(a2, a1, a6, nil, a11, a12, a13)
    FlashClientIcon();
  end
end
---------------------------------------
function a:CHAT_MSG_WHISPER_INFORM(...)
---------------------------------------
  local a1, a2, _, _, _, a6 = Filter("CHAT_MSG_WHISPER_INFORM", ...)
  -- if a2 and (not GMChatFrame_IsGM or not GMChatFrame_IsGM(a2)) then  -- don't handle GM whispers
  if not a2 or a6 ~= "GM" then  -- don't handle GM whispers (new version)
    a:OutgoingMessage(a2, a1)
  end
end
------------------------------------------
function a:CHAT_MSG_BN_WHISPER_INFORM(...)  -- battle.net outgoing whisper
------------------------------------------
  local a1,a2,_,_,_,_,_,_,_,_,_,_,a13 = Filter("CHAT_MSG_BN_WHISPER_INFORM", ...)
  if a2 then
    a:OutgoingMessage(a2, a1, a13)
  end
end
-------------------------------
function a:CHAT_MSG_AFK(a1, a2)
-------------------------------
  a:IncomingMessage(a2, a2.." is AFK: "..a1, nil, 2)
end
-------------------------------
function a:CHAT_MSG_DND(a1, a2)
-------------------------------
  a:IncomingMessage(a2, a2.." is DND: "..a1, nil, 3)
end
----------------------------------
function a:CHAT_MSG_IGNORED(_, a2)
----------------------------------
  a:IncomingMessage(a2, a2.." is ignoring you.", nil, 4)
end

-- parse some important system messages when chatting to someone
local parstrings
function a:CHAT_MSG_SYSTEM(text)
  if not taborder[1] or not text then return end
  if not parstrings then
    parstrings = {
      "|Hplayer:(.+)|h%[(.+)%]|h(.+)", ERR_FRIEND_OFFLINE_S,
      JOINED_PARTY, LEFT_PARTY, ERR_DECLINE_GROUP_S,
      ERR_RAID_MEMBER_ADDED_S, ERR_RAID_MEMBER_REMOVED_S,
      ERR_GUILD_JOIN_S, ERR_GUILD_DECLINE_S, ERR_GUILD_LEAVE_S,
      ERR_PETITION_DECLINED_S, ERR_PETITION_SIGNED_S,
    }
    for index, s in ipairs(parstrings) do
      parstrings[index] = gsub(s, "%%s", "(.+)")
    end
  end
  for index, s in ipairs(parstrings) do
    local name = strmatch(text, s)
    if name then
      return a:IncomingMessage(name, text, nil, 1)
    end
  end
end
function a:CHAT_MSG_TEXT_EMOTE(emote, sender)
  if taborder[1] and strfind(emote, " you") then
    a:IncomingMessage(sender, emote, nil, 1)
  end
end


--------------------------------------
--- TAB ORGANIZATION
local function UpdateTabOrder(id)  -- update tab order and set positions
  if not db.enabletabs then return end
  currenttab = id or currenttab or 1
  base[1].tab = currenttab
  local n = #taborder + 0.4
  local tabsize = (db.width - (2*n + 48)) / n
  local i = 0
  for _, tid in ipairs(taborder) do
    i = i + 1
    local t = tabs[tid]
    t:SetPoint("TOPLEFT", base[1], "TOPLEFT", ((i-1)*tabsize) + (2*i) + 8, -6)
    if tid == currenttab then
      if not t:GetParent().mini then
        t.mininew = 0
        t.text:SetText(t.name)
        t.msg:Show()
      end
      t:SetBackdropColor(0, 0, 0, 0)
      t.text:SetTextColor(t.text.r or 1, t.text.g or 1, t.text.b or 1, 1)
      i = i + 0.4 -- makes active tab 40% wider
    else
      t.msg:Hide()
      t:SetBackdropColor(0.7, 0.7, 0.7, 0.7)
      t.text:SetTextColor(0.8, 0.8, 0.8, 0.8)
    end
    t:SetPoint("BOTTOMRIGHT", base[1], "TOPLEFT", (i*tabsize) + (2*i) + 8, -20)
  end
  if #taborder < 1 then
    CloseWindow(tabs[1])
  end
end
local function RemoveTab(id, activeid)  -- remove a tab and reorganize
  if not id then return end
  for index, tid in pairs(taborder) do
    if tid == id or id == "a" then
      local tab = tabs[tid]
      usedtabs[tab.name] = nil
      tab:Hide()
      tab.text.r, tab.text.g, tab.text.b = nil, nil, nil
      tremove(taborder, index)
      if IsControlKeyDown() then
        svar[tabs[(id == "a" and activeid) or tid].name] = nil
      end
    end
  end
  currenttab = (id == currenttab and taborder[1]) or currenttab
  if attached == id and cfeb:IsShown() then
    ChatEdit_DeactivateChat(cfeb)
  end
  UpdateTabOrder()
end


--------------------------------------
--- EDITBOX
local function ResetEditBox()  -- reset the editbox to it's normal position
  if not attached then return end
  cfeb:ClearAllPoints()
  cfeb:SetParent(l_rt)
  cfeb:SetPoint(l_p, l_rt, l_rp, l_x, l_y)
  if r_p then cfeb:SetPoint(r_p, r_rt, r_rp, r_x, r_y) end
  attached = nil
end
local skipupdate
local sw = _G.SLASH_SMART_WHISPER1.." "
local function AttachEditBox(id, skiptext, skipset)  -- attach the main chat editbox to the current person you're whispering
  local tab = tabs[id]
  if not tab:IsShown() then return end
  if not db.noattach then
    local lastTell, lastTellType = ChatEdit_GetLastTellTarget();
    local lastTold, lastToldType = ChatEdit_GetLastToldTarget();

    if lastTell then
      cfeb:SetAttribute("chatType", lastTellType)
      cfeb:SetAttribute("tellTarget", tab.name)
    elseif lastTold then
      cfeb:SetAttribute("chatType", lastToldType)
      cfeb:SetAttribute("tellTarget", tab.name)
    end

    ChatEdit_ActivateChat(cfeb)
    cfeb.setText = 1
    cfeb.text = sw..tab.name.." "
    ChatEdit_UpdateHeader(cfeb)
    ChatEdit_ParseText(cfeb, 0)
    if not attached then
      l_p, l_rt, l_rp, l_x, l_y = cfeb:GetPoint(1)
      r_p, r_rt, r_rp, r_x, r_y = cfeb:GetPoint(2)
    end
    cfeb:SetParent(tab:GetParent())
    cfeb:ClearAllPoints()
    if db.showtop then
      cfeb:SetPoint("BOTTOMLEFT", tab:GetParent(), "TOPLEFT", 0, -6)
      cfeb:SetPoint("BOTTOMRIGHT", tab:GetParent(), "TOPRIGHT", 0, -6)
    else
      cfeb:SetPoint("TOPLEFT", tab:GetParent(), "BOTTOMLEFT", 0, 6)
      cfeb:SetPoint("TOPRIGHT", tab:GetParent(), "BOTTOMRIGHT", 0, 6)
    end
    attached = id
    cfeb:SetFocus()
  else
    if tab.name and tab.name ~= "" then
      local editBox = ChatEdit_ChooseBoxForSend()
      if not editBox then return end
      local lastTell, lastTellType = ChatEdit_GetLastTellTarget();
      if lastTell then
        editBox:SetAttribute("chatType", lastTellType)
        editBox:SetAttribute("tellTarget", tab.name)
        ChatEdit_UpdateHeader(editBox)
        if editBox ~= ChatEdit_GetActiveWindow() then
          ChatFrame_OpenChat("")
        end
      end
    end
  end
end
local function ToggleEditBox(id, hidediff)
  if not db.noattach and (attached == id or (attached and hidediff)) then
    ChatEdit_DeactivateChat(cfeb)
  elseif not hidediff and id then
    AttachEditBox(id)
  end
end


--------------------------------------
--- MESSAGE HANDLERS
GetWindow = function(name, isSpecial, showmore, battleTag)  -- retrieve window
  local id = usedtabs[name]
  if (not id or not tabs[id] or not tabs[id]:IsShown()) and not isSpecial then
    local t
    for _, tab in ipairs(tabs) do  -- assumes if a window is hidden, it's unused
      if not tab:IsShown() then
        t = tab
        break
      end
    end
    t = t or a:CreateWindow()  -- if no windows are available, make a new one
    if t then  -- still no windows, you probably hit maximum allowed
      t.name = name
      t.lastspecial = nil
      t.tag = nil

      t.msg:Clear()
      t.msg:ScrollToBottom()
      local history = svar[battleTag or name]
      if history then  -- show recent history if available
        local n = #history
        local numlines = (showmore and 50) or 15
        if n > numlines then
          t.msg:AddMessage("**See ..\\WTF \\Account \\<Account Name> \\<Server> \\<Character> \\SavedVariables \\Cellular.lua for more**", 1, 1, 0)
        end
        for i = max(1, n-numlines), n, 1 do
          t.msg:AddMessage(history[i], 0.6, 0.6, 0.6)
        end
        if not a.memchecked and (not db.memcheck or db.memcheck + 21600 < time()) then  -- quick memory check
          db.memcheck = time()
          UpdateAddOnMemoryUsage()
          local mem = GetAddOnMemoryUsage("Cellular")
          if mem and mem > 490 then
            t.msg:AddMessage(format("History usage is high ( +%d KB ). Consider cleaning it.", mem - 85), 0.7, 0.5, 0.5)
          end
        end
        a.memchecked = true
      end
      id = t.id
      usedtabs[name] = id
      tinsert(taborder, id)
      t:GetParent():Show()
      t:Show()
      t.mininew = 0
      t.text:SetText(t.name)
      t.msg:Show()
      t:EnableMouse(db.enabletabs)
      UpdateTabOrder(currenttab or taborder[1])
      if id  and  (db.autominalways or (db.automin and InCombatLockdown()))  and  (not db.enabletabs or #taborder == 1) then
        MinimizeWindow(t:GetParent().Minimize)
      end
    end
  end
  return id
end
do
  local ChatEdit_SetLastTellTarget, GetTime = ChatEdit_SetLastTellTarget, GetTime
  local function HandleHistory(name, dname, text, battleTag)  -- history tracking
    recentw[name] = true
    if not db.history then return end

    local t = svar[battleTag or name]
    if not t then
      svar[battleTag or name] = {}
      t = svar[battleTag or name]
    end
    t[#t + 1] = format("<%s>[%s] %s", date("%m-%d-%y %H:%M"), dname, text)
    if eb and eb:IsShown() and eb.name == name then
      eb.max = #t
    end
  end
  local function HandleWindow(name, special, text, battleTag)  -- window check
    if not name then return end
    local id = GetWindow(name, special, nil, battleTag)
    if not id then
      if not special then
        print(format("|cff88ff88Cellular|r: Max windows reached - [%s] %s", name, text))
      end
      return
    end
    lastwindow = id
    return tabs[id]
  end
  local function addmsg(fmsg, out, form, ...)
    local c = (out and db.outcolor) or db.incolor
    fmsg:AddMessage(format(form, ...), c[1], c[2], c[3], c[4])
  end
  local lastTell = 0
  ------------------------------------------------------------------------
  function a:IncomingMessage(name, text, status, special, cid, guid, isbn)  -- handles the displaying of all incoming whisper messages
  ------------------------------------------------------------------------
    local battleTag, presenceName, _, toonName
    name = gsub(name, "-" .. realmName, "")
    if isbn then
      -- _, presenceName, battleTag, _, toonName = C_BattleNet.GetAccountInfoByID(isbn)
      local infoBN = C_BattleNet.GetAccountInfoByID(isbn)
			if infoBN then
				battleTag = infoBN.battleTag
				presenceName = infoBN.accountName
				toonName = infoBN.characterName
			end
    end
    local f = HandleWindow(name, special, text, battleTag)
    if not f then return end

    local ctime = GetTime()
    if special then  -- handle special messages (system, afk, dnd, etc) and reduces the spam
      if special == 1 then
        f.msg:AddMessage(format("[%s] %s", date("%H:%M:%S"), text), 1, 1, 0)
      else
        if not f.lastspecial or ctime > f.lastspecial + 90 or f.tag ~= special then
          f.lastspecial = ctime
          f.tag = special
          f.msg:AddMessage(format("[%s] %s", date("%H:%M:%S"), text), 1, 0, 0)
        end
      end
      return
    end

    -- handles the status flags (GM, AFK, DND)
    status, cid = status or "", cid or ""
    if status ~= "" then
      status = ((status == "GM" or status == "DEV") and " |TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:0:2:0:-3|t") or format(" (%s)", status)
    end
    local tname = gsub(name, "-(.+)", "")  -- remove realm name
    if isbn then
      if db.showname and db.showtime then  -- finally add the message to whisper window
        addmsg(f.msg, nil, "|HBNplayer:%s:%s:%s:BN_WHISPER:%s|h[%s %s|h%s] %s", name, isbn, cid, name, gsub(date("%I:%M:%S"), "^0", ""), tname, status, text)
      elseif db.showtime then
        addmsg(f.msg, nil, "|HBNplayer:%s:%s:%s:BN_WHISPER:%s|h[%s|h%s] %s", name, isbn, cid, name, gsub(date("%I:%M:%S"), "^0", ""), status, text)
      elseif db.showname then
        addmsg(f.msg, nil, "|HBNplayer:%s:%s:%s:BN_WHISPER:%s|h[%s|h%s] %s", name, isbn, cid, name, tname, status, text)
      else
        addmsg(f.msg, nil, "|HBNplayer:%s:%s:%s:BN_WHISPER:%s|h[>|h%s] %s", name, isbn, cid, name, status, text)
      end
    else
      if db.showname and db.showtime then  -- finally add the message to whisper window
        addmsg(f.msg, nil, "|Hplayer:%s:%s:WHISPER:%s|h[%s %s|h%s] %s", name, cid, strupper(name), gsub(date("%I:%M:%S"), "^0", ""), tname, status, text)
      elseif db.showtime then
        addmsg(f.msg, nil, "|Hplayer:%s:%s:WHISPER:%s|h[%s|h%s] %s", name, cid, strupper(name), gsub(date("%I:%M:%S"), "^0", ""), status, text)
      elseif db.showname then
        addmsg(f.msg, nil, "|Hplayer:%s:%s:WHISPER:%s|h[%s|h%s] %s", name, cid, strupper(name), tname, status, text)
      else
        addmsg(f.msg, nil, "|Hplayer:%s:%s:WHISPER:%s|h[>|h%s] %s", name, cid, strupper(name), status, text)
      end
    end

    local r, g, b
    if ChatTypeInfo.WHISPER and ChatTypeInfo.WHISPER.colorNameByClass and guid and guid ~= "" then
      local _, englishClass, _, _, _ = GetPlayerInfoByGUID(guid)
      local cc = englishClass and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[englishClass]
      r, g, b = cc and cc.r or 1, cc and cc.g or 1, cc and cc.b or 1
      f.text.r, f.text.g, f.text.b = r, g, b
    else
      f.text.r, f.text.g, f.text.b = nil, nil, nil
    end
    if not f.msg:IsVisible() then  -- update number of whispers received if minimized
      f.mininew = f.mininew + 1
      r, g, b = 0.8, 0, 0
      f.text:SetFormattedText("%s (%d)", f.name, f.mininew)
    end
    f.text:SetTextColor(r or 1, g or 1, b or 1, 1)

    ChatEdit_SetLastTellTarget(name, isbn and "BN_WHISPER" or "WHISPER")
    HandleHistory(name, tname, text, battleTag)  -- add entry to history

    if ctime > lastTell + 2 then  -- support for whisper sound alerts
      if a.pratloaded and Prat.Addon:GetModule("Sounds", true) then
        a.PLAYERLINK = name
        Prat.Addon:GetModule("Sounds", true):Prat_PostAddMessage(nil, a, nil, "CHAT_MSG_WHISPER")
      elseif ChatSounds_InitConfig then
        ChatSounds_PlaySound(ChatSounds_Config[ChatSounds_Player].Incoming["WHISPER"])
      elseif not ChatSoundsDB then
        --PlaySound("TellMessage")
      end
      lastTell = ctime
    end
  end
  --------------------------------------------
  function a:OutgoingMessage(name, text, isbn)  -- handles the displaying of all outgoing whisper messages
  --------------------------------------------
    local battleTag, presenceName, _, toonName
    name = gsub(name, "-" .. realmName, "")
    if isbn then
      -- _, presenceName, battleTag, _, toonName = C_BattleNet.GetAccountInfoByID(isbn)
      local infoBN = C_BattleNet.GetAccountInfoByID(isbn)
			if infoBN then
				battleTag = infoBN.battleTag
				presenceName = infoBN.accountName
				toonName = infoBN.characterName
			end
    end
    local f = HandleWindow(name, nil, text, battleTag)
    if not f then return end
    if db.showname and db.showtime then
      addmsg(f.msg, true, "[%s %s] %s", gsub(date("%I:%M:%S"), "^0", ""), you, text)
    elseif db.showtime then
      addmsg(f.msg, true, "[%s] %s", gsub(date("%I:%M:%S"), "^0", ""), text)
    elseif db.showname then
      addmsg(f.msg, true, "[%s] %s", you, text)
    else
      addmsg(f.msg, true, "[<] %s", text)
    end

    HandleHistory(name, you, text, battleTag)
    if a.pratloaded and Prat.Addon:GetModule("Sounds", true) then
      a.PLAYERLINK = you
      Prat.Addon:GetModule("Sounds", true):Prat_PostAddMessage(nil, a, nil, "CHAT_MSG_WHISPER_INFORM")
    elseif ChatSounds_InitConfig then
      ChatSounds_PlaySound(ChatSounds_Config[ChatSounds_Player].Outgoing["WHISPER"])
    end
  end
end


--------------------------------------
--- FRAME/VISUAL STUFF

-- button functions
local buttons
local function ApplyFont(t, font, fontsize, fontstyle)
  local flags = ""
  if not fontstyle then
    fontstyle = "OUTLINE,MONOCHROME"
  end

  if fontstyle == "Shadow" then
    t:SetFont(smed:Fetch("font", font), fontsize, "")
    t:SetShadowColor(0, 0, 0, 0.7)
    t:SetShadowOffset(1, -1)
  else
    if fontstyle ~= "None" then
      flags = gsub(fontstyle, "%s+", "")
    end
    t:SetFont(smed:Fetch("font", font), fontsize, flags)
    t:SetShadowOffset(0, 0)
  end
end
do
  local function Who(this)
    C_FriendList.SendWho(tabs[this:GetParent().tab].name)
  end
  local function Busy(this)
    local bm = db.busymessage
    if bm and bm ~= "" then
      C_ChatInfo.SendChatMessage(bm, "WHISPER", nil, tabs[this:GetParent().tab].name)
    end
  end
  local function Social(this)
    if not IsShiftKeyDown() then return end
    local b, n = this.text, tabs[this:GetParent().tab].name
    if b == _G.CHAT_INVITE_SEND then
      InviteUnit(n)
    elseif b == _G.ADD_FRIEND then
      C_FriendList.AddFriend(n)
    elseif b == _G.IGNORE_PLAYER then
      C_FriendList.AddIgnore(n)
    end
  end
  local function Scroll(this)
    local f = tabs[this:GetParent().tab].msg
    f[this.text](f)
  end
  MinimizeWindow = function(this)
    local p = this:GetParent()
    local t = tabs[p.tab]
    if not p.mini then
      p.mini = 1
      p:SetHeight(28)
      for b, k in pairs(buttons) do
        if not k.dontmin then
          p[b]:Hide()
        end
      end
      p.resizer:Hide()
      p.mininew = 0
      t.msg:Hide()
    else
      p.mini = nil
      p:SetHeight(db.height)
      for b, k in pairs(buttons) do
        if db.showside or not k.side then
          p[b]:Show()
        end
      end
      p.resizer:Show()
      t.mininew = 0
      t.text:SetText(t.name)
      t.text:SetTextColor(t.text.r or 1, t.text.g or 1, t.text.b or 1, 1)
      t.msg:Show()
    end
    if eb and eb:IsShown() then eb:Hide() end
  end
  CloseWindow = function(this)
    local p = this:GetParent()
    if p.mini then MinimizeWindow(p.Minimize) end
    if attached == p.tab then ChatEdit_DeactivateChat(cfeb) end
    if eb and eb:IsShown() then eb:Hide() end
    if db.enabletabs then
      for i = 1, #taborder, 1 do
        RemoveTab("a", p.tab)
      end
      currenttab = 1
    else
      RemoveTab(p.tab)
    end
    p:Hide()
  end
  local EButtonClick
  local function CreateEButton(texture, left, close)
    local f = CreateFrame("Button", nil, eb)
    f:SetWidth(16)
    f:SetHeight(16)
    f:SetNormalTexture(texture)
    f:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    EButtonClick = EButtonClick or function(this)
      local p = this:GetParent()
      p.i = (this.back and max(p.i-1, 1)) or min(p.max, p.i + 1)
      p:SetText(svar[p.name][p.i])
      p:HighlightText()
      p:SetFocus()
    end
    f:SetScript("OnClick", (not close and EButtonClick) or function(this) this:GetParent():Hide() end)
    f:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", -1, 0)
    return f
  end
  local function Copy(this)
    local p = this:GetParent()
    local t = tabs[p.tab]
    local h = svar[t.name]
    if not h or not h[1] then return end
    if not eb then
      eb = CreateFrame("EditBox", "CellularEB", UIParent)
      ApplyFont(eb, db.fontmsg, db.fontsize, db.fontmsgstyle)
      eb:SetMaxLetters(600)
      eb.back = CreateEButton("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", eb)
      eb.forward = CreateEButton("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", eb.back)
      eb.close = CreateEButton("Interface\\Buttons\\UI-Panel-MinimizeButton-Up", eb.forward, true)
      eb.back.back = true
      eb:Hide()
      eb:SetHeight(16)
      eb:SetScript("OnEscapePressed", function(this) this:Hide() this:ClearFocus() end)
      --The line below is temporarily commented out.
      --eb:SetScript("OnEditFocusLost", function(this) this:Hide() end)
    end
    if eb:IsShown() and eb.name == t.name then
      eb:Hide()
    else
      eb.name = t.name
      eb.max = #h
      eb.i = eb.max
      eb:SetText(h[eb.i])
      eb:ClearAllPoints()
      if db.showtop then
        eb:SetPoint("LEFT", p, "BOTTOMLEFT", -4, -5)
        eb:SetPoint("RIGHT", p, "BOTTOMRIGHT", -40, -5)
      else
        eb:SetPoint("LEFT", p, "TOPLEFT", -4, 5)
        eb:SetPoint("RIGHT", p, "TOPRIGHT", -40, 5)
      end
      eb:Show()
      eb:HighlightText()
      eb:SetFocus()
    end
  end

  buttons = {
    [_G.WHO] = { p="TOPLEFT", x=6, y=-22, tt=1, path="Interface\\Icons\\INV_Misc_QuestionMark", func=Who, side=true, },
    ["\"I'm Busy!\""] = { p="TOPLEFT", x=6, y=-42, tt=1, path="Interface\\Icons\\Spell_Holy_Silence", func=Busy, side=true, },
    [_G.CHAT_INVITE_SEND] = { p="TOPLEFT", x=6, y=-59, tt=2, path="Interface\\Icons\\Spell_Holy_PrayerofSpirit", func=Social, side=true, },
    [_G.ADD_FRIEND] = { p="TOPLEFT", x=6, y=-76, tt=2, path="Interface\\Icons\\Spell_ChargePositive", func=Social, side=true, },
    [_G.IGNORE_PLAYER] = { p="TOPLEFT", x=6, y=-95, tt=2, path="Interface\\Icons\\Spell_ChargeNegative", func=Social, side=true, },
    [_G.CALENDAR_COPY_EVENT] = { p="BOTTOMLEFT", x=6, y=6, tt=3, path="Interface\\Icons\\INV_Scroll_01", func=Copy, side=true, },
    ScrollUp = { p="BOTTOMRIGHT", x=-6, y=42, path="Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up", func=Scroll, },
    ScrollDown = { p="BOTTOMRIGHT", x=-6, y=26, path="Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up", func=Scroll, },
    ScrollToBottom = { p="BOTTOMRIGHT", x=-6, y=10, path="Interface\\ChatFrame\\UI-ChatIcon-ScrollEnd-Up", func=Scroll, },
    [_G.CLOSE] = { p="TOPRIGHT", x=-6, y=-6, tt=1, tpl="UIPanelButtonTemplate", func=CloseWindow, bt = "x", dontmin = true, },
    Minimize = { p="TOPRIGHT", x=-22, y=-6, tt=1, tpl="UIPanelButtonTemplate", func=MinimizeWindow, bt = "-", dontmin = true, },
  }
end

-- backdrop table
local bdt = { tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4, }, }
local bdt2 = { bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, }
local function UpdateBaseVars(f)  -- updates main window's variable settings
  bdt.bgFile = smed:Fetch(db.bglist or "background", db.bg)
    or smed:Fetch("background", db.bg)
    or smed:Fetch("statusbar", db.bg)
    or "Interface\\Tooltips\\UI-Tooltip-Background"
  bdt.tile = (db.bg == "Tooltip")
  bdt.edgeFile = smed:Fetch("border", db.border)
  f:SetBackdrop(nil)
  f:SetBackdrop(bdt)
  f:SetBackdropColor(unpack(db.bgcolor))
  f:SetBackdropBorderColor(unpack(db.bordercolor))
  if db.strata then f:SetFrameStrata(db.strata) end
  for b, k in pairs(buttons) do
    if k.side and db.showside then
      f[b]:Show()
    elseif k.side then
      f[b]:Hide()
    end
  end
end
local function UpdateTabVars(f)  -- updates tab's variable settings
  ApplyFont(f.text, db.fonttitle, 12, db.fonttitlestyle)
  ApplyFont(f.msg, db.fontmsg, db.fontsize, db.fontmsgstyle)
  f.msg:SetFading(db.fade)
  f.msg:SetPoint("TOPLEFT", f:GetParent(), "TOPLEFT", db.showside and 24 or 8, -18)
  f.msg:SetPoint("BOTTOMRIGHT", f:GetParent(), "BOTTOMRIGHT", -20, 8)
end
local function UpdateSizes(reset)
  if reset then
    db.width, db.height = 340, 160
  end
  for _, f in pairs(base) do
    f:SetWidth(db.width)
    f:SetHeight(db.height)
  end
end
local function UpdatePosition(this, reset)
  db.pos[this.id] = db.pos[this.id] or {}
  local t = db.pos[this.id]
  if reset then
    this:ClearAllPoints()
    this:SetPoint("TOPLEFT", UIParent, "CENTER", (this.id - 1) * 20 + 100, -(this.id - 1) * 20)
    t.p, t.rp, t.x, t.y = "TOPLEFT", "BOTTOMLEFT", this:GetLeft(), this:GetTop()
  elseif (this:GetTop() - db.height/2) > (GetScreenHeight()/2) then
    t.p, t.rp, t.x, t.y = "TOPLEFT", "BOTTOMLEFT", this:GetLeft(), this:GetTop()
  else
    t.p, t.rp, t.x, t.y = "BOTTOMLEFT", "BOTTOMLEFT", this:GetLeft(), this:GetBottom()
  end
  this:ClearAllPoints()
  this:SetPoint(t.p, UIParent, t.rp, t.x, t.y)
end
do  -- button creation and layout handler
  local gtt = GameTooltip
  local function BOnEnter(this)
    gtt:SetOwner(this, "ANCHOR_BOTTOMLEFT")
    gtt:SetText(this.text, 1, 1, 1)
    if this.tt then
      if this.tt == 2 then
        gtt:AddLine(" Shift-click to execute", 0, 1, 0)
      elseif not db.history and this.tt == 3 then
        gtt:AddLine(" History must be enabled", 0, 1, 0)
      end
    end
    gtt:Show()
  end
  local function GttHide() gtt:Hide() end
  local function BDown(this) this:SetAlpha(0.3) end
  local function BUp(this) this:SetAlpha(0.6) end
  local function ResizeStart(this)
    if not IsShiftKeyDown() then
      if not a.shiftsaid2 then
        print("|cff00ff00Cellular|r: Hold shift and drag to resize.")
        a.shiftsaid2 = true
      end
      return
    end
    this:GetParent():StartSizing("BOTTOMRIGHT")
  end
  local function ResizeEnd(this)
    local p = this:GetParent()
    p:StopMovingOrSizing()
    db.height, db.width = floor(p:GetHeight() + 0.5), floor(p:GetWidth() + 0.5)
    UpdateSizes()
    UpdateTabOrder()
    UpdatePosition(p)
  end
  local function DragStart(this)
    if not IsShiftKeyDown() then
      if not a.shiftsaid then
        print("|cff00ff00Cellular|r: Hold shift and drag to move.")
        a.shiftsaid = true
      end
      return
    end
    this = this.msg and this:GetParent() or this
    this:StartMoving()
  end
  local function DragStop(this)
    this = this.msg and this:GetParent() or this
    this:StopMovingOrSizing()
    UpdatePosition(this)
  end
  local function Wheel(this, a1)
    if not a1 then return end
    local t = tabs[this.tab].msg
    if a1 > 0 then
      t:ScrollUp()
      t:ScrollUp()
    else
      t:ScrollDown()
      t:ScrollDown()
    end
  end
  local function MainClick(this, a1)
    if a1 == "RightButton" then
      ShowOptions()
    else
      ToggleEditBox(this.tab)
    end
  end
  local function TabOnClick(this, a1)
    if a1 == "LeftButton" then
      local id = this.id
      ToggleEditBox(id, currenttab ~= id)
      if currenttab ~= id then
        UpdateTabOrder(id)
      end
    elseif a1 == "RightButton" then
      ShowOptions(nil, this.id)
    elseif a1 == "MiddleButton" then
      RemoveTab(this.id)
    end
  end
  local function TabOnEnter(this)
    gtt:SetOwner(this, "ANCHOR_TOPLEFT")
    gtt:SetText(this.text:GetText(), 1, 1, 1)
    gtt:Show()
  end
  -------------------------
  function a:CreateBase(id)
  -------------------------
    if base[id] then return base[id] end

    local f = CreateFrame("Button", "CellularWindow"..id, a, BackdropTemplateMixin and "BackdropTemplate")
    f:SetWidth(db.width)
    f:SetHeight(db.height)
    local pos = db.pos[id]
    if pos then
      f:SetPoint(pos.p or "TOPLEFT", UIParent, pos.rp or "TOPLEFT", pos.x, pos.y)
    else
      f:SetPoint("TOPLEFT", UIParent, "CENTER", (id-1)*20 + 100, -(id-1)*20)
    end
    f.id = id
    f:SetMovable(true)
    f:SetResizable(true)
    f:EnableMouseWheel(true)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", DragStart)
    f:SetScript("OnDragStop", DragStop)
    f:SetScript("OnClick", MainClick)
    f:SetScript("OnMouseWheel", Wheel)
    f:SetClampedToScreen(true)
    f:SetClampRectInsets(10, -10, -10, 10)

    -- resizing button
    f:SetResizeBounds(120, 80)
    local resize = CreateFrame("Button", nil, f, "UIPanelButtonGrayTemplate")
    resize:SetWidth(8)
    resize:SetHeight(8)
    resize:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resize:SetScript("OnMouseDown", ResizeStart)
    resize:SetScript("OnMouseUp", ResizeEnd)
    if ChatFrame1ResizeButton then
      resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
      resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
      resize:SetWidth(14)
      resize:SetHeight(14)
    end
    f.resizer = resize

    -- all the buttons
    for bn, t in pairs(buttons) do
      local b = CreateFrame("Button", nil, f, t.tpl)
      b:SetWidth(16)
      b:SetHeight(16)
      b.text = bn
      b:SetPoint(t.p, f, t.p, t.x, t.y)
      if t.path then
        b:SetNormalTexture(t.path)
        b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
      end
      b:SetScript("OnMouseDown", BDown)
      b:SetScript("OnMouseUp", BUp)
      b:SetScript("OnClick", t.func)
      if t.tt then
        b:SetScript("OnEnter", BOnEnter)
        b:SetScript("OnLeave", GttHide)
        b.tt = t.tt
      end
      b:SetText(t.bt)
      b:SetAlpha(0.6)
      f[bn] = b
    end

    UpdateBaseVars(f)
    UpdatePosition(f)
    base[id] = f
    return f
  end
  --------------------------------
  function a:CreateTab(id, parent)
  --------------------------------
    if tabs[id] then return tabs[id] end

    local t = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -6)
    t:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", -8, -20)
    t:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    t:RegisterForDrag("LeftButton")
    t:SetScript("OnClick", TabOnClick)
    t:SetScript("OnEnter", TabOnEnter)
    t:SetScript("OnLeave", GttHide)
    t:SetScript("OnDragStart", DragStart)
    t:SetScript("OnDragStop", DragStop)
    t:SetBackdrop(bdt2)
    t:SetBackdropColor(0,0,0,0)
    t.id = id

    -- button text (not needed if someone tells me how to justify button text)
    t.text = t:CreateFontString(nil, "ARTWORK")
    t.text:SetJustifyH("LEFT")
    t.text:SetJustifyV("TOP")
    t.text:SetAllPoints(t)

    -- scrolling text
    local m = CreateFrame("ScrollingMessageFrame", nil, t)
    m:SetHyperlinksEnabled(true)
    m:UnregisterAllEvents()
    m:SetJustifyH("LEFT")
    m:SetTimeVisible(120)
    m:SetMaxLines(100)
    m:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
    m:SetScript("OnHyperlinkEnter", ChatFrame1:GetScript("OnHyperlinkEnter"))
    m:SetScript("OnHyperlinkLeave", GttHide)
    m:Hide()
    t.msg = m

    UpdateTabVars(t)
    tabs[id] = t
    return t
  end
  -------------------------
  function a:CreateWindow()
  -------------------------
    if nwin >= db.maxwindows then return end
    nwin = nwin + 1
    if nwin == 1 then  -- setup system events and hooks
      a:RegisterEvent("CHAT_MSG_SYSTEM")
      a:RegisterEvent("CHAT_MSG_TEXT_EMOTE")

      hooksecurefunc("ChatFrame_ReplyTell", function(chatframe)
        local lastTell = ChatEdit_GetLastTellTarget()
        if not lastTell or lastTell == "" then return end
        local id = GetWindow(lastTell)
        if id then
          AttachEditBox(id)
          UpdateTabOrder(id)
        end
      end)
      hooksecurefunc("ChatEdit_DeactivateChat", ResetEditBox)
    end
    if not db.enabletabs or (db.enabletabs and nwin == 1) then  -- create full windows
      local f = a:CreateBase(nwin)
      f.tab = nwin
      return a:CreateTab(nwin, f)
    else  -- create tabs
      return a:CreateTab(nwin, base[1])
    end
  end
end

local CellularDD
local info, list = { }, { }
local offsetvalue, offsetcount, lastb, showid
ShowOptions = function(a1, id)
  showid = type(id) == "number" and id
  if not CellularDD then
    CellularDD = CreateFrame("Frame", "CellularDD", Cellular)
    CellularDD.displayMode = "MENU"

    hooksecurefunc("ToggleDropDownMenu", function(...) lastb = select(8, ...) end)
    local function UpdateSettings()
      Cellular:SetAlpha(db.alpha)
      for _, f in pairs(base) do
        UpdateBaseVars(f)
      end
      for _, t in pairs(tabs) do
        UpdateTabVars(t)
      end
    end
    local function HideCheck(b)
      if b and b.GetName and _G[b:GetName().."Check"] then
        _G[b:GetName().."Check"]:Hide()
      end
    end
    local function CloseMenu(b)
      if not b or not b:GetParent() then return end
      CloseDropDownMenus(b:GetParent():GetID())
    end
    local function RefreshMenu(b)
      local tb = _G[gsub(lastb:GetName(), "ExpandArrow", "")]
      CloseMenu(b)
      ToggleDropDownMenu(b:GetParent():GetID(), tb.value, nil, nil, nil, nil, tb.menuList, tb)
    end
    local function Exec(b, k, value)
      HideCheck(b)
      if (k == "less" or k == "more") and lastb then
        local off = (k == "less" and -8) or 8
        if offsetvalue == value then
          offsetcount = offsetcount + off
        else
          offsetvalue, offsetcount = value, off
        end
        RefreshMenu(b)
      elseif k == "showtab" then
        CloseMenu(b)
        ToggleEditBox(value, currenttab ~= value)
        if currenttab ~= value then
          UpdateTabOrder(value)
        end
      elseif k == "removetab" then
        CloseMenu(b)
        RemoveTab(value)
      elseif k == "showoptions" then
        CloseMenu(b)
        ShowOptions()
      elseif k == "resetsizes" then
        UpdateSizes(true)
        for id, f in pairs(base) do
          UpdatePosition(f, true)
        end
      elseif k == "movehelp" then
        print("|cff00ff00Cellular|r: Hold shift and drag empty space to move or bottom-right corner to resize windows.")
      elseif k == "busymessage" then
        StaticPopupDialogs["CellularBusy"] = StaticPopupDialogs["CellularBusy"] or {
          text = "Set your busy message.",
          button1 = ACCEPT, button2 = CANCEL,
          hasEditBox = 1, maxLetters = 60, editBoxWidth = 350,
          OnAccept = function(this)
            db.busymessage = this.editBox:GetText() or ""
          end,
          EditBoxOnEnterPressed = function(this)
            db.busymessage = this:GetParent().editBox:GetText() or ""
            this:GetParent():Hide()
          end,
          EditBoxOnEscapePressed = function(this)
            this:GetParent():Hide()
          end,
          OnShow = function(this)
            this.editBox:SetText(db.busymessage or "")
            this.editBox:SetFocus()
          end,
          OnHide = function(this)
            this.editBox:SetText("")
          end,
          timeout = 0, exclusive = 1, whileDead = 1, hideOnEscape = 1,
        }
        StaticPopup_Show("CellularBusy")
      elseif k == "clearall" and IsShiftKeyDown() then
        for name in pairs(svar) do
          svar[name] = nil
        end
        print("|cff00ff00Cellular|r: History cleared.")
      elseif k == "clearold" and IsShiftKeyDown() then
        local cdays = tonumber(date("%y")) * 365.25 + tonumber(date("%m")) * 30.4 + tonumber(date("%d"))
        local cleared = 0
        for name, t in pairs(svar) do
          while true do
            if #t < 1 then
              svar[name] = nil
              break
            end
            local m, d, y = strmatch(t[1], "<(%d+)-(%d+)-(%d+) ")
            if m and d and y then
              local days = tonumber(y) * 365.25 + tonumber(m) * 30.4 + tonumber(d)
              if days + 42 < cdays then
                cleared = cleared + 1
                tremove(t, 1)
              else
                break
              end
            else
              break
            end
          end
        end
        print("|cff00ff00Cellular|r: "..cleared.." history entries removed.")
      end
    end
    local function Set(b, k)
      if not k then return end
      db[k] = not db[k]
      if k == "enabletabs" then
        if nwin < 1 then return end
        local v = db.enabletabs
        for i, tab in pairs(tabs) do
          local p = base[(v and 1) or i] or a:CreateBase((v and 1) or i)
          tab:GetParent():Hide()
          tab:SetParent(p)
          tab:EnableMouse(db.enabletabs)
          tab.msg:SetPoint("TOPLEFT", p, "TOPLEFT", db.showside and 24 or 8, -18)
          tab.msg:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -20, 8)
          if not v then
            if not tab:GetParent().mini then
              tab.mininew = 0
              tab.text:SetText(tab.name)
              tab.msg:Show()
            end
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", p, "TOPLEFT", 8, -6)
            tab:SetPoint("BOTTOMRIGHT", p, "TOPRIGHT", -8, -20)
            tab:SetBackdropColor(0, 0, 0, 0)
            tab.text:SetTextColor(tab.text.r or 1, tab.text.g or 1, tab.text.b or 1, 1)
            p.tab = tab.id
          end
          tab:GetParent():Hide()
        end
        for _, id in pairs(usedtabs) do
          tabs[id]:GetParent():Show()
          tabs[id]:Show()
        end
        UpdateTabOrder(lastwindow or taborder[1])
        ChatEdit_DeactivateChat(cfeb)
      elseif k == "char" or k == "chatshow" or k == "nobn" then
        print("|cff00ff00Cellular|r: This setting requires a reload and will effect all characters.")
      else
        UpdateSettings()
      end
    end
    local function SetSelect(b, a1)
      HideCheck(b)
      if a1 == "show" or a1 == "recent" then
        GetWindow(b.value, nil, true)
      elseif a1 == "clear" then
        if IsShiftKeyDown() then
          svar[b.value] = nil
          RefreshMenu(b)
        end
      else
        db[a1] = tonumber(b.value) or b.value
        if a1 == "bglist" then
          local bg = db.bg and smed:Fetch(db.bglist, db.bg)
          if not bg then
            local t = smed:List(db.bglist)
            db.bg = t and t[1] or "Tooltip"
          end
        end
        local level, num = strmatch(b:GetName(), "DropDownList(%d+)Button(%d+)")
        level, num = tonumber(level) or 0, tonumber(num) or 0
        for i = 1, UIDROPDOWNMENU_MAXBUTTONS, 1 do
          local b = _G["DropDownList"..level.."Button"..i.."Check"]
          if b then
            b[i == num and "Show" or "Hide"](b)
          end
        end
        UpdateSettings()
      end
    end
    local function SetColor(a1)
      local dbc = db[UIDROPDOWNMENU_MENU_VALUE]
      if not dbc then return end
      if a1 then
        local pv = ColorPickerFrame.previousValues
        dbc[1], dbc[2], dbc[3], dbc[4] = pv.r, pv.g, pv.b, pv.opacity
      else
        dbc[1], dbc[2], dbc[3] = ColorPickerFrame:GetColorRGB()
        local opacity = ColorPickerFrame.opacity or 0
        if ColorPickerFrame.GetColorAlpha then
          opacity = ColorPickerFrame:GetColorAlpha()
        end
        if OpacitySliderFrame and OpacitySliderFrame.GetValue then
          opacity = OpacitySliderFrame:GetValue()
        end
        dbc[4] = opacity
      end
      UpdateSettings()
    end
    local function AddButton(lvl, text, keepshown)
      info.text = text
      info.keepShownOnClick = keepshown
      UIDropDownMenu_AddButton(info, lvl)
      wipe(info)
    end
    local function AddToggle(lvl, text, value)
      info.arg1 = value
      info.func = Set
      info.checked = db[value]
      info.isNotRadio = true
      AddButton(lvl, text, 1)
    end
    local function AddExecute(lvl, text, arg1, arg2)
      info.arg1 = arg1
      info.arg2 = arg2
      info.func = Exec
      info.notCheckable = 1
      AddButton(lvl, text, 1)
    end
    local function AddColor(lvl, text, value)
      local dbc = db[value]
      if not dbc then return end
      info.hasColorSwatch = true
      info.hasOpacity = 1
      info.r, info.g, info.b, info.opacity = dbc[1], dbc[2], dbc[3], dbc[4] or 1
      info.swatchFunc, info.opacityFunc, info.cancelFunc = SetColor, SetColor, SetColor
      info.value = value
      info.notCheckable = 1
      info.func = UIDropDownMenuButton_OpenColorPicker
      AddButton(lvl, text, nil)
    end
    local function AddList(lvl, text, value)
      info.value = value
      info.hasArrow = true
      info.func = HideCheck
      info.notCheckable = 1
      AddButton(lvl, text, 1)
    end
    local function AddSelect(lvl, text, arg1, value)
      info.arg1 = arg1
      info.func = SetSelect
      info.value = value
      if tonumber(value) and tonumber(db[arg1] or "blah") then
        if floor(100 * tonumber(value)) == floor(100 * tonumber(db[arg1])) then
          info.checked = true
        end
      else
        info.checked = (db[arg1] == value)
      end
      AddButton(lvl, text, 1)
    end
    local function AddFakeSlider(lvl, value, minv, maxv, step, tbl)
      local cvalue = 0
      local dbv = db[value]
      if type(dbv) == "string" and tbl then
        for i, v in ipairs(tbl) do
          if dbv == v then
            cvalue = i
            break
          end
        end
      else
        cvalue = dbv or floor((maxv - minv) / 2)
      end
      local adj = (offsetvalue == value and offsetcount) or 0
      local starti = max(minv, cvalue - (7 - adj) * step)
      local endi = min(maxv, cvalue + (8 + adj) * step)
      if starti == minv then
        endi = min(maxv, starti + 16 * step)
      elseif endi == maxv then
        starti = max(minv, endi - 16 * step)
      end
      if starti > minv then
        AddExecute(lvl, "--", "less", value)
      end
      if tbl then
        for i = starti, endi, step do
          AddSelect(lvl, tbl[i], value, tbl[i])
        end
      else
        local fstring = (step >= 1 and "%d") or (step >= 0.1 and "%.1f") or "%.2f"
        for i = starti, endi, step do
          AddSelect(lvl, format(fstring, i), value, i)
        end
      end
      if endi < maxv then
        AddExecute(lvl, "++", "more", value)
      end
    end
    CellularDD.initialize = function(self, lvl)
      if lvl == 1 then
        if showid then
          AddExecute(lvl, "Show Message (or left-click)", "showtab", showid)
          AddExecute(lvl, "Close Tab (or middle-click)", "removetab", showid)
          info.isTitle = true
          AddButton(lvl, " ")
          AddExecute(lvl, "Options", "showoptions")
        else
          info.isTitle = true
          info.notCheckable = 1
          AddButton(lvl, "|cff5555ffCellular|r")
          AddList(lvl, "Frame", "frame")
          AddList(lvl, "Text", "text")
          AddList(lvl, "Behavior", "behave")
          AddList(lvl, "History", "history")
        end
      elseif lvl == 2 then
        local sub = UIDROPDOWNMENU_MENU_VALUE
        if sub == "frame" then
          AddList(lvl, "Texture Group", "bglist")
          AddList(lvl, "Background Texture", "bg")
          AddColor(lvl, "Background Color", "bgcolor")
          AddList(lvl, "Border", "border")
          AddColor(lvl, "Border Color", "bordercolor")
          AddToggle(lvl, "Show Side Buttons", "showside")
          AddList(lvl, "Frame Opacity", "alpha")
          AddList(lvl, "Frame Strata", "strata")
          AddExecute(lvl, "Reset Size and Position", "resetsizes")
          AddExecute(lvl, "How to Move/Resize", "movehelp")
        elseif sub == "text" then
          AddToggle(lvl, "Show Name", "showname")
          AddToggle(lvl, "Show Timestamp", "showtime")
          AddToggle(lvl, "Fade Old Messages", "fade")
          AddList(lvl, "Title Font", "fonttitle")
          AddList(lvl, "Title Style", "fonttitlestyle")
          AddList(lvl, "Message Font", "fontmsg")
          AddList(lvl, "Message Style", "fontmsgstyle")
          AddList(lvl, "Message Font Size", "fontsize")
          AddColor(lvl, "Incoming Font Color", "incolor")
          AddColor(lvl, "Outgoing Font Color", "outcolor")
        elseif sub == "behave" then
          AddToggle(lvl, "Use Tabs", "enabletabs")
          AddToggle(lvl, "No battle.net", "nobn")
          AddToggle(lvl, "Combat Auto-Minimize", "automin")
          AddToggle(lvl, "Always Auto-Minimize", "autominalways")
          AddToggle(lvl, "Editbox Top Anchor", "showtop")
          AddToggle(lvl, "Disable EditBox Move", "noattach")
          AddToggle(lvl, "Disable Block to Default", "chatshow")
          AddList(lvl, "Maximum Windows/Tabs", "maxwindows")
          AddExecute(lvl, "Set Busy Message", "busymessage")
          AddToggle(lvl, "Save Settings Per Character", "char")
        elseif sub == "history" then
          AddToggle(lvl, "Enable History", "history")
          AddList(lvl, "Show Recent", "recent")
          AddList(lvl, "Show Entry", "show")
          AddList(lvl, "Clear Entry (hold shift)", "clear")
          AddExecute(lvl, "Clear +6 Weeks (hold shift)", "clearold")
          AddExecute(lvl, "Clear All (hold shift)", "clearall")
        end
      elseif lvl == 3 then
        local sub = UIDROPDOWNMENU_MENU_VALUE
        if sub == "bglist" then
          AddSelect(lvl, "background", sub, "background")
          AddSelect(lvl, "statusbar", sub, "statusbar")
        elseif sub == "bg" then
          local t = smed:List(db.bglist or "background")
          AddFakeSlider(lvl, sub, 1, #t, 1, t)
        elseif sub == "fonttitle" or sub == "fontmsg" then
          local t = smed:List("font")
          AddFakeSlider(lvl, sub, 1, #t, 1, t)
        elseif sub == "border" then
          local t = smed:List("border")
          AddFakeSlider(lvl, sub, 1, #t, 1, t)
        elseif sub == "fontsize" then
          AddFakeSlider(lvl, sub, 4, 30, 1)
        elseif sub == "fonttitlestyle" or sub == "fontmsgstyle" then
          AddSelect(lvl, "None", sub, "None")
          AddSelect(lvl, "Shadow", sub, "Shadow")
          AddSelect(lvl, "Outline", sub, "OUTLINE")
          AddSelect(lvl, "Thick Outline", sub, "THICKOUTLINE")
          AddSelect(lvl, "Monochrome", sub, "MONOCHROME")
        elseif sub == "alpha" then
          AddFakeSlider(lvl, sub, 0, 1, 0.1)
        elseif sub == "strata" then
          AddSelect(lvl, "BACKGROUND", sub, "BACKGROUND")
          AddSelect(lvl, "LOW", sub, "LOW")
          AddSelect(lvl, "MEDIUM", sub, "MEDIUM")
          AddSelect(lvl, "HIGH", sub, "HIGH")
          AddSelect(lvl, "DIALOG", sub, "DIALOG")
        elseif sub == "maxwindows" then
          AddFakeSlider(lvl, sub, 4, 20, 1)
        elseif sub == "recent" or sub == "show" or sub == "clear" then
          wipe(list)
          for name in pairs(sub == "recent" and recentw or svar) do
            tinsert(list, name)
          end
          table.sort(list)
          AddFakeSlider(lvl, sub, 1, #list, 1, list)
        end
      end
    end
  end
  ToggleDropDownMenu(1, nil, CellularDD, "cursor")
end
