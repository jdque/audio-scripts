isNewValue, fileName, sectionId, cmdId, mode, resolution, value = reaper.get_action_context()

inputEditModal = reaper.GetExtState("electribe", "input_edit_modal")
if inputEditModal == "on" then
  --TODO
end

trackEditModal = reaper.GetExtState("electribe", "track_edit_modal")
if trackEditModal == "on" then
  SelectTrack()
end

mode = reaper.GetExtState("electribe", "mode")
if mode == "sequencer" then
  ToggleNoteOnOff()
end

local function SelectTrack()
  trackIdx = GetTrackIndex(fileName)
  track = reaper.GetTrack(0, trackIdx)
  if track == nil then
    return
  end

  --unselect currently selected item
  selectedItem = reaper.GetSelectedMediaItem(0, 0)
  if selectedItem ~= nil then
    reaper.SetMediaItemSelected(selectedItem, false)
  end

  --select new track
  reaper.SetOnlyTrackSelected(track)

  --select first item in new track
  firstItem = reaper.GetTrackMediaItem(track, 0)
  if firstItem ~= nil then
    reaper.SetMediaItemSelected(firstItem, true)
  end

  reaper.UpdateArrange()
end

local function ToggleNoteOnOff()
  trackIdx = GetTrackIndex(fileName)
  track = reaper.GetTrack(0, trackIdx)
  if track == nil then
    return
  end

  selectedItem = reaper.GetSelectedMediaItem(0, 0)
  if selectedItem == nil then
    return
  end

  --get measure position
  --get all notes at position
  --delete notes, otherwise insert C4 note
end

local function GetTrackIndex(fileName)
  return tonumber(fileName:sub(fileName:find('%(') + 1, fileName:find('%)') - 1))
end