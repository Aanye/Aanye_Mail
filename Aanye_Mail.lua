-----------------------
--  Local variables  --
-----------------------

local SYNC_INTERVAL = 0.5
local timer,status = 0,0
local world_event_fired,mailbox_open,mailbox_event_fired,mail_update_fired,_
local L = LibStub:GetLibrary( "AceLocale-3.0" ):GetLocale("Aanye_Mail")
local db

---------------------------
--  Instantiate Objects  --
---------------------------

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Aanye_Mail", {type = "data source", text = " ", icon = "Interface\\AddOns\\Aanye_Mail\\nomail"})

-------------------------
--  Frame Functions  --
-------------------------

f:RegisterEvent("UPDATE_PENDING_MAIL")
f:RegisterEvent("MAIL_SHOW")
f:RegisterEvent("MAIL_CLOSED")
f:RegisterEvent("MAIL_INBOX_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		if not db then
			db = LibStub:GetLibrary("AceDB-3.0"):New("Aanye_Mail_DB", {
				char = {
					last_senders = {},
				},
			}, true)
		end
	end
	if event == "UPDATE_PENDING_MAIL" then
		mail_update_fired = 1
	elseif event == "PLAYER_ENTERING_WORLD" then
		world_event_fired = 1
	elseif event == "MAIL_SHOW" then
		mailbox_open,mailbox_event_fired = 1,1
		if status == 2 then
			status = 1
			f.SetBrokerText()
		end
	elseif event == "MAIL_CLOSED" then
		mailbox_open = nil
	elseif event == "MAIL_INBOX_UPDATE" then
		db.char.last_senders = {GetLatestThreeSenders()}
		if not db.char.last_senders[1] then
			status = 0
			f.SetBrokerText()
		end
	end
end)

f:SetScript("OnUpdate", function(self, elapsed)
	if not (world_event_fired or mail_update_fired) then return end
	if mailbox_open then
		timer = 0
		return
	end

	timer = timer + elapsed
	if timer < SYNC_INTERVAL then return end

	if mail_update_fired then
		local senders = {GetLatestThreeSenders()}
		if not senders[1] then
			status = 0
		elseif not world_event_fired then
			status = 2
		elseif not mailbox_event_fired then
			if senders[1] ~= db.char.last_senders[1]
				or senders[2] ~= db.char.last_senders[2]
				or senders[3] ~= db.char.last_senders[3]
			then
				status = 2
			elseif status ~= 2 then
				status = senders[1] and 1 or 0
			end
		end
		db.char.last_senders = senders
		f.SetBrokerText()
	end
	world_event_fired,mail_update_fired,timer = nil,nil,0
end)

function f.SetBrokerText()
	if status == 2 then
		dataobj.icon = "Interface\\AddOns\\Aanye_Mail\\newmail"
		dataobj.text = ' |cFF00FF00'..L["New Mail"]..'|r '
	elseif status == 1 then
		dataobj.icon = "Interface\\Addons\\Aanye_Mail\\mail"
		dataobj.text = ' '..L["New Mail"]..' '
	else
		dataobj.icon = "Interface\\Addons\\Aanye_Mail\\nomail"
		dataobj.text = ' '..L["No Mail"]..' '
	end
end

------------------
--  LDB Object  --
------------------

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

function dataobj.OnEnter(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	dataobj.SetTooltipContents()
end

function dataobj.OnLeave()
	GameTooltip:Hide()
	if status == 2 then status = 1 end
	f.SetBrokerText()
end

function dataobj.SetTooltipContents()
	GameTooltip:ClearLines()

	if status > 0 then
		GameTooltip:AddLine(L["Unread mail from:"])
		GameTooltip:AddLine(" ")
		for i,v in ipairs(db.char.last_senders) do
			GameTooltip:AddLine(v)
		end
	else
		GameTooltip:AddLine(L["No unread mail."])
	end

	GameTooltip:Show()
end