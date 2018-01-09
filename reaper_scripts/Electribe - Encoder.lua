local RP = reaper
local ROOT_NOTE = 48

-----------------------------------------------------------

local function GetAction(fileName)
  return fileName:sub(fileName:find('%(') + 1, fileName:find('%)') - 1)
end

local function GetSelectedTrackIndex()
  local selTrackIdx = -1
  for i = 0, RP.CountTracks(0) - 1 do
    if RP.IsTrackSelected(RP.GetTrack(0, i)) then
      selTrackIdx = i
      break
    end
  end
  return selTrackIdx
end

-----------------------------------------------------------

local function TransposeSelectedTrackInput()
  _, _, _, _, _, _, value = RP.get_action_context()

  selTrackIdx = GetSelectedTrackIndex()
  if selTrackIdx < 0 then
    return
  end

  channel = selTrackIdx - 1
  adjValue = value - 64

  controlTrack = RP.GetTrack(0, 0)
  transposeFx = RP.TrackFX_GetByName(controlTrack, "MIDI Transpose Channels", false)
  RP.TrackFX_SetParam(controlTrack, transposeFx, channel, adjValue)
end

local function ProgramChange()
  -- if selected instrument is sampler, change sample, otherwise change preset
end

local function SelectChord()
  _, _, _, _, _, _, value = RP.get_action_context()

  controlTrack = RP.GetTrack(0, 0)
  tonespaceFx = RP.TrackFX_GetByName(controlTrack, "tonespace (mucoder)", false)
  RP.TrackFX_SetParam(controlTrack, tonespaceFx, 5, value / 127)

  --disable tonespace fx if chord param is set to unison (0), so it doesn't block polyphony
  shouldEnable = (value > 0)
  RP.TrackFX_SetEnabled(controlTrack, tonespaceFx, shouldEnable)
end

local function SelectVoicing()
  _, _, _, _, _, _, value = RP.get_action_context()

  controlTrack = RP.GetTrack(0, 0)
  tonespaceFx = RP.TrackFX_GetByName(controlTrack, "tonespace (mucoder)", false)
  RP.TrackFX_SetParam(controlTrack, tonespaceFx, 6, value / 127)
end

-----------------------------------------------------------

local function Main()
  _, fileName, _, _, _, _, _ = RP.get_action_context()

  action = GetAction(fileName)
  if action == "transpose" then
    TransposeSelectedTrackInput()
  elseif action == "program_change" then
    ProgramChange()
  elseif action == "select_chord" then
    SelectChord()
  elseif action == "select_voicing" then
    SelectVoicing()
  end
end

RP.defer(Main)