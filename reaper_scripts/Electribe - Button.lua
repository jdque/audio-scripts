isNewValue, fileName, sectionId, cmdId, mode, resolution, value = reaper.get_action_context()

inputEditModal = reaper.GetExtState("electribe", "input_edit_modal")
if inputEditModal == "on" then
  InputEditAction()
end

trackEditModal = reaper.GetExtState("electribe", "track_edit_modal")
if trackEditModal == "on" then
  TrackEditAction()
end

mode = reaper.GetExtState("electribe", "mode")
if mode == "sequencer" then
  --TODO
end

local function InputEditAction()
  action = GetAction(fileName)

  if action == "input_drum_mode" then
    reaper.SetExtState("electribe", "mode", "drum", false)
  elseif action == "input_piano_mode" then
    reaper.SetExtState("electribe", "mode", "piano", false)
  elseif action == "input_sequencer_mode" then
    reaper.SetExtState("electribe", "mode", "sequencer", false)
  end
end

local function TrackEditAction()
  action = GetAction(fileName)

  if action == "track_mute" then
    track = reaper.GetSelectedTrack(0, 0)
    if track != nil then
      isMuted = reaper.GetMediaTrackInfo_Value(track, 'B_MUTE')
      reaper.SetMediaTrackInfo_Value(track, 'B_MUTE', !isMuted)
    end
  elseif action == "track_erase" then
    item = reaper.GetSelectedMediaItem(0, 0)
    if item != nil then
      --DELETE NOTES
    end
  end
end

local function GetAction(fileName)
  return fileName:sub(fileName:find('%(') + 1, fileName:find('%)') - 1)
end