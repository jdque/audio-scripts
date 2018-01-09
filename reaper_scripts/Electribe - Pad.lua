local RP = reaper
local ROOT_NOTE = 48

local MODALS = {
  ["mute_modal"]  = 0x8, -- 1000
  ["erase_modal"] = 0x4, -- 0100
  ["copy_modal"]  = 0x2, -- 0010
  ["edit_modal"]  = 0x1  -- 0001
}

-----------------------------------------------------------

local function GetTrackIndex(fileName)
  return tonumber(fileName:sub(fileName:find('%(') + 1, fileName:find('%)') - 1))
end

local function OutAllPadsOff()
  for note = ROOT_NOTE, ROOT_NOTE + 16 do
    RP.StuffMIDIMessage(0, 128, note, 0)
  end
end

local function OutSelectedTrack()
  for trackIdx = 0, RP.CountTracks(0) - 1 do
    if RP.IsTrackSelected(RP.GetTrack(0, trackIdx)) == true then
      RP.StuffMIDIMessage(0, 144, (trackIdx + ROOT_NOTE) - 1, 128)
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

local function SelectTrack(trackIdx)
  track = RP.GetTrack(0, trackIdx)
  if track == nil then
    return
  end

  --toggle FX window
  if RP.IsTrackSelected(track) then
    instrFx = RP.TrackFX_GetInstrument(track)
    isOpen = RP.TrackFX_GetOpen(track, instrFx)

    -- show/hide media explorer if track is a sampler
    _, fxName = RP.TrackFX_GetFXName(track, instrFx, "")
    if fxName == "VSTi: ReaSamplOmatic5000 (Cockos)" or fxName:find("RS5K") != nil then
      mediaExplorerState = RP.GetToggleCommandState(50124)
      if isOpen == true and mediaExplorerState == 1 or isOpen == false and mediaExplorerState == 0 then
        RP.Main_OnCommand(50124, 0) --toggle media explorer
      end
    end

    RP.TrackFX_SetOpen(track, instrFx, not isOpen)
    return
  end

  -- TODO: change to use selected track
  retval, fxTrackIdx, fxItemIdx, fxIdx = RP.GetFocusedFX()
  if retval > 0 then
    fxTrack = RP.GetTrack(0, fxTrackIdx - 1)

    -- show/hide media explorer if track is a sampler
    _, fxName = RP.TrackFX_GetFXName(fxTrack, fxIdx, "")
    if fxName == "VSTi: ReaSamplOmatic5000 (Cockos)" or fxName:find("RS5K") != nil then
      mediaExplorerState = RP.GetToggleCommandState(50124)
      if mediaExplorerState == 1 then
        RP.Main_OnCommand(50124, 0) --toggle media explorer
      end
    end

    RP.TrackFX_SetOpen(fxTrack, fxIdx, false)
  end

  --piano mode: set output channel
  controlTrack = RP.GetTrack(0, 0)
  channelizeFx = RP.TrackFX_GetByName(controlTrack, "MIDI Channelize", false)
  RP.TrackFX_SetParam(controlTrack, channelizeFx, 0, trackIdx - 1)

  --select first item in new track
  prevItem = RP.GetSelectedMediaItem(0, 0)
  nextItem = RP.GetTrackMediaItem(track, 0)
  if prevItem ~= nil then
    RP.SetMediaItemSelected(prevItem, false)
  end
  if nextItem ~= nil then
    RP.SetMediaItemSelected(nextItem, true)
  end

  --select new track
  RP.Main_OnCommand(40297, 0)
  RP.Main_OnCommand(40939 + trackIdx, 0)

  --output selected track
  OutAllPadsOff()
  OutSelectedTrack()

  RP.UpdateArrange()
end

local function MuteTrack(trackIdx)
  track = RP.GetTrack(0, trackIdx)
  if track == nil then
    return
  end

  RP.PreventUIRefresh(1)

  for itemIdx = 0, RP.CountTrackMediaItems(track) - 1 do
    item = RP.GetTrackMediaItem(track, itemIdx)
    isMuted = RP.GetMediaItemInfo_Value(item, 'B_MUTE')
    RP.SetMediaItemInfo_Value(item, 'B_MUTE', isMuted == 0 and 1 or 0)
  end

  RP.UpdateArrange()
  RP.PreventUIRefresh(-1)
end

local function EraseTrack(trackIdx)
  track = RP.GetTrack(0, trackIdx)
  if track == nil then
    return
  end

  RP.PreventUIRefresh(1)

  for itemIdx = 0, RP.CountTrackMediaItems(track) - 1 do
    item = RP.GetTrackMediaItem(track, itemIdx)

    --select all MIDI items in active take
    take = RP.GetActiveTake(item)
    RP.MIDI_SelectAll(take, true)

    --delete notes
    while true do
      if not RP.MIDI_DeleteNote(take, 0) then
        break
      end
    end

    --delete CC's
    while true do
      if not RP.MIDI_DeleteCC(take, 0) then
        break
      end
    end
  end

  RP.PreventUIRefresh(-1)
  RP.UpdateArrange()
end

local function CopyNotes(trackIdx)
  srcTrack = RP.GetSelectedTrack(0, 0)
  dstTrack = RP.GetTrack(0, trackIdx)
  if srcTrack == nil or dstTrack == nil then
    return
  end

  numSrcItems = RP.CountTrackMediaItems(srcTrack)
  numDstItems = RP.CountTrackMediaItems(dstTrack)
  if numSrcItems ~= numDstItems then
    return
  end

  RP.PreventUIRefresh(1)

  for itemIdx = 0, numSrcItems - 1 do
    srcTake = RP.GetMediaItemTake(RP.GetTrackMediaItem(srcTrack, itemIdx), 0)
    dstTake = RP.GetMediaItemTake(RP.GetTrackMediaItem(dstTrack, itemIdx), 0)

    retval, numNotes, _, _ = RP.MIDI_CountEvts(srcTake)
    for noteIdx = 0, numNotes - 1 do
      note = { RP.MIDI_GetNote(srcTake, noteIdx) }
      table.remove(note, 1) --retval
      RP.MIDI_InsertNote(dstTake, table.unpack(note))
    end
  end

  RP.PreventUIRefresh(-1)
  RP.UpdateArrange()
end

local function CopyTrack(trackIdx)
  srcTrack = RP.GetSelectedTrack(0, 0)
  dstTrackIdx = trackIdx
  dstTrack = RP.GetTrack(0, dstTrackIdx)
  if srcTrack == nil or dstTrack == nil then
    return
  end

  RP.PreventUIRefresh(1)

  if RP.GetTrackGUID(srcTrack) == RP.GetTrackGUID(dstTrack) then
    numItems = RP.CountTrackMediaItems(srcTrack)

    RP.Main_OnCommand(40698, 0) --copy selected item
    RP.Main_OnCommand(40421, 0) --select all track items
    RP.Main_OnCommand(40006, 0) --delete selected items
    for i = 0, numItems - 1 do
      RP.Main_OnCommand(40058, 0) --paste copied item
    end

    RP.SetEditCurPos(0, true, false)
  else
    dstMidiInput = RP.GetMediaTrackInfo_Value(dstTrack, "I_RECINPUT")

    RP.Main_OnCommand(40210, 0) --copy source track
    RP.Main_OnCommand(40297, 0)
    RP.Main_OnCommand(40939 + dstTrackIdx, 0)
    RP.Main_OnCommand(40058, 0) --paste copied track
    RP.Main_OnCommand(40297, 0)
    RP.Main_OnCommand(40939 + dstTrackIdx, 0)
    RP.Main_OnCommand(40005, 0) --delete destination track

    SelectTrack(dstTrackIdx)

    newTrack = RP.GetSelectedTrack(0, 0)
    RP.SetMediaTrackInfo_Value(newTrack, "I_RECINPUT", dstMidiInput)
  end

  RP.PreventUIRefresh(-1)
  RP.UpdateArrange()
end

local function ToggleNoteOnOff(trackIdx)
  selItem = RP.GetSelectedMediaItem(0, 0)
  selTake = RP.GetMediaItemTake(selItem, 0)

  takeStartSec = RP.GetMediaItemInfo_Value(selItem, "D_POSITION")
  takeEndSec =  takeStartSec + RP.GetMediaItemInfo_Value(selItem, "D_LENGTH")
  takeStartPPQ = RP.MIDI_GetPPQPosFromProjTime(selTake, takeStartSec)
  takeEndPPQ = RP.MIDI_GetPPQPosFromProjTime(selTake, takeEndSec)
  takeStartQN = RP.MIDI_GetProjQNFromPPQPos(selTake, takeStartPPQ)
  takeEndQN = RP.MIDI_GetProjQNFromPPQPos(selTake, takeEndPPQ)

  step = trackIdx - 1
  stepQN = step / 4.0 + takeStartQN
  stepNoteIdx = -1 --TODO: make into array

  retval, numNotes, _, _ = RP.MIDI_CountEvts(selTake)
  for noteIdx = 0, numNotes - 1 do
    retval, _, _, noteStartPPQ, noteEndPPQ, _, _, _ = RP.MIDI_GetNote(selTake, noteIdx)
    noteStartQN = RP.MIDI_GetProjQNFromPPQPos(selTake, noteStartPPQ)
    if noteStartQN >= stepQN and noteStartQN < stepQN + (1 / 4) then
      stepNoteIdx = noteIdx
    end
  end

  if stepNoteIdx >= 0 then
    RP.MIDI_DeleteNote(selTake, stepNoteIdx)
  else
    noteStartPPQ = RP.MIDI_GetPPQPosFromProjQN(selTake, stepQN)
    noteEndPPQ = RP.MIDI_GetPPQPosFromProjQN(selTake, stepQN + (1 / 8))
    RP.MIDI_InsertNote(selTake, false, false, noteStartPPQ, noteEndPPQ, 1, 60, 96)
    RP.StuffMIDIMessage(0, 144, (step + ROOT_NOTE), 127)
  end
end

-----------------------------------------------------------

_, fileName, _, _, _, _, _ = RP.get_action_context()

curModals = tonumber(RP.GetExtState("electribe", "modals"))
curModals = curModals ~= nil and curModals or 0x0

if curModals == MODALS["erase_modal"] | MODALS["copy_modal"] then
  CopyNotes(GetTrackIndex(fileName))
elseif curModals == MODALS["edit_modal"] then
  SelectTrack(GetTrackIndex(fileName))
elseif curModals == MODALS["mute_modal"] then
  MuteTrack(GetTrackIndex(fileName))
elseif curModals == MODALS["erase_modal"] then
  EraseTrack(GetTrackIndex(fileName))
elseif curModals == MODALS["copy_modal"] then
  CopyTrack(GetTrackIndex(fileName))
end

curMode = RP.GetExtState("electribe", "mode")
if curMode == "sequencer" then
  if curModals ~= 0x0 then --is any modal on?
    OutAllPadsOff()
    OutStepNotes()
  else
    ToggleNoteOnOff(GetTrackIndex(fileName))
  end
end