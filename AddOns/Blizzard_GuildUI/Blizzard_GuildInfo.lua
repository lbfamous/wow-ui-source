local GUILD_BUTTON_HEIGHT = 84;

local GUILD_EVENT_TEXTURES = {
	--[CALENDAR_EVENTTYPE_RAID]		= "Interface\\LFGFrame\\LFGIcon-",
	--[CALENDAR_EVENTTYPE_DUNGEON]	= "Interface\\LFGFrame\\LFGIcon-",
	[CALENDAR_EVENTTYPE_PVP]		= "Interface\\Calendar\\UI-Calendar-Event-PVP",
	[CALENDAR_EVENTTYPE_MEETING]	= "Interface\\Calendar\\MeetingIcon",
	[CALENDAR_EVENTTYPE_OTHER]		= "Interface\\Calendar\\UI-Calendar-Event-Other",
};
local GUILD_EVENT_TEXTURE_PATH = "Interface\\LFGFrame\\LFGIcon-";

function GuildInfoFrame_OnLoad(self)
	GuildFrame_RegisterPanel(self);
	PanelTemplates_SetNumTabs(self, 3);

	self:RegisterEvent("GUILD_MOTD");
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
	self:RegisterEvent("GUILD_RANKS_UPDATE");
	self:RegisterEvent("PLAYER_GUILD_UPDATE");
	self:RegisterEvent("LF_GUILD_POST_UPDATED");
	self:RegisterEvent("LF_GUILD_RECRUITS_UPDATED");
	
	RequestGuildRecruitmentSettings();
end

function GuildInfoFrame_OnEvent(self, event, arg1)
	if ( event == "GUILD_MOTD" ) then
		GuildInfoMOTD:SetText(arg1);
	elseif ( event == "GUILD_ROSTER_UPDATE" ) then
		GuildInfoFrame_UpdatePermissions();
		GuildInfoFrame_UpdateText();
	elseif ( event == "GUILD_RANKS_UPDATE" ) then
		GuildInfoFrame_UpdatePermissions();
	elseif ( event == "PLAYER_GUILD_UPDATE" ) then
		GuildInfoFrame_UpdatePermissions();
	elseif ( event == "LF_GUILD_POST_UPDATED" ) then
		local bCasual, bModerate, bHardcore, bWeekdays, bWeekends, bTank, bHealer, bDamage, bAnyLevel, bMaxLevel, bListed = GetGuildRecruitmentSettings();
		-- playstyle
		if ( bModerate ) then
			GuildRecruitmentPlaystyleButton_OnClick(2);
		elseif ( bHardcore ) then
			GuildRecruitmentPlaystyleButton_OnClick(3);
		else
			GuildRecruitmentPlaystyleButton_OnClick(1);
		end
		-- availability
		GuildRecruitmentWeekdaysButton:SetChecked(bWeekdays);
		GuildRecruitmentWeekendsButton:SetChecked(bWeekends);
		-- roles
		GuildRecruitmentTankButton.checkButton:SetChecked(bTank);
		GuildRecruitmentHealerButton.checkButton:SetChecked(bHealer);
		GuildRecruitmentDamagerButton.checkButton:SetChecked(bDamage);
		-- level
		if ( bMaxLevel ) then
			GuildRecruitmentLevelButton_OnClick(2);
		else
			GuildRecruitmentLevelButton_OnClick(1);
		end
		-- comment
		GuildRecruitmentCommentEditBox:SetText(GetGuildRecruitmentComment());
		GuildRecruitmentListGuildButton_Update();
	elseif ( event == "LF_GUILD_RECRUITS_UPDATED" ) then
		GuildInfoFrameApplicants_Update();
	end
end

function GuildInfoFrame_OnShow(self)
	RequestGuildApplicantsList();
end

function GuildInfoFrame_Update()
	local selectedTab = PanelTemplates_GetSelectedTab(GuildInfoFrame);
	if ( selectedTab == 1 ) then
		GuildInfoFrameInfo:Show();
		GuildInfoFrameRecruitment:Hide();
		GuildInfoFrameApplicants:Hide();
	elseif ( selectedTab == 2 ) then
		GuildInfoFrameInfo:Hide();
		GuildInfoFrameRecruitment:Show();
		GuildInfoFrameApplicants:Hide();
	else
		GuildInfoFrameInfo:Hide();
		GuildInfoFrameRecruitment:Hide();
		GuildInfoFrameApplicants:Show();
	end
end

--*******************************************************************************
--   Info Tab
--*******************************************************************************

function GuildInfoFrameInfo_OnLoad(self)
	GuildInfoEventsContainer.update = GuildInfoEvents_Update;
	HybridScrollFrame_CreateButtons(GuildInfoEventsContainer, "GuildNewsButtonTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, 0, "TOP", "BOTTOM");
	local buttons = GuildInfoEventsContainer.buttons;
	for i = 1, #buttons do
		buttons[i].isEvent = true;
	end

	local fontString = GuildInfoEditMOTDButton:GetFontString();
	GuildInfoEditMOTDButton:SetHeight(fontString:GetHeight() + 4);
	GuildInfoEditMOTDButton:SetWidth(fontString:GetWidth() + 4);
	fontString = GuildInfoEditDetailsButton:GetFontString();
	GuildInfoEditDetailsButton:SetHeight(fontString:GetHeight() + 4);
	GuildInfoEditDetailsButton:SetWidth(fontString:GetWidth() + 4);	
	fontString = GuildInfoEditEventButton:GetFontString();
	GuildInfoEditEventButton:SetHeight(fontString:GetHeight() + 4);
	GuildInfoEditEventButton:SetWidth(fontString:GetWidth() + 4);
	
	-- faction icon
	if ( GetGuildFactionGroup() == 0 ) then  -- horde
		GUILD_EVENT_TEXTURES[CALENDAR_EVENTTYPE_PVP] = "Interface\\Calendar\\UI-Calendar-Event-PVP01";
	else  -- alliance
		GUILD_EVENT_TEXTURES[CALENDAR_EVENTTYPE_PVP] = "Interface\\Calendar\\UI-Calendar-Event-PVP02";
	end
end

function GuildInfoFrameInfo_OnShow(self)
	GuildInfoEvents_Update();
	GuildInfoFrame_UpdatePermissions();	
	GuildInfoFrame_UpdateText();
end

function GuildInfoFrame_UpdatePermissions()
	if ( CanEditMOTD() ) then
		GuildInfoEditMOTDButton:Show();
	else
		GuildInfoEditMOTDButton:Hide();
	end
	if ( CanEditGuildInfo() ) then
		GuildInfoEditDetailsButton:Show();
	else
		GuildInfoEditDetailsButton:Hide();
	end
	if ( CanEditGuildEvent() ) then
		GuildInfoEditEventButton:Show();
	else
		GuildInfoEditEventButton:Hide();
	end
	local guildInfoFrame = GuildInfoFrame;
	if ( IsGuildLeader() ) then
		GuildControlButton:Enable();
		-- show the recruitment tabs if the player is guild leader
		if ( not guildInfoFrame.tabsShowing ) then
			guildInfoFrame.tabsShowing = true;
			GuildInfoFrameTab1:Show();
			GuildInfoFrameTab2:Show();
			GuildInfoFrameTab3:Show();
			GuildInfoFrameTab3:SetText(GUILDINFOTAB_APPLICANTS_NONE);
			PanelTemplates_DisableTab(guildInfoFrame, 3);
			PanelTemplates_SetTab(guildInfoFrame, 1);
			PanelTemplates_UpdateTabs(guildInfoFrame);
			RequestGuildApplicantsList();
		end
	else
		GuildControlButton:Disable();
		-- hide the recruitment tabs if the player is not guild leader any more
		if ( guildInfoFrame.tabsShowing ) then
			guildInfoFrame.tabsShowing = nil;
			GuildInfoFrameTab1:Hide();
			GuildInfoFrameTab2:Hide();
			GuildInfoFrameTab3:Hide();
			if ( PanelTemplates_GetSelectedTab(guildInfoFrame) ~= 1 ) then
				PanelTemplates_SetTab(guildInfoFrame, 1);
				GuildInfoFrame_Update();
			end
		end
	end
	if ( CanGuildInvite() ) then
		GuildAddMemberButton:Enable();
	else
		GuildAddMemberButton:Disable();
	end	
end

function GuildInfoFrame_UpdateText(infoText)
	GuildInfoMOTD:SetText(GetGuildRosterMOTD());
	if ( infoText ) then
		GuildInfoFrame.cachedInfoText = infoText;
		GuildInfoFrame.cacheExpiry = GetTime() + 10;
	else
		if ( not GuildInfoFrame.cacheExpiry or GetTime() > GuildInfoFrame.cacheExpiry ) then 
			GuildInfoFrame.cachedInfoText = GetGuildInfoText();
		end
	end
	GuildInfoDetails:SetText(GuildInfoFrame.cachedInfoText);
	GuildInfoDetailsFrame:SetVerticalScroll(0);
	GuildInfoDetailsFrameScrollBarScrollUpButton:Disable();
end

function GuildInfoEvents_Update()
	local scrollFrame = GuildInfoEventsContainer;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local button, index;
	local numEvents = CalendarGetNumGuildEvents();
	
	if ( numEvents > 0 ) then
		GuildInfoNoEvents:Hide();
	else
		GuildInfoNoEvents:Show();
	end

	for i = 1, numButtons do
		button = buttons[i];
		index = offset + i;
		if ( index <= numEvents ) then
			GuildInfoEvents_SetButton(button, index);
			button:Show();
		else
			button:Hide();
		end
	end
	local totalHeight = numEvents * scrollFrame.buttonHeight;
	local displayedHeight = numButtons * scrollFrame.buttonHeight;
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
	GuildFrame_UpdateScrollFrameWidth(scrollFrame);
end

function GuildInfoEvents_SetButton(button, eventIndex)
	local today = date("*t");
	local month, day, weekday, hour, minute, eventType, title, calendarType, textureName = CalendarGetGuildEventInfo(eventIndex);
	local displayTime = GameTime_GetFormattedTime(hour, minute, true);
	local displayDay;
	
	if ( today["day"] == day and today["month"] == month ) then
		displayDay = NORMAL_FONT_COLOR_CODE..GUILD_EVENT_TODAY..FONT_COLOR_CODE_CLOSE;
	elseif ( abs(today["day"] - day) > 6 ) then		-- good-enough calculation of next week
		displayDay = string.format(GUILD_NEWS_DATE, CALENDAR_WEEKDAY_NAMES[weekday], day, month);
	else
		displayDay = CALENDAR_WEEKDAY_NAMES[weekday];
	end
	button.text:SetFormattedText(GUILD_EVENT_FORMAT, displayDay, displayTime, title);
	button.index = eventIndex;
	-- icon
	if ( button.icon.type ~= "event" ) then
		button.icon.type = "event"
		button.icon:SetTexCoord(0, 1, 0, 1);
		button.icon:SetWidth(14);
		button.icon:SetHeight(14);
	end
	if ( GUILD_EVENT_TEXTURES[eventType] ) then
		button.icon:SetTexture(GUILD_EVENT_TEXTURES[eventType]);
	else
		button.icon:SetTexture(GUILD_EVENT_TEXTURE_PATH..textureName);
	end	
end

function GuildInfoEventButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		if ( CalendarFrame and CalendarFrame:IsShown() ) then
			-- if the calendar is already open we need to do some work that's normally happening in CalendarFrame_OnShow
			local weekday, month, day, year = CalendarGetDate();
			CalendarSetAbsMonth(month, year);
		else
			ToggleCalendar();
		end
		local monthOffset, day, eventIndex = CalendarGetGuildEventSelectionInfo(self.index);
		CalendarSetMonth(monthOffset);
		-- need to highlight the proper day/event in calendar
		local _, _, _, firstDay = CalendarGetMonth();
		local buttonIndex = day + firstDay - CALENDAR_FIRST_WEEKDAY;
		if ( firstDay < CALENDAR_FIRST_WEEKDAY ) then
			buttonIndex = buttonIndex + 7;
		end
		local dayButton = _G["CalendarDayButton"..buttonIndex];
		CalendarDayButton_Click(dayButton);
		if ( eventIndex <= 4 ) then -- can only see 4 events per day
			local eventButton = _G["CalendarDayButton"..buttonIndex.."EventButton"..eventIndex];
			CalendarDayEventButton_Click(eventButton, true);	-- true to open the event
		else
			CalendarFrame_SetSelectedEvent();	-- clears any event highlights
			CalendarOpenEvent(0, day, eventIndex);
		end
	end
end

--*******************************************************************************
--   Recruitment Tab
--*******************************************************************************

function GuildInfoFrameRecruitment_OnLoad(self)
	GuildRecruitmentPlaystyleFrameText:SetText(GUILD_PLAYSTYLE);
	GuildRecruitmentPlaystyleFrame:SetHeight(46);
	GuildRecruitmentAvailabilityFrameText:SetText(GUILD_AVAILABILITY);
	GuildRecruitmentAvailabilityFrame:SetHeight(46);
	GuildRecruitmentRolesFrameText:SetText(CLASS_ROLES);
	GuildRecruitmentRolesFrame:SetHeight(80);
	GuildRecruitmentLevelFrameText:SetText(GUILD_RECRUITMENT_LEVEL);
	GuildRecruitmentLevelFrame:SetHeight(46);
	GuildRecruitmentCommentFrameText:SetText(COMMENT);
	GuildRecruitmentCommentFrame:SetHeight(84);
	
	-- defaults until data is retrieved
	GuildRecruitmentCasualButton:SetChecked(1);
	GuildRecruitmentLevelAnyButton:SetChecked(1);
	GuildRecruitmentListGuildButton:Disable();
end

function GuildRecruitmentPlaystyleButton_OnClick(index, userClick)
	local param;
	if ( index == 1 ) then
		GuildRecruitmentCasualButton:SetChecked(1);
		GuildRecruitmentModerateButton:SetChecked(nil);
		GuildRecruitmentHardcoreButton:SetChecked(nil);
		param = LFGUILD_PARAM_CASUAL;
	elseif ( index == 2 ) then
		GuildRecruitmentCasualButton:SetChecked(nil);
		GuildRecruitmentModerateButton:SetChecked(1);
		GuildRecruitmentHardcoreButton:SetChecked(nil);
		param = LFGUILD_PARAM_MODERATE;
	else
		GuildRecruitmentCasualButton:SetChecked(nil);
		GuildRecruitmentModerateButton:SetChecked(nil);
		GuildRecruitmentHardcoreButton:SetChecked(1);
		param = LFGUILD_PARAM_HARDCORE;
	end
	if ( userClick ) then
		SetGuildRecruitmentSettings(param, true);
	end
end

function GuildRecruitmentLevelButton_OnClick(index, userClick)
	local param;
	if ( index == 1 ) then
		GuildRecruitmentLevelAnyButton:SetChecked(1);
		GuildRecruitmentLevelMaxButton:SetChecked(nil);
		param = LFGUILD_PARAM_ANY_LEVEL;
	elseif ( index == 2 ) then
		GuildRecruitmentLevelAnyButton:SetChecked(nil);
		GuildRecruitmentLevelMaxButton:SetChecked(1);
		param = LFGUILD_PARAM_MAX_LEVEL;
	end
	if ( userClick ) then
		SetGuildRecruitmentSettings(param, true);
	end	
end

function GuildRecruitmentRoleButton_OnClick(self)
	local checked = self:GetChecked();
	if ( self:GetChecked() ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
	local id = self:GetParent():GetID();
	if ( id == 1 ) then
		SetGuildRecruitmentSettings(LFGUILD_PARAM_TANK, checked);
	elseif ( id == 2 ) then
		SetGuildRecruitmentSettings(LFGUILD_PARAM_HEALER, checked);
	else
		SetGuildRecruitmentSettings(LFGUILD_PARAM_DAMAGE, checked);
	end
	GuildRecruitmentListGuildButton_Update();
end

function GuildRecruitmentListGuildButton_Update()
	local bCasual, bModerate, bHardcore, bWeekdays, bWeekends, bTank, bHealer, bDamage, bAnyLevel, bMaxLevel, bListed = GetGuildRecruitmentSettings();
	-- need to have at least 1 time and at least 1 role checked to be able to list
	if ( bWeekdays or bWeekends ) and ( bTank or bHealer or bDamage ) then
		GuildRecruitmentListGuildButton:Enable();
	else
		GuildRecruitmentListGuildButton:Disable();
		-- delist if already listed
		if ( bListed ) then
			bListed = false;
			SetGuildRecruitmentSettings(LFGUILD_PARAM_LOOKING, false);
		end
	end
	GuildRecruitmentListGuildButton_UpdateText(bListed);
end

function GuildRecruitmentListGuildButton_OnClick(self)
	local bCasual, bModerate, bHardcore, bWeekdays, bWeekends, bTank, bHealer, bDamage, bAnyLevel, bMaxLevel, bListed = GetGuildRecruitmentSettings();
	bListed = not bListed;
	if ( bListed and GuildRecruitmentCommentEditBox:HasFocus() ) then
		GuildRecruitmentComment_SaveText();
	end
	SetGuildRecruitmentSettings(LFGUILD_PARAM_LOOKING, bListed);
	GuildRecruitmentListGuildButton_UpdateText(bListed);
end

function GuildRecruitmentListGuildButton_UpdateText(listed)
	if ( listed ) then
		GuildRecruitmentListGuildButton:SetText(GUILD_CLOSE_RECRUITMENT);
	else
		GuildRecruitmentListGuildButton:SetText(GUILD_OPEN_RECRUITMENT);
	end
end

function GuildRecruitmentComment_SaveText(self)
	self = self or GuildRecruitmentCommentEditBox;
	SetGuildRecruitmentComment(self:GetText());
	self:ClearFocus();
end

--*******************************************************************************
--   Applicants Tab
--*******************************************************************************

function GuildInfoFrameApplicants_OnLoad(self)
	GuildInfoFrameApplicantsContainer.update = GuildInfoFrameApplicants_Update;
	HybridScrollFrame_CreateButtons(GuildInfoFrameApplicantsContainer, "GuildRecruitmentApplicantTemplate", 0, 0);
	
	GuildInfoFrameApplicantsContainerScrollBar.Show = 
		function (self)
			GuildInfoFrameApplicantsContainer:SetWidth(304);
			for _, button in next, GuildInfoFrameApplicantsContainer.buttons do
				button:SetWidth(301);
			end
			getmetatable(self).__index.Show(self);
		end
	GuildInfoFrameApplicantsContainerScrollBar.Hide = 
		function (self)
			GuildInfoFrameApplicantsContainer:SetWidth(320);
			for _, button in next, GuildInfoFrameApplicantsContainer.buttons do
				button:SetWidth(320);
			end
			getmetatable(self).__index.Hide(self);
		end
end

function GuildInfoFrameApplicants_OnShow(self)
	GuildInfoFrameApplicants_Update();
end

function GuildInfoFrameApplicants_Update()
	local scrollFrame = GuildInfoFrameApplicantsContainer;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local button, index;
	local numApplicants = GetNumGuildApplicants();
	local selection = GetGuildApplicantSelection();

	if ( numApplicants == 0 ) then
		if ( not GuildInfoFrameTab3.wasEnabled ) then
			PanelTemplates_DisableTab(GuildInfoFrame, 3);
		end
		GuildInfoFrameTab3:SetText(GUILDINFOTAB_APPLICANTS_NONE);
	else
		PanelTemplates_EnableTab(GuildInfoFrame, 3);
		GuildInfoFrameTab3.wasEnabled = true;
		GuildInfoFrameTab3:SetFormattedText(GUILDINFOTAB_APPLICANTS, numApplicants);
	end
	PanelTemplates_TabResize(GuildInfoFrameTab3, 0);
	
	for i = 1, numButtons do
		button = buttons[i];
		index = offset + i;
		local name, level, class, _, _, _, _, _, isTank, isHealer, isDamage, comment = GetGuildApplicantInfo(index);
		if ( name ) then
			button.name:SetText(name);
			button.level:SetText(level);
			button.comment:SetText(comment);
			button.emblem:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]));
			-- roles
			if ( isTank ) then
				button.tankTex:Show();
			else
				button.tankTex:Hide();
			end
			if ( isHealer ) then
				button.healerTex:Show();
			else
				button.healerTex:Hide();
			end
			if ( isDamage ) then
				button.damageTex:Show();
			else
				button.damageTex:Hide();
			end
			-- selection
			if ( index == selection ) then
				button.selectedTex:Show();
			else
				button.selectedTex:Hide();
			end
			
			button:Show();
			button.index = index;
		else
			button:Hide();
		end
	end
	local totalHeight = numApplicants * GUILD_BUTTON_HEIGHT;
	local displayedHeight = numApplicants * GUILD_BUTTON_HEIGHT;
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
	
	if ( selection and selection > 0 ) then
		GuildRecruitmentInviteButton:Enable();
		GuildRecruitmentDeclineButton:Enable();
		GuildRecruitmentMessageButton:Enable();
	else
		GuildRecruitmentInviteButton:Disable();
		GuildRecruitmentDeclineButton:Disable();
		GuildRecruitmentMessageButton:Disable();
	end
end

function GuildRecruitmentApplicant_OnClick(self, button)
	if ( button == "LeftButton" ) then
		SetGuildApplicantSelection(self.index);
		GuildInfoFrameApplicants_Update();
	end
end

--*******************************************************************************
--   Popups
--*******************************************************************************

function GuildTextEditFrame_OnLoad(self)
	GuildFrame_RegisterPopup(self);
	GuildTextEditBox:SetTextInsets(4, 0, 4, 4);
	GuildTextEditBox:SetSpacing(2);
end

function GuildTextEditFrame_Show(editType)
	if ( editType == "motd" ) then
		GuildTextEditFrame:SetHeight(162);
		GuildTextEditBox:SetMaxLetters(128);
		GuildTextEditBox:SetText(GetGuildRosterMOTD());
		GuildTextEditFrameTitle:SetText(GUILD_MOTD_EDITLABEL);
		GuildTextEditBox:SetScript("OnEnterPressed", GuildTextEditFrame_OnAccept);
	elseif ( editType == "info" ) then
		GuildTextEditFrame:SetHeight(295);
		GuildTextEditBox:SetMaxLetters(500);
		GuildTextEditBox:SetText(GuildInfoFrame.cachedInfoText);
		GuildTextEditFrameTitle:SetText(GUILD_INFO_EDITLABEL);
		GuildTextEditBox:SetScript("OnEnterPressed", nil);
	end
	GuildTextEditFrame.type = editType;
	GuildFramePopup_Show(GuildTextEditFrame);
	GuildTextEditBox:SetCursorPosition(0);
	GuildTextEditBox:SetFocus();
	PlaySound("igMainMenuOptionCheckBoxOn");
end

function GuildTextEditFrame_OnAccept()
	if ( GuildTextEditFrame.type == "motd" ) then
		GuildSetMOTD(GuildTextEditBox:GetText());
	elseif ( GuildTextEditFrame.type == "info" ) then
		local infoText = GuildTextEditBox:GetText();
		GuildInfoFrame_UpdateText(infoText);
		SetGuildInfoText(infoText);
	end
	GuildTextEditFrame:Hide();
end

function GuildLogFrame_OnLoad(self)
	GuildFrame_RegisterPopup(self);
	GuildLogHTMLFrame:SetSpacing(2);
	ScrollBar_AdjustAnchors(GuildLogScrollFrameScrollBar, 0, -2);
	self:RegisterEvent("GUILD_EVENT_LOG_UPDATE");
end

function GuildLogFrame_Update()
	local numEvents = GetNumGuildEvents();
	local type, player1, player2, rank, year, month, day, hour;
	local msg;
	local buffer = "";
	for i = numEvents, 1, -1 do
		type, player1, player2, rank, year, month, day, hour = GetGuildEventInfo(i);
		if ( not player1 ) then
			player1 = UNKNOWN;
		end
		if ( not player2 ) then
			player2 = UNKNOWN;
		end
		if ( type == "invite" ) then
			msg = format(GUILDEVENT_TYPE_INVITE, player1, player2);
		elseif ( type == "join" ) then
			msg = format(GUILDEVENT_TYPE_JOIN, player1);
		elseif ( type == "promote" ) then
			msg = format(GUILDEVENT_TYPE_PROMOTE, player1, player2, rank);
		elseif ( type == "demote" ) then
			msg = format(GUILDEVENT_TYPE_DEMOTE, player1, player2, rank);
		elseif ( type == "remove" ) then
			msg = format(GUILDEVENT_TYPE_REMOVE, player1, player2);
		elseif ( type == "quit" ) then
			msg = format(GUILDEVENT_TYPE_QUIT, player1);
		end
		if ( msg ) then
			buffer = buffer..msg.."|cff009999   "..format(GUILD_BANK_LOG_TIME, RecentTimeDate(year, month, day, hour)).."|r|n";
		end
	end
	GuildLogHTMLFrame:SetText(buffer);
end