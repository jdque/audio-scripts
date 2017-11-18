is_new_value, filename, section_id, cmd_id, mode, resolution, val = reaper.get_action_context()

control_track = reaper.GetTrack(0, 0)

state = reaper.GetExtState("electribe", "select_track")

if state == "on" then
    state = "off"
    reaper.SetMediaTrackInfo_Value(control_track, 'I_RECARM', 1)
else
    state = "on"
    reaper.SetMediaTrackInfo_Value(control_track, 'I_RECARM', 0)
end

reaper.SetExtState("electribe", "select_track", state, false)