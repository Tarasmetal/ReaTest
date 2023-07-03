-- @description trs_Marker Set START_END by time sel
-- @author Taras Umanskiy
-- @version 1.0
-- @metapackage
-- @provides [main] .
-- @link http://vk.com/tarasmetal
-- @donation https://paypal.me/Tarasmetal
-- @about
--  # trs_Marker Set START_END by time sel
-- @changelog
--  + Code Fixies

if not reaper.APIExists("JS_Window_Find") then
  reaper.ShowMessageBox("Необходимо установить SWS/S&M Extension", "Ошибка", 0)
end

console = false

function msg(value)
  if console then
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
  end
end

local nameLeft = '=START'
local nameRight = '=END'

function setStartEndMarkers()
  local markerCount = reaper.CountProjectMarkers(0)
  local markersToDelete = {}

  for i = 0, markerCount - 1 do
    local _, isrgn, pos, rgnend, name, id = reaper.EnumProjectMarkers(i)

    if name:find("START") then
      -- msg(name .. " - " .. id)
      table.insert(markersToDelete, i)
    end
    if name:find("END") then
      -- msg(name .. " - " .. id)
      table.insert(markersToDelete, i)
    end
  end
  -- msg(" All Markers: " .. markerCount)

  for i = #markersToDelete, 1, -1 do
    reaper.DeleteProjectMarkerByIndex(0, markersToDelete[i])
    -- msg(markersToDelete[i])
  end
    -------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------
    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0); -- В Аранже
    if timeSelStart==timeSelEnd then no_undo() return end;
    reaper.Undo_BeginBlock();
    reaper.PreventUIRefresh(1);
    local color = reaper.ColorToNative(255,0,255)|0x1000000
    reaper.AddProjectMarker2(0,0,timeSelStart,0, nameLeft, 0, color)
    reaper.AddProjectMarker2(0,0,timeSelEnd,0, nameRight, 99, color)
    reaper.PreventUIRefresh(-1);
    reaper.Undo_EndBlock('trs_Insert • start_end markers by time selection',-1);
    reaper.UpdateArrange();
end