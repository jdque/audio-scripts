isNewValue, fileName, sectionId, cmdId, mode, resolution, value = reaper.get_action_context()

stateName = GetStateName(fileName)
state = reaper.GetExtState("electribe", stateName)

controlTrack = reaper.GetTrack(0, 0)

if state == "on" then
  state = "off"
  reaper.SetMediaTrackInfo_Value(controlTrack, 'I_RECARM', 1)
else
  state = "on"
  reaper.SetMediaTrackInfo_Value(controlTrack, 'I_RECARM', 0)
end

reaper.SetExtState("electribe", stateName, state, false)

local function GetStateName(fileName)
  return fileName:sub(fileName:find('%(') + 1, fileName:find('%)') - 1)
end