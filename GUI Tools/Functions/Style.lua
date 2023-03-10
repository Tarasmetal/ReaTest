--@noindex

function PushStyle()
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),             0x1B1B1BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(),              0x0F0F0FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),              0x0000008A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),       0x9B9B9B66)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),        0x9B9B9BBA)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),        0x9B9B9BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),          0x3D3D3D87)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),        0x5A5959FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0x747474FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  0x8D8D8DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),            0x29EDFF37)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),           0x29EDFF71)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(),     0x29EDFFAC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),            0x20E9FB80)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),     0x20E9FBC5)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),      0x20E9FBFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),        0x18E9ED59)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), 0x18E9ED7C)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),  0x18E9EDFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),               0x29EDFF37)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),        0x29EDFF71)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),         0x29EDFFAC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),            0x6192AC61)

    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(),  4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(),   3)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(),   4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),   3)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(), 1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),    3)
end

function PopStyle()
    reaper.ImGui_PopStyleVar(ctx, 6)
    reaper.ImGui_PopStyleColor(ctx, 23)
end