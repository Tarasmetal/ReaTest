-- @description Label Functions
-- @author Taras Umanskiy
-- @version 1.0
-- @metapackage
-- @provides [nomain] .
-- @link http://vk.com/tarasmetal
-- @donation https://paypal.me/Tarasmetal
-- @about
--   # Label Functions
-- @changelog
--  + Code optimizations

function AddZerosAndOffset(number, zeros, offset)

    local number = number + offset

    number = tostring(number)

    number = string.format('%0' .. zeros .. 'd', number)
    msg(number)

    return number

end


function ProcessKeyword(input, number, keyword)

    local zeros, offset = input:match(keyword .. "(%d+)_([^,]+)_")

    if zeros or offset then
        msg('zeros = ' .. zeros)
        msg('offset = ' .. offset)
        local number = AddZerosAndOffset(number, zeros, offset)
        input = input:gsub(keyword .. "(%d+)_([^,]+)_", tostring(number))
    else
        input = input:gsub(keyword, tostring(number))
    end

    return input

end

------------------------------------------------------------------------------------------------------------------

function round(num)
  return num ~= 0 and math.floor(num+0.5) or math.ceil(num-0.5)
end

function RgbaToArgb(rgba)
  return (rgba >> 8 & 0x00FFFFFF) | (rgba << 24 & 0xFF000000)
end

function ArgbToRgba(argb)
  return (argb << 8) | (argb >> 24 & 0xFF)
end

-- function round(n)
--   return math.floor(n + .5)
-- end

function clamp(v, mn, mx)
  if v < mn then return mn end
  if v > mx then return mx end
  return v
end

function Link(url)
  if not r.CF_ShellExecute then
    r.ImGui_Text(ctx, url)
    return
  end

  local color = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_CheckMark())
  r.ImGui_TextColored(ctx, color, url)
  if r.ImGui_IsItemClicked(ctx) then
    r.CF_ShellExecute(url)
  elseif r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_Hand())
  end
end

function trs_HSV(h, s, v, a)
  local r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v)
  return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    if HEX_COLOR == nil then
        HEX_COLOR = '#FFFFFF'
    end
    local hex = HEX_COLOR:sub(2)
    return '0x' .. hex .. 'FF'
end
------------------------------------------------------------------------------------------------------------------
function main(text)

    reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the

    -- INITIALIZE loop through selected items
    for i = 0, selected_items_count-1  do
        -- GET ITEMS
        item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i

        track = reaper.GetMediaItemTrack(item)
        track_id = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        track_name_retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)

        -- Some possible keywords from SWS label processor
        -- /D -- Duration
        -- /E[digits, first] -- enumerate in selection
        -- /e[digits, first] -- enumerate in selection on track
        -- /I[digits, first] -- inverse enumerate in selection
        -- /i[digits, first] -- inverse enumerate in selection on track
        -- /T[offset, length] -- Track name
        -- /t[digits] -- Track number

        input = text
        msg('input = ' .. input)

        if string.find(input, "/E") then
            number = i + 1

            input  = ProcessKeyword(input, number, "/E")
        end

        if string.find(input, "/I") then
            number = selected_items_count - i

            input  = ProcessKeyword(input, number, "/I")
        end

        input = input:gsub("/T", track_name)
        input = input:gsub("/t", tostring(track_id))
        item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        markeridx, regionidx = reaper.GetLastMarkerAndCurRegion( 0, item_pos )
        retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers( regionidx )
        input = input:gsub("/r", name )

        notes = reaper.ULT_GetMediaItemNote(item)
        input = input:gsub("$notes", notes )
        input = input:gsub("\\n", "\r\n" )

        reaper.ULT_SetMediaItemNote(item, input)

    end -- end of items loop

    reaper.Undo_EndBlock("Add text to selected items notes (Items Names Processor)", -1) -- End of the undo block. Leave it at the bottom of your main function

end -- end of function

------------------------------------------------------------------------------------------------------------
function notes_to_names() -- local (i, j, item, take, track)

    reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.
    -- LOOP THROUGH SELECTED ITEMS
    selected_items_count = reaper.CountSelectedMediaItems(0)
    -- INITIALIZE loop through selected items
    for i = 0, selected_items_count-1  do
        -- GET ITEMS
        item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i
        take = reaper.GetActiveTake(item)
        if take ~= nil then
            -- GET NOTES
            note = reaper.ULT_GetMediaItemNote(item)
            note = note:gsub("\n", " ")
            --reaper.ShowConsolemsg(note)
            -- MODIFY TAKE
            retval, stringNeedBig = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", note, 1)
        end
    end -- ENDLOOP through selected items
    reaper.Undo_EndBlock("Convert selected item to take name", 0) -- End of the undo block. Leave it at the bottom of your main function.
end

-- notes_to_names() -- Execute your main function

------------------------------------------------------------------------------------------------------------
function delete() -- local (i, j, item, take, track)
    reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.
    -- LOOP THROUGH SELECTED ITEMS
    selected_items_count = reaper.CountSelectedMediaItems(0)
    -- INITIALIZE loop through selected items
    for i = 0, selected_items_count-1  do
        -- GET ITEMS
        item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i
        -- MODIFY NOTES
        note = ""
        -- SET NOTES
        reaper.ULT_SetMediaItemNote(item, note)
    end -- ENDLOOP through selected items
    reaper.Undo_EndBlock("Delete selected items names", 0) -- End of the undo block. Leave it at the bottom of your main function.
end

-- delete() -- Execute your main function
------------------------------------------------------------------------------------------------------------
reaper.UpdateArrange() -- Update the arrangement (often needed)
reaper.PreventUIRefresh(-1)
