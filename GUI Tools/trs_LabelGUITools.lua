-- @description Label GUI Tools
-- @author Taras Umanskiy
-- @version 1.0
-- @metapackage
-- @provides [main] .
-- @link http://vk.com/tarasmetal
-- @donation http://vk.com/tarasmetal
-- @about
--   # Label GUI Tools

local r = reaper
console = false

function msg(value)
  if console then
    r.ShowConsoleMsg(tostring(value) .. "\n")
  end
end

myTime = ''
scrVersion = '0.1'
scrName = 'LABEL TOOLS' .. ' ' .. scrVersion .. ' | by Taras Umanskiy'

ListDir = {}
ListDir.scriptDir, ListDir.scriptFileName = ({reaper.get_action_context()})[2]:match("(.-)([^/\\]+).lua$")

scriptDir = ListDir.scriptDir
scriptFileName = ListDir.scriptFileName

windowTitle = scrName

dofile(scriptDir .. "Functions/" .. "LabelFunctions.lua")
-----------------------------------------------------------------------------
local ctx = r.ImGui_CreateContext(windowTitle)
local size =  r.GetAppVersion():match('Win64') and 12 or 14
local Font = reaper.ImGui_CreateFont('sans-serif', 14)
r.ImGui_Attach(ctx, Font)
click_count, text = 0, '/T /E'
color = nil
-----------------------------------------------------------------------------

function round(num)
  return num ~= 0 and math.floor(num+0.5) or math.ceil(num-0.5)
end

-- function round(exact, quantum)
--     local quant,frac = math.modf(exact/quantum)
--     return quantum * (quant + (frac > 0.5 and 1 or 0))
-- end

-- function round(x, n)
--     n = math.pow(10, n or 0)
--     x = x * n
--     if x >= 0 then x = math.floor(x + 0.5) else x = math.ceil(x - 0.5) end
--     return x / n
-- end

-- function round(num)
--   return math.floor(num + .5)
-- end

function btnColor(col, i)
    r.ImGui_PushID(ctx, color)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(color / 7.0, 0.6, 0.6, 1.0))
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(color / 7.0, 0.7, 0.7, 1.0))
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(color / 7.0, 0.8, 0.8, 1.0))
end

function btnCol(name, string, col, i)
              r.ImGui_PushID(ctx, col)
              r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(col / 7.0, 0.6, 0.6, 1.0))
              r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(col / 7.0, 0.7, 0.7, 1.0))
              r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(col / 7.0, 0.8, 0.8, 1.0))
           if r.ImGui_Button(ctx, name) then
              click_count, text = 0, string
              click_count = click_count + 1
           end
           r.ImGui_PopStyleColor(ctx, 3)
           r.ImGui_PopID(ctx)
           return
end
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
           if r.ImGui_Button(ctx, ''.. name ..'') then
              --click_count, text = 0, idCmd
              if idCmd ~= nil then
                r.Main_OnCommand(r.NamedCommandLookup('' .. idCmd .. ''), 0)
                click_count = click_count - 1
              end
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
           idCmd = nil
           return
end

function frame()
  local rv
    click_count = 0
      -- local myBPM = r.GetProjectTimeSignature()
      myBPM = r.GetProjectTimeSignature2()
      myBPM = tostring(myBPM)

      r.ImGui_Text(ctx,  'Selected Items:' .. '\n')
           r.ImGui_SameLine(ctx)
           selected_items_count =  r.CountSelectedMediaItems(0)
           if selected_items_count > 0 then
                 r.ImGui_TextColored(ctx, 0x88FF00FF, selected_items_count)
               else if selected_items_count == 1 then
                 r.ImGui_TextColored(ctx, 0xFF0036FF, selected_items_count)
               else
                 r.ImGui_TextColored(ctx, 0xFF0036FF, selected_items_count)
              end
           end
      btnCmdCol('Rename takes and source files','_XENAKIOS_RENMTAKEANDSOURCE','Xenakios/SWS: Rename takes and source files... (no undo)', 7,5)
      r.ImGui_Text(ctx,  '')
      r.ImGui_TextColored(ctx, 0xFFFF00FF, 'Rename LABEL Buttons:')

      btnCol('RENAME','/T', 5,1)r.ImGui_SameLine(ctx)r.ImGui_Text(ctx,  'Name only')
      btnCol('RENAME','/T_/E', 6,2)r.ImGui_SameLine(ctx)r.ImGui_Text(ctx,  'Name Index')
      btnCol('RENAME','/T /E Tunned', 4,1)r.ImGui_SameLine(ctx)r.ImGui_Text(ctx,  'Name Tuned')
      -- btnCol('RENAME','/T Fixed', 3,1)r.ImGui_SameLine(ctx)r.ImGui_Text(ctx,  'Name Fixed')
      btnCol('RENAME','/T Click', 3,1)r.ImGui_SameLine(ctx)r.ImGui_Text(ctx,  'Name Click')

      btnCol('RENAME','/T_/E '.. round(myBPM) ..' bpm', 7,5)r.ImGui_SameLine(ctx)r.ImGui_Text(ctx,  'Name Index')r.ImGui_SameLine(ctx)r.ImGui_TextColored(ctx, 0xFFFF00FF, myBPM)r.ImGui_SameLine(ctx)r.ImGui_Text(ctx, 'BPM')
      r.ImGui_Text(ctx,  '  ')
      btnCol('GO!', text, 9,3)
      r.ImGui_SameLine(ctx)
  if click_count % 2 == 1 then
      main(text) -- Execute your main function
      notes_to_names() -- Execute your main function
      delete() -- Execute your main function
  end
      rv, text = r.ImGui_InputText(ctx, ' ',text)r.ImGui_Text(ctx,  ' ')
  end
      r.ImGui_SameLine(ctx)
      r.ImGui_TextColored(ctx, 0xFF0036FF, text)

function loop()
  r.ImGui_PushFont(ctx, font)
  r.ImGui_PopFont(ctx)
  r.ImGui_SetNextWindowSize(ctx, 180, 150,  r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, windowTitle, true)
  if visible then
    frame(ctx)
    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)
