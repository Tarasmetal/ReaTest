-- @description Marker GUI Tools
-- @author Taras Umanskiy
-- @version 1.0
-- @metapackage
-- @provides [main] .
-- @link http://vk.com/tarasmetal
-- @donation https://paypal.me/Tarasmetal
-- @about
--   # КАК ЭТО РАБОТАЕТ?
--   Основная идея и задача скрипта — максимально сократить время на разметку проекта, оставляя его красивым и понятным для всех, а главное для самого себя.
--   Не отвлекайтесь от творческого процесса, перемещайтесь в любую точку проекта за пару секунд, чтобы записать, прослушать или внести кориктеровки в трекинг.
-- @changelog
--  + Code Fixies


local r = reaper
local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()
local IMGUI_VERSION, REAIMGUI_VERSION = r.ImGui_GetVersion()

widgets = {}

console = true

function msg(value)
  if console then
    r.ShowConsoleMsg(tostring(value) .. "\n")
  end
end

scrAuthor = 'Taras Umanskiy'
scrVersion = '1.0'
scrName = 'MARKER TOOLS'
scrAbout = scrName .. ' ' .. scrVersion .. ' by ' .. scrAuthor

ListDir = {}
ListDir.scriptDir, ListDir.scriptFileName = ({r.get_action_context()})[2]:match("(.-)([^/\\]+).lua$")

scriptDir = ListDir.scriptDir
presetDir = ListDir.scriptDir .. 'MarkerPresets'

windowTitle = scrAbout
defaultPresetName = 'Default.lua'

dofile(scriptDir .. "Functions/" .. "PresetFileLoadFunctions.lua")
dofile(scriptDir .. "Functions/" .. "MarkerFunctions.lua")


local info = debug.getinfo(1, 'S');
local FontPath = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua') ('0.8.1') -- current version at the time of writing the script

local ctx = r.ImGui_CreateContext(windowTitle)
local size = r.GetAppVersion():match('Win64') and 12 or 14
-- local font = r.ImGui_CreateFont('Tahoma', 9)
local font = reaper.ImGui_CreateFont('sans-serif', 14)
-- local font = r.ImGui_CreateFont('Consolas', 9)
-- local font =  r.ImGui_CreateFont('Sedoe', 9)
r.ImGui_Attach(ctx, font)

markersToShow = parse_simple_preset_content(preset_read_simple(presetDir, defaultPresetName)) -- Дефолтный пресет

------------------------------------------------------------------------------------------------------------------

function HelpMarker(helpName, desc)
  r.ImGui_TextDisabled(ctx, '' .. helpName .. '')
  if r.ImGui_IsItemHovered(ctx) then
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
    r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), desc)
    r.ImGui_PopTextWrapPos(ctx)
    r.ImGui_EndTooltip(ctx)
  end
end

function btnCmdCol(name, idCmd, helpText, col, i)
           r.ImGui_PushID(ctx, col)
		   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(col / 7.0, 0.6, 0.6, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(col / 7.0, 0.7, 0.7, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(col / 7.0, 0.8, 0.8, 1.0))
           if r.ImGui_Button(ctx, ''..name..'') then
              click_count, text = 0, idCmd
              if idCmd ~= '' then
                r.Main_OnCommand(r.NamedCommandLookup('' .. idCmd ..''), 0)
              end
              click_count = click_count + 1
           end
            r.ImGui_PopStyleColor(ctx, 3)
            r.ImGui_PopID(ctx)

          if r.ImGui_IsItemHovered(ctx) then
          r.ImGui_BeginTooltip(ctx)
			     r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
               if helpText ~= '' then
			     r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), helpText)
               end
			     r.ImGui_PopTextWrapPos(ctx)
			     r.ImGui_EndTooltip(ctx)
            end

           return
end

function btnSCRCol(name, idCmd, helpText, col, i)
		   r.ImGui_PushID(ctx, col)
		   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(col / 7.0, 0.6, 0.6, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(col / 7.0, 0.7, 0.7, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(col / 7.0, 0.8, 0.8, 1.0))
           if r.ImGui_Button(ctx, ''..name..'') then
              click_count, text = 0, idCmd
              if idCmd ~= '' then
                -- r.Main_OnCommand(r.NamedCommandLookup('' .. idCmd ..''), 0)
                local r_path = reaper.GetResourcePath()
                dofile(string.format("%s\\Scripts\\Taras Scripts\\" .. idCmd .. "", r_path))
              end
              click_count = click_count + 1
           end
            r.ImGui_PopStyleColor(ctx, 3)
            r.ImGui_PopID(ctx)

          if r.ImGui_IsItemHovered(ctx) then
          r.ImGui_BeginTooltip(ctx)
           r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
               if helpText ~= '' then
           r.ImGui_TextColored(ctx, hex2rgb('#FFFFFF'), helpText)
           r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), idCmd)
               end
           r.ImGui_PopTextWrapPos(ctx)
           r.ImGui_EndTooltip(ctx)
            end

           return
end

------------------------------------------------------------------------------------------------------------------
-- Вызывается в цикле ОСТОРОЖНО

function frame(ctx)

    -- r.ImGui_LabelText(ctx, left, text)
    -- -- r.ImGui_Text(ctx, 'Hold to repeat:')
    r.ImGui_SameLine(ctx) r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'),'<(?)>')
    if r.ImGui_IsItemHovered(ctx) then
                r.ImGui_BeginTooltip(ctx)
                r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
                r.ImGui_Spacing(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#FFFFFF'),'** ABOUT SCRIPT **')
                r.ImGui_Spacing(ctx)
                r.ImGui_Separator(ctx)
                r.ImGui_Spacing(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'Script File:') r.ImGui_SameLine(ctx) r.ImGui_TextColored(ctx, hex2rgb('#FFFF00'), ListDir.scriptFileName .. '.lua')
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'Script Name:') r.ImGui_SameLine(ctx) r.ImGui_TextColored(ctx, hex2rgb('#FFFFFF'), scrName .. ' ' .. scrVersion)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'Author:')r.ImGui_SameLine(ctx)r.ImGui_TextColored(ctx, hex2rgb('#FFFF00'), scrAuthor)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'Author URL:')r.ImGui_SameLine(ctx)r.ImGui_TextColored(ctx, hex2rgb('#FFFFFF'), 'http://vk.com/tarasmetal')
                r.ImGui_Text(ctx, '')
                r.ImGui_TextColored(ctx, hex2rgb('#FF0000'), '<3')r.ImGui_SameLine(ctx)r.ImGui_Text(ctx,'&')r.ImGui_SameLine(ctx)r.ImGui_TextColored(ctx, hex2rgb('#88FF00'), 'SPECIAL THX:')
                r.ImGui_TextColored(ctx, hex2rgb('#FFFF00'), 'MPL,SuperMaximus,Aleksey Bezborodov.\n')
                r.ImGui_Spacing(ctx)
                r.ImGui_PopTextWrapPos(ctx)
                r.ImGui_EndTooltip(ctx)
      end
    r.ImGui_SameLine(ctx)
    selectedMarkers = renderFilesList(ctx, presetDir)
    if selectedMarkers then
        markersToShow = selectedMarkers
    end

    r.ImGui_SameLine(ctx)
    rv,widgets.closable = r.ImGui_Checkbox(ctx, 'ID', widgets.closable)

    r.ImGui_SameLine(ctx)HelpMarker('(?)',
      'Hidden ID number for Markers\n')
    r.ImGui_SameLine(ctx)

if not widgets.cheads then
      widgets.cheads = {
        closable_group = true,
      }
      end

    rv,widgets.cheads.closable_group = r.ImGui_Checkbox(ctx, '<', widgets.cheads.closable_group)
    -- rv,widgets.cheads.closable_group = r.ImGui_Checkbox(ctx, 'Scripts', widgets.cheads.closable_group)

        r.ImGui_SameLine(ctx) HelpMarker('(?)',
            'Show CUSTOM SCRIPTS buttons\n')

    if widgets.cheads.closable_group then
      -- rv,widgets.cheads.closable_group = r.ImGui_CollapsingHeader(ctx, 'Custom Buttons', true)
      -- if rv then
        -- r.ImGui_Spacing(ctx)
        -- r.ImGui_Text(ctx, ('IsItemHovered: %s'):format(r.ImGui_IsItemHovered(ctx)))
        r.ImGui_SameLine(ctx)
        btnCmdCol('Del M', '40613', 'Markers: Delete marker at cursor', 7.5,0)
        r.ImGui_SameLine(ctx)
        btnCmdCol('Del all M', '_SWSMARKERLIST9', 'Markers: Delete all Markers', 7,0)
        r.ImGui_SameLine(ctx)
        r.ImGui_TextDisabled(ctx, '|')
        r.ImGui_SameLine(ctx)
        btnCmdCol('Del R', '40615', 'Regions: Delete region at cursor', 7.5,0)
        r.ImGui_SameLine(ctx)
        btnCmdCol('Del all R', '_SWSMARKERLIST10', 'Regions: Delete all Regions', 7,0)
        r.ImGui_SameLine(ctx)
        r.ImGui_TextDisabled(ctx, '|')
        r.ImGui_SameLine(ctx)
        btnCmdCol('M ID', '_SWSMARKERLIST7','ReNumber Markers ID [0-9X]', 5.8,0)
        r.ImGui_SameLine(ctx)
        btnCmdCol('R ID', '_SWSMARKERLIST8','ReNumber Regions ID [0-9X]', 5.5,0)
        r.ImGui_SameLine(ctx)
        r.ImGui_TextDisabled(ctx, '|')
        r.ImGui_SameLine(ctx)
        btnCmdCol('M >> R', '_SWSMARKERLIST13','Convert all Markers to Regions', 5.2,0)
        r.ImGui_SameLine(ctx)
        btnCmdCol('R << M', '_SWSMARKERLIST14','Convert all Regions to Markers', 5.0,0)
        r.ImGui_SameLine(ctx) r.ImGui_TextDisabled(ctx, '|')r.ImGui_SameLine(ctx)
        -- btnSCRCol('File Load', 'Taras\\Tools\\trs_TrackReNameTools.lua', 'Script Load', 6.5,0) -- Load lua file script
        btnSCRCol('Set 00', 'Markers\\trs_cfillion_Set timecode at edit cursor (set to 0).lua', 'Set start 0:00:00 at edit cursor', 0,0) -- Load lua file script
        r.ImGui_SameLine(ctx)
         btnSCRCol('Bck 00', 'Markers\\trs_Set project time back.lua', 'Jump cursor to 0:00:00', 8,0) -- Load lua file script
        r.ImGui_SameLine(ctx)
        btnSCRCol('Rst 00', 'Markers\\trs_Reset project start time.lua', 'Reset project start time', 9,0) -- Load lua file script
        r.ImGui_SameLine(ctx) r.ImGui_TextDisabled(ctx, '|')r.ImGui_SameLine(ctx)
        btnSCRCol('REC', 'Markers\\trs_Insert Marker REC 666.lua', 'Insert REC 666 Marker', 0,0) -- Red -- Load lua file script
        r.ImGui_SameLine(ctx)
        btnSCRCol('BCK', 'Markers\\trs_Insert Marker go to REC 666.lua', 'Go to REC 666 Marker', 9,0) -- Green -- Load lua file script
        r.ImGui_SameLine(ctx) r.ImGui_TextDisabled(ctx, '|')r.ImGui_SameLine(ctx)
        r.ImGui_SameLine(ctx)
        btnCmdCol('+ T', '40256','Insert tempo/time sig. change marker at edit cursor...', 5.0,0)
        r.ImGui_SameLine(ctx)
        btnCmdCol('+ R', '40174','Insert Region from time selection', 5.3,0)
        r.ImGui_SameLine(ctx)
        btnCmdCol('Rename', '_RS10d3b58aeeb998ffc803441a04fdf6144ac9500f','Regions: Rename Region from track name', 5.6,0)
        -- r.ImGui_Checkbox(ctx, 'test', 0)
        -- if r.ImGui_IsItemHovered(ctx) then
        --         r.ImGui_BeginTooltip(ctx)
        --         r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
        --         r.ImGui_TextColored(ctx, hex2rgb('#FFFFFF'),'DONT WORK!')
        --         r.ImGui_TextColored(ctx, hex2rgb('#FF0000'),'SCRIPT NOT COMPLITE !!!')
        --         r.ImGui_PopTextWrapPos(ctx)
        --         r.ImGui_EndTooltip(ctx)
        --       end
    r.ImGui_SameLine(ctx)
        -- r.ImGui_Spacing(ctx)
      -- end
    end
        r.ImGui_Spacing(ctx)
        r.ImGui_Separator(ctx)
        r.ImGui_Spacing(ctx)
        r.ImGui_Text(ctx, '<')
        r.ImGui_SameLine(ctx)
        	local col = 6
           r.ImGui_PushID(ctx, col)
		   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(col / 7.0, 0.6, 0.6, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(col / 7.0, 0.7, 0.7, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(col / 7.0, 0.8, 0.8, 1.0))

        if r.ImGui_Button(ctx, 'START') then
            r.ImGui_BulletText(ctx, '•')
            insertMarkerStart("=START", ColorMap.red)
        end
            if r.ImGui_IsItemHovered(ctx) then
                r.ImGui_BeginTooltip(ctx)
                r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'Set')
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#FFFF00'), 'START')
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'project marker')
                r.ImGui_PopTextWrapPos(ctx)
                r.ImGui_EndTooltip(ctx)
              end
        r.ImGui_PopStyleColor(ctx, 3)
        r.ImGui_PopID(ctx)
        r.ImGui_SameLine(ctx)
        r.ImGui_Text(ctx, '|')


    for i = 5, #markersToShow do -- С какого элемента начинать

        buttonText = markersToShow[i].name
        color = markersToShow[i].color
        if i > 0 then
          r.ImGui_SameLine(ctx)
        end
        -- local col = i
        local col = 3 -- Зеленый
           r.ImGui_PushID(ctx, col)
		   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(col / 7.0, 0.6, 0.6, 0.6))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(col / 7.0, 0.7, 0.7, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(col / 7.0, 0.8, 0.8, 1.0))

if not widgets then
       widgets = {
        closable = true,
      }
    end
        if not widgets.closable then
          if r.ImGui_Button(ctx, buttonText) then
              insertMarker(buttonText, color, ColorMap)
          end
             if r.ImGui_IsItemHovered(ctx) then
                r.ImGui_BeginTooltip(ctx)
                r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'Insert')
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#FFFF00'), buttonText)
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#88FF00'), generateId(buttonText))
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'marker at cursor')
                r.ImGui_PopTextWrapPos(ctx)
                r.ImGui_EndTooltip(ctx)
              end
             else
          if r.ImGui_Button(ctx, buttonText) then
             	insertMarkerNoID(buttonText, color, ColorMap)
          end
          if r.ImGui_IsItemHovered(ctx) then
                r.ImGui_BeginTooltip(ctx)
                r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'Insert')
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#FFFF00'), buttonText)
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'marker at cursor')
                r.ImGui_PopTextWrapPos(ctx)
                r.ImGui_EndTooltip(ctx)
              end
        end
        r.ImGui_PopStyleColor(ctx, 3)
        r.ImGui_PopID(ctx)
        end
        r.ImGui_SameLine(ctx)
        r.ImGui_Text(ctx, '|')
        r.ImGui_SameLine(ctx)

			local col = 6
           r.ImGui_PushID(ctx, col)
		   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(col / 7.0, 0.6, 0.6, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(col / 7.0, 0.7, 0.7, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(col / 7.0, 0.8, 0.8, 1.0))

        if r.ImGui_Button(ctx, 'END') then
            insertMarkerEnd("=END",ColorMap.red)
         end
          -- if  r.ImGui_IsItemHovered(ctx) then
          --      -- local cursor_pos = r.GetCursorPosition()
          --           r.ImGui_SetTooltip(ctx, 'Set END project maker point') -- Need to Fix
          --           -- r.ImGui_SetTooltip(ctx, 'Set END point pos '.. timeEND ..' for render track') -- Need to Fix
          --   end
            if r.ImGui_IsItemHovered(ctx) then
                r.ImGui_BeginTooltip(ctx)
                r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'Set')
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#FFFF00'), 'END')
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), 'project marker')
                r.ImGui_PopTextWrapPos(ctx)
                r.ImGui_EndTooltip(ctx)
              end
        r.ImGui_PopStyleColor(ctx, 3)
        r.ImGui_PopID(ctx)
        r.ImGui_SameLine(ctx)
        r.ImGui_Text(ctx, '>')
        r.ImGui_Spacing(ctx)
end

function loop()
    local visible, open = r.ImGui_Begin(ctx, windowTitle, true)
    if visible then
        frame(ctx)
        r.ImGui_End(ctx)
    end

    if open and (not r.ImGui_IsKeyDown(ctx, 27)) then
        r.defer(loop)
    else
        r.ImGui_DestroyContext(ctx)
    end
end

r.defer(loop)

