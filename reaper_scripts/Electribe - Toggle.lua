local RP = reaper
local ROOT_NOTE = 48

local MODALS = {
  ["mute_modal"]  = 0x8, -- 1000
  ["erase_modal"] = 0x4, -- 0100
  ["copy_modal"]  = 0x2, -- 0010
  ["edit_modal"]  = 0x1  -- 0001
}

-----------------------------------------------------------

local function GetStateName(fileName)
  return fileName:sub(fileName:find('%(') + 1, fileName:find('%)') - 1)
end

local function OutAllPadsOff()
  for note = ROOT_NOTE, ROOT_NOTE + 16 do
    RP.StuffMIDIMessage(0, 128, note, 0)
  end
end

local function OutSelectedTrack()
  for trackIdx = 0, RP.CountTracks(0) - 1 do
    if RP.IsTrackSelected(RP.GetTrack(0, trackIdx)) == true then
      RP.StuffMIDIMessage(0, 144, (trackIdx + ROOT_NOTE) - 1, 127)
      break
    end
  end
end

local function OutStepNotes()
  selItem = RP.GetSelectedMediaItem(0, 0)
  selTake = RP.GetMediaItemTake(selItem, 0)

  takeStartSec = RP.GetMediaItemInfo_Value(selItem, "D_POSITION")
  takeEndSec =  takeStartSec + RP.GetMediaItemInfo_Value(selItem, "D_LENGTH")
  takeStartPPQ = RP.MIDI_GetPPQPosFromProjTime(selTake, takeStartSec)
  takeEndPPQ = RP.MIDI_GetPPQPosFromProjTime(selTake, takeEndSec)
  takeStartQN = RP.MIDI_GetProjQNFromPPQPos(selTake, takeStartPPQ)
  takeEndQN = RP.MIDI_GetProjQNFromPPQPos(selTake, takeEndPPQ)

  retval, numNotes, _, _ = RP.MIDI_CountEvts(selTake)
  for noteIdx = 0, numNotes - 1 do
    retval, _, _, noteStartPPQ, noteEndPPQ, _, _, _ = RP.MIDI_GetNote(selTake, noteIdx)
    noteStartQN = RP.MIDI_GetProjQNFromPPQPos(selTake, noteStartPPQ)
    relNoteStartQN = noteStartQN - takeStartQN
    snappedQN = relNoteStartQN - (relNoteStartQN % (1 / 4))
    step = math.floor(4 * snappedQN)

    RP.StuffMIDIMessage(0, 144, (step + ROOT_NOTE), 127)
  end
end

-----------------------------------------------------------

local function SetModeFXEnabled(modeFxName, enabled)
  controlTrack = RP.GetTrack(0, 0)
  startToggle = false
  for idx = 0, RP.TrackFX_GetCount(controlTrack) - 1 do
    retval, fxName = RP.TrackFX_GetFXName(controlTrack, idx, "")
    if fxName == "END" and startToggle == true then
      break
    elseif fxName == modeFxName then
      startToggle = true
    elseif startToggle then
      RP.TrackFX_SetEnabled(controlTrack, idx, enabled)
    end
  end
end

local function ToggleModal(modalName)
  _, _, _, _, _, _, value = RP.get_action_context()

  toggleModal = MODALS[modalName]
  curModals = tonumber(RP.GetExtState("electribe", "modals"))
  curModals = curModals ~= nil and curModals or 0x0
  isToggleOn = nil

  if value > 0 then
    isToggleOn = true
    newModals = curModals | toggleModal --bit on
  else
    isToggleOn = false
    newModals = curModals & (~toggleModal & 0xf) --bit off
  end

  RP.SetExtState("electribe", "modals", newModals, false)

  -- turn off record arm on control track to block note input
  controlTrack = RP.GetTrack(0, 0)
  if newModals == 0x0 then
    RP.SetMediaTrackInfo_Value(controlTrack, 'I_RECARM', 1)
  else
    RP.SetMediaTrackInfo_Value(controlTrack, 'I_RECARM', 0)
  end

  -- TODO: move
  curMode = RP.GetExtState("electribe", "mode")
  if curMode ~= "sequencer" then
    OutAllPadsOff()
    if isToggleOn then
      OutSelectedTrack()
    end
  end
end

local function CycleMode()
  _, _, _, _, _, _, value = RP.get_action_context()
  if value ~= 127 then
    return
  end

  curMode = RP.GetExtState("electribe", "mode")
  newMode = nil
  if curMode == "piano" then
    newMode = "drum"
    SetModeFXEnabled("PIANO", false)
  elseif curMode == "drum" then
    newMode = "sequencer"
    SetModeFXEnabled("DRUM", false)
  else
    newMode = "piano"
    SetModeFXEnabled("SEQUENCER", false)
  end
  RP.SetExtState("electribe", "mode", newMode, false)

  controlTrack = RP.GetTrack(0, 0)

  if newMode == "piano" then
    RP.GetSetMediaTrackInfo_String(controlTrack, "P_NAME", "PIANO", true)
    SetModeFXEnabled("PIANO", true)

    -- TODO: move somewhere else
    -- deactivate tonespace fx if its chord param is set to unison (0)
    tonespaceFx = RP.TrackFX_GetByName(controlTrack, "tonespace (mucoder)", false)
    chordVal, _, _ = RP.TrackFX_GetParam(controlTrack, tonespaceFx, 5)
    if chordVal == 0 then
      RP.TrackFX_SetEnabled(controlTrack, tonespaceFx, false)
    end

    OutAllPadsOff()
    OutSelectedTrack()
  elseif newMode == "drum" then
    RP.GetSetMediaTrackInfo_String(controlTrack, "P_NAME", "DRUM", true)
    SetModeFXEnabled("DRUM", true)
    OutAllPadsOff()
    OutSelectedTrack()
  elseif newMode == "sequencer" then
    RP.GetSetMediaTrackInfo_String(controlTrack, "P_NAME", "SEQUENCER", true)
    SetModeFXEnabled("SEQUENCER", true)
    OutAllPadsOff()
    OutStepNotes()
  end
end

local function SelectNextRegion()
  _, numMarkers, numRegions = RP.CountProjectMarkers(0)

  selRegion = nil
  for markerIdx = 0, (numMarkers + numRegions) - 1 do
    marker = { RP.EnumProjectMarkers3(0, markerIdx) }
    if marker.isrgnOut and marker.nameOut == "SELECTED" then
      selRegion = marker
      break
    end
  end

  if selRegion == nil then
    return
  end

  selRegionIdx = selRegion.markrgnindexnumberOut
  nextRegionIdx = selRegionIdx + 1 and selRegionIdx < numRegions - 1 or 0
  nextRegion = { RP.EnumProjectMarkers3(0, nextRegionIdx) }

  RP.SetProjectMarker3(0, selRegion.markrgnindexnumberOut, selRegion.isrgnOut, selRegion.posOut, selRegion.rgnendOut, "", selRegion.colorOut)
  RP.SetProjectMarker3(0, nextRegion.markrgnindexnumberOut, nextRegion.isrgnOut, nextRegion.posOut, nextRegion.rgnendOut, "SELECTED", nextRegion.colorOut)

  RP.UpdateArrange()
end

local function SelectNextItem()
  _, _, _, _, _, _, value = RP.get_action_context()
  if value ~= 127 then
    return
  end

  selTrack = RP.GetSelectedTrack(0, 0)
  prevItem = RP.GetSelectedMediaItem(0, 0)
  nextItem = RP.GetTrackMediaItem(selTrack, 0)

  numItems = RP.CountTrackMediaItems(selTrack)
  for itemIdx = 0, numItems - 1 do
    item = RP.GetTrackMediaItem(selTrack, itemIdx)
    if RP.IsMediaItemSelected(item) then
      if itemIdx == numItems - 1 then
        nextItem = RP.GetTrackMediaItem(selTrack, 0)
      else
        nextItem = RP.GetTrackMediaItem(selTrack, itemIdx + 1)
      end
      break
    end
  end

  if prevItem ~= nil then
    RP.SetMediaItemSelected(prevItem, false)
  end
  if nextItem ~= nil then
    RP.SetMediaItemSelected(nextItem, true)
  end

  RP.UpdateArrange()

  curMode = RP.GetExtState("electribe", "mode")
  if curMode == "sequencer" then
    OutAllPadsOff()
    OutStepNotes()
  end
end

-----------------------------------------------------------

local function Main()
  _, fileName, _, _, _, _, _ = RP.get_action_context()

  curModals = tonumber(RP.GetExtState("electribe", "modals"))
  curModals = curModals ~= nil and curModals or 0x0
  newModalName = GetStateName(fileName)

  if curModals == MODALS["edit_modal"] then
    if newModalName == "mute_modal" then
      CycleMode()
    elseif newModalName == "erase_modal" then
      SelectNextItem()
    else
      ToggleModal(newModalName)
    end
  else
    ToggleModal(newModalName)
  end
end

RP.defer(Main)