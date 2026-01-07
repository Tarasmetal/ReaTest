-- @description Vintage BPM Analyzer
-- @author Taras Umanskiy
-- @version 1.1
-- @provides [main] .
-- @link http://vk.com/tarasmetal
-- @donation https://vk.com/Tarasmetal
-- @about Анализатор BPM аудиофайлов в винтажном ретро-стиле с красивым GUI
-- @changelog
-- + v1.1 - Fixed critical bugs
-- + Fixed WindowFlags initialization
-- + Fixed GetMediaSourceLength return values
-- + Fixed buffer:clear() syntax
-- + Fixed SetCurrentBPM function
-- + Fixed ChildFlags compatibility
-- + Code optimizations

local r = reaper

local imgui_exists = r.APIExists('ImGui_CreateContext')
if not imgui_exists then
  r.MB('ReaImGui не установлен!\n\nУстановите через ReaPack:\nExtensions > ReaPack > Browse packages > ReaImGui', 'Ошибка', 0)
  return
end

local ImGui = {}
for name, func in pairs(reaper) do
  local imgui_name = name:match('^ImGui_(.+)$')
  if imgui_name then ImGui[imgui_name] = func end
end

local COLORS = {
  bg_dark       = 0x1A1510FF,
  bg_medium     = 0x2D261EFF,
  bg_light      = 0x3D342AFF,
  bg_panel      = 0x252019FF,
  accent_gold   = 0xD4A84BFF,
  accent_amber  = 0xE8923AFF,
  accent_copper = 0xB87333FF,
  text_bright   = 0xF5E6C8FF,
  text_dim      = 0xA89880FF,
  text_dark     = 0x6B5D4DFF,
  needle_red    = 0xC94C4CFF,
  vu_green      = 0x7CB342FF,
  vu_yellow     = 0xFFD54FFF,
  vu_red        = 0xE57373FF,
  shadow        = 0x00000088,
  border        = 0x4A3F32FF,
}

local ctx = nil
local WINDOW_FLAGS = nil

local state = {
  detected_bpm = 0,
  confidence = 0,
  is_analyzing = false,
  analysis_progress = 0,
  history = {},
  selected_item_name = "Не выбрано",
  needle_angle = -45,
  target_needle_angle = -45,
  pulse_phase = 0,
}

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function ApplyVintageTheme()
  ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg(), COLORS.bg_dark)
  ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg(), COLORS.bg_panel)
  ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg(), COLORS.bg_medium)
  ImGui.PushStyleColor(ctx, ImGui.Col_Border(), COLORS.border)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg(), COLORS.bg_light)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered(), COLORS.bg_medium)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive(), COLORS.accent_copper)
  ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg(), COLORS.bg_dark)
  ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive(), COLORS.bg_medium)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text(), COLORS.text_bright)
  ImGui.PushStyleColor(ctx, ImGui.Col_TextDisabled(), COLORS.text_dim)
  ImGui.PushStyleColor(ctx, ImGui.Col_Button(), COLORS.bg_light)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), COLORS.accent_copper)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(), COLORS.accent_gold)
  ImGui.PushStyleColor(ctx, ImGui.Col_Header(), COLORS.bg_light)
  ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered(), COLORS.accent_copper)
  ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive(), COLORS.accent_gold)
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab(), COLORS.accent_gold)
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive(), COLORS.accent_amber)
  ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark(), COLORS.accent_gold)
  ImGui.PushStyleColor(ctx, ImGui.Col_Separator(), COLORS.border)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableHeaderBg(), COLORS.bg_medium)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableBorderStrong(), COLORS.border)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableBorderLight(), COLORS.bg_light)
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotHistogram(), COLORS.accent_gold)
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotHistogramHovered(), COLORS.accent_amber)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding(), 8)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding(), 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding(), 6)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding(), 6)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding(), 12, 12)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), 8, 6)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing(), 10, 8)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize(), 2)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize(), 1)
end

local function PopVintageTheme()
  ImGui.PopStyleVar(ctx, 9)
  ImGui.PopStyleColor(ctx, 26)
end

local function AnalyzeBPM()
  local item = r.GetSelectedMediaItem(0, 0)
  if not item then
    r.MB('Выберите аудио-айтем для анализа!', 'Внимание', 0)
    return
  end
  local take = r.GetActiveTake(item)
  if not take then
    r.MB('Айтем не содержит take!', 'Ошибка', 0)
    return
  end
  if r.TakeIsMIDI(take) then
    r.MB('Выберите аудио-айтем, не MIDI!', 'Ошибка', 0)
    return
  end
  local source = r.GetMediaItemTake_Source(take)
  if not source then return end
  local filename = r.GetMediaSourceFileName(source)
  state.selected_item_name = filename:match("([^/\\]+)$") or "Unknown"
  state.is_analyzing = true
  state.analysis_progress = 0
  local source_length, _ = r.GetMediaSourceLength(source)
  r.Main_OnCommand(40635, 0)
  local project_bpm = r.Master_GetTempo()
  local accessor = r.CreateTakeAudioAccessor(take)
  if accessor then
    local samplerate = r.GetMediaSourceSampleRate(source)
    local numchannels = r.GetMediaSourceNumChannels(source)
    local samples_per_block = 1024
    local buffer = r.new_array(samples_per_block * numchannels)
    local peaks = {}
    local threshold = 0.3
    local last_peak_pos = 0
    local min_peak_distance = samplerate * 0.2
    local total_samples = source_length * samplerate
    local current_pos = 0
    while current_pos < total_samples and current_pos < samplerate * 30 do
      buffer:clear()
      r.GetAudioAccessorSamples(accessor, samplerate, numchannels, current_pos / samplerate, samples_per_block, buffer)
      for i = 1, samples_per_block do
        local sample = math.abs(buffer[i] or 0)
        if sample > threshold and (current_pos + i - last_peak_pos) > min_peak_distance then
          table.insert(peaks, current_pos + i)
          last_peak_pos = current_pos + i
        end
      end
      current_pos = current_pos + samples_per_block
      state.analysis_progress = math.min(current_pos / math.min(total_samples, samplerate * 30), 1)
    end
    r.DestroyAudioAccessor(accessor)
    if #peaks > 2 then
      local intervals = {}
      for i = 2, #peaks do
        local interval = (peaks[i] - peaks[i-1]) / samplerate
        if interval > 0.25 and interval < 2.0 then
          table.insert(intervals, interval)
        end
      end
      if #intervals > 0 then
        table.sort(intervals)
        local median_interval = intervals[math.floor(#intervals / 2) + 1]
        local detected = 60 / median_interval
        while detected < 60 do detected = detected * 2 end
        while detected > 180 do detected = detected / 2 end
        state.detected_bpm = math.floor(detected + 0.5)
        state.confidence = math.min(#intervals / 20, 1) * 100
      else
        state.detected_bpm = math.floor(project_bpm + 0.5)
        state.confidence = 30
      end
    else
      state.detected_bpm = math.floor(project_bpm + 0.5)
      state.confidence = 20
    end
  else
    state.detected_bpm = math.floor(project_bpm + 0.5)
    state.confidence = 10
  end
  table.insert(state.history, 1, {
    name = state.selected_item_name,
    bpm = state.detected_bpm,
    confidence = state.confidence,
    time = os.date("%H:%M:%S")
  })
  while #state.history > 10 do
    table.remove(state.history)
  end
  state.target_needle_angle = ((state.detected_bpm - 60) / 140) * 90 - 45
  state.is_analyzing = false
  state.analysis_progress = 1
end

local function DrawVintageDisplay()
  local draw_list = ImGui.GetWindowDrawList(ctx)
  local pos_x, pos_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w = ImGui.GetContentRegionAvail(ctx)
  local display_w = math.min(avail_w, 380)
  local display_h = 200
  local center_x = pos_x + display_w / 2
  local center_y = pos_y + display_h - 40
  ImGui.DrawList_AddRectFilled(draw_list, pos_x, pos_y, pos_x + display_w, pos_y + display_h, COLORS.bg_panel, 10)
  ImGui.DrawList_AddRect(draw_list, pos_x, pos_y, pos_x + display_w, pos_y + display_h, COLORS.accent_copper, 10, 0, 3)
  ImGui.DrawList_AddRect(draw_list, pos_x + 10, pos_y + 10, pos_x + display_w - 10, pos_y + display_h - 10, COLORS.border, 6, 0, 1)
  ImGui.DrawList_AddText(draw_list, pos_x + display_w/2 - 60, pos_y + 15, COLORS.accent_gold, "♦ BPM METER ♦")
  local radius = 100
  for i = 0, 10 do
    local bpm_val = 60 + i * 14
    local angle = math.rad(-135 + i * 18)
    local x1 = center_x + math.cos(angle) * (radius - 10)
    local y1 = center_y + math.sin(angle) * (radius - 10)
    local x2 = center_x + math.cos(angle) * radius
    local y2 = center_y + math.sin(angle) * radius
    local tick_color = COLORS.text_dim
    if i > 7 then tick_color = COLORS.vu_red
    elseif i > 4 then tick_color = COLORS.vu_yellow end
    ImGui.DrawList_AddLine(draw_list, x1, y1, x2, y2, tick_color, 2)
    local text_x = center_x + math.cos(angle) * (radius - 25) - 10
    local text_y = center_y + math.sin(angle) * (radius - 25) - 6
    ImGui.DrawList_AddText(draw_list, text_x, text_y, COLORS.text_dim, tostring(bpm_val))
  end
  state.needle_angle = lerp(state.needle_angle, state.target_needle_angle, 0.08)
  local needle_rad = math.rad(-90 + state.needle_angle)
  local needle_len = radius - 20
  local needle_x = center_x + math.cos(needle_rad) * needle_len
  local needle_y = center_y + math.sin(needle_rad) * needle_len
  ImGui.DrawList_AddLine(draw_list, center_x + 2, center_y + 2, needle_x + 2, needle_y + 2, COLORS.shadow, 4)
  ImGui.DrawList_AddLine(draw_list, center_x, center_y, needle_x, needle_y, COLORS.needle_red, 3)
  ImGui.DrawList_AddCircleFilled(draw_list, center_x, center_y, 8, COLORS.accent_copper)
  ImGui.DrawList_AddCircle(draw_list, center_x, center_y, 8, COLORS.accent_gold, 0, 2)
  local bpm_text = string.format("%d", state.detected_bpm)
  ImGui.DrawList_AddRectFilled(draw_list, center_x - 45, pos_y + 45, center_x + 45, pos_y + 80, COLORS.bg_dark, 4)
  ImGui.DrawList_AddRect(draw_list, center_x - 45, pos_y + 45, center_x + 45, pos_y + 80, COLORS.accent_copper, 4, 0, 1)
  state.pulse_phase = state.pulse_phase + 0.1
  local bpm_color = state.is_analyzing and COLORS.accent_amber or COLORS.accent_gold
  ImGui.DrawList_AddText(draw_list, center_x - 25, pos_y + 52, bpm_color, bpm_text)
  ImGui.Dummy(ctx, display_w, display_h)
end

local function DrawConfidenceMeter()
  local draw_list = ImGui.GetWindowDrawList(ctx)
  local pos_x, pos_y = ImGui.GetCursorScreenPos(ctx)
  local meter_w = ImGui.GetContentRegionAvail(ctx)
  local meter_h = 30
  ImGui.DrawList_AddRectFilled(draw_list, pos_x, pos_y, pos_x + meter_w, pos_y + meter_h, COLORS.bg_dark, 4)
  ImGui.DrawList_AddRect(draw_list, pos_x, pos_y, pos_x + meter_w, pos_y + meter_h, COLORS.border, 4, 0, 1)
  local fill_w = (meter_w - 8) * (state.confidence / 100)
  local fill_color = COLORS.vu_green
  if state.confidence > 70 then fill_color = COLORS.vu_green
  elseif state.confidence > 40 then fill_color = COLORS.vu_yellow
  else fill_color = COLORS.vu_red end
  ImGui.DrawList_AddRectFilled(draw_list, pos_x + 4, pos_y + 4, pos_x + 4 + fill_w, pos_y + meter_h - 4, fill_color, 2)
  for i = 1, 9 do
    local x = pos_x + (meter_w / 10) * i
    ImGui.DrawList_AddLine(draw_list, x, pos_y + 4, x, pos_y + meter_h - 4, COLORS.bg_panel, 1)
  end
  local conf_text = string.format("Уверенность: %.0f%%", state.confidence)
  ImGui.DrawList_AddText(draw_list, pos_x + meter_w/2 - 50, pos_y + 8, COLORS.text_bright, conf_text)
  ImGui.Dummy(ctx, meter_w, meter_h)
end

local function MainWindow()
  ApplyVintageTheme()
  ImGui.SetNextWindowSize(ctx, 420, 580, ImGui.Cond_FirstUseEver())
  local visible, open = ImGui.Begin(ctx, '♦ VINTAGE BPM ANALYZER ♦', true, WINDOW_FLAGS)
  if visible then
    ImGui.PushStyleColor(ctx, ImGui.Col_Text(), COLORS.accent_gold)
    ImGui.SeparatorText(ctx, "◈ TEMPO DETECTOR ◈")
    ImGui.PopStyleColor(ctx)
    ImGui.Spacing(ctx)
    DrawVintageDisplay()
    ImGui.Spacing(ctx)
    DrawConfidenceMeter()
    ImGui.Spacing(ctx)
    ImGui.Separator(ctx)
    ImGui.Spacing(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text(), COLORS.text_dim)
    ImGui.Text(ctx, "Файл:")
    ImGui.PopStyleColor(ctx)
    ImGui.SameLine(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text(), COLORS.accent_gold)
    ImGui.Text(ctx, state.selected_item_name)
    ImGui.PopStyleColor(ctx)
    ImGui.Spacing(ctx)
    local btn_w = (ImGui.GetContentRegionAvail(ctx) - 10) / 2
    ImGui.PushStyleColor(ctx, ImGui.Col_Button(), COLORS.accent_copper)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), COLORS.accent_gold)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(), COLORS.accent_amber)
    if ImGui.Button(ctx, "◉ АНАЛИЗ", btn_w, 40) then
      AnalyzeBPM()
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "✓ ПРИМЕНИТЬ", btn_w, 40) then
      if state.detected_bpm > 0 then
        r.SetCurrentBPM(0, state.detected_bpm, true)
        r.MB(string.format("BPM проекта установлен: %d", state.detected_bpm), "Успех", 0)
      end
    end
    ImGui.PopStyleColor(ctx, 3)
    if state.is_analyzing then
      ImGui.Spacing(ctx)
      ImGui.ProgressBar(ctx, state.analysis_progress, -1, 0, "Анализ...")
    end
    ImGui.Spacing(ctx)
    ImGui.Separator(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text(), COLORS.accent_gold)
    ImGui.SeparatorText(ctx, "◈ ИСТОРИЯ ◈")
    ImGui.PopStyleColor(ctx)
    local child_flags = ImGui.ChildFlags_Border and ImGui.ChildFlags_Border() or 1
    if ImGui.BeginChild(ctx, "history", 0, 150, child_flags) then
      if #state.history == 0 then
        ImGui.PushStyleColor(ctx, ImGui.Col_Text(), COLORS.text_dim)
        ImGui.Text(ctx, "История пуста...")
        ImGui.PopStyleColor(ctx)
      else
        for _, entry in ipairs(state.history) do
          local conf_icon = "●"
          local conf_color = COLORS.vu_green
          if entry.confidence < 40 then
            conf_icon = "○"
            conf_color = COLORS.vu_red
          elseif entry.confidence < 70 then
            conf_icon = "◐"
            conf_color = COLORS.vu_yellow
          end
          ImGui.PushStyleColor(ctx, ImGui.Col_Text(), conf_color)
          ImGui.Text(ctx, conf_icon)
          ImGui.PopStyleColor(ctx)
          ImGui.SameLine(ctx)
          ImGui.PushStyleColor(ctx, ImGui.Col_Text(), COLORS.text_bright)
          ImGui.Text(ctx, string.format("%d BPM", entry.bpm))
          ImGui.PopStyleColor(ctx)
          ImGui.SameLine(ctx)
          ImGui.PushStyleColor(ctx, ImGui.Col_Text(), COLORS.text_dim)
          ImGui.Text(ctx, string.format("- %s [%s]", entry.name:sub(1, 20), entry.time))
          ImGui.PopStyleColor(ctx)
        end
      end
      ImGui.EndChild(ctx)
    end
    ImGui.Spacing(ctx)
    ImGui.Separator(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text(), COLORS.text_dark)
    ImGui.Text(ctx, "♦ Vintage BPM Analyzer v1.1 ♦")
    ImGui.PopStyleColor(ctx)
  end
  ImGui.End(ctx)
  PopVintageTheme()
  return open
end

local function Init()
  ctx = ImGui.CreateContext('Vintage BPM Analyzer')
  WINDOW_FLAGS = ImGui.WindowFlags_NoCollapse()
end

local function Loop()
  local open = MainWindow()
  if open then
    r.defer(Loop)
  else
    ImGui.DestroyContext(ctx)
  end
end

Init()
Loop()
