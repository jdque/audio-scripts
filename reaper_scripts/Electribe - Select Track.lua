is_new_value, filename, section_id, cmd_id, mode, resolution, val = reaper.get_action_context()

select_track_state = reaper.GetExtState("electribe", "select_track")
if select_track_state == "on" then
    selectTrack()
end

local function selectTrack()
    --TODO - get track number from filename instead
    --convert MIDI velocity value to track number
    track_idx = math.floor(val / 8) + 1
    if track_idx < reaper.GetNumTracks() then
        return
    end

    --unselect currently selected item
    sel_item = reaper.GetSelectedMediaItem(0, 0)
    if sel_item ~= nil then
        reaper.SetMediaItemSelected(sel_item, false)
    end

    --select new track
    track = reaper.GetTrack(0, track_idx)
    reaper.SetOnlyTrackSelected(track)

    --select first item in new track
    first_item = reaper.GetTrackMediaItem(track, 0)
    if first_item ~= nil then
        reaper.SetMediaItemSelected(first_item, true)
    end

    reaper.UpdateArrange()
end