local function GetTrackIndex(fileName)
  return tonumber(fileName:sub(fileName:find('%(') + 1, fileName:find('%)') - 1))
end

local function SelectTrack()
  trackIdx = GetTrackIndex(fileName)
  track = reaper.GetTrack(0, trackIdx)
  if track == nil then
    return
  end

  --unselect currently selected item
  selItem = reaper.GetSelectedMediaItem(0, 0)
  if selItem ~= nil then
    reaper.SetMediaItemSelected(selItem, false)
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

local function MuteTrack()
  trackIdx = GetTrackIndex(fileName)
  track = reaper.GetTrack(0, trackIdx)
  if track == nil then
    return
  end

  selItem = reaper.GetSelectedMediaItem(0, 0)
  if selItem == nil then
    return
  end

  isMuted = reaper.GetMediaItemInfo_Value(selItem, 'B_MUTE')
  reaper.SetMediaItemInfo_Value(selItem, 'B_MUTE', isMuted == 0 and 1 or 0)

  reaper.UpdateArrange()
end

local function EraseTrack()
  trackIdx = GetTrackIndex(fileName)
  track = reaper.GetTrack(0, trackIdx)
  if track == nil then
    return
  end

  selItem = reaper.GetSelectedMediaItem(0, 0)
  if selItem == nil then
    return
  end

  --select all MIDI items in active take
  selTake = reaper.GetActiveTake(selItem)
  reaper.MIDI_SelectAll(selTake, true)

  --delete notes
  while true do
    if not reaper.MIDI_DeleteNote(selTake, 0) then
      break
    end
  end

  --delete CC's
  while true do
    if not reaper.MIDI_DeleteCC(selTake, 0) then
      break
    end
  end

  reaper.UpdateArrange()
end

local function ToggleNoteOnOff()
  track = reaper.GetSelectedTrack(0, 0)
  if track == nil then
    return
  end

  selItem = reaper.GetSelectedMediaItem(0, 0)
  if selItem == nil then
    return
  end

  --get measure position
  --get all notes at position
  --delete notes, otherwise insert C4 note
end

isNewValue, fileName, sectionId, cmdId, mode, resolution, value = reaper.get_action_context()

inputEditModal = reaper.GetExtState("electribe", "edit_input_modal")
if inputEditModal == "on" then
  --TODO
end

trackEditModal = reaper.GetExtState("electribe", "edit_track_modal")
if trackEditModal == "on" then
  SelectTrack()
end

muteTrackModal = reaper.GetExtState("electribe", "mute_track_modal")
if muteTrackModal == "on" then
  MuteTrack()
end

eraseTrackModal = reaper.GetExtState("electribe", "erase_track_modal")
if eraseTrackModal == "on" then
  EraseTrack()
end

mode = reaper.GetExtState("electribe", "mode")
if mode == "sequencer" then
  ToggleNoteOnOff()
end