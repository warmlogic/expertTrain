function [secs] = et_impedanceCheck(w, cfg, talkToNS, phaseName)
% function [secs] = et_impedanceCheck(w, cfg, talkToNS)
%
% Run an impedance check.
%
% Input:
%  w:        The psychtoolbox window
%  cfg:      The experiment config struct
%  talkToNS: Whether Net Station needs to be stopped and started again.
%            true/false. (default = false)
%

if ~exist('talkToNS','var') || isempty(talkToNS)
  talkToNS = false;
end

if ~exist('phaseName','var') || isempty(phaseName)
  phaseName = 'experiment';
else
  phaseName = sprintf('%s phase',phaseName);
end

Screen('TextSize', w, cfg.text.basicTextSize);
pauseMsg = sprintf('The experimenter will now check the EEG cap.');
% just draw straight into the main window since we don't need speed here
DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.experimenterColor);
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
Screen('Flip', w);

if talkToNS
  WaitSecs(5.000);
  % stop recording
  [NSStopStatus, NSStopError] = NetStation('StopRecording'); %#ok<NASGU,ASGLU>
end

% % wait until g key is held for ~1 seconds
% KbCheckHold(1000, {cfg.keys.expContinue}, -1);
% wait until g key is pressed
RestrictKeysForKbCheck(KbName(cfg.keys.expContinue));
secs = KbWait(-1,2);
RestrictKeysForKbCheck([]);

if talkToNS
  % start recording
  [NSStopStatus, NSStopError] = NetStation('StartRecording'); %#ok<NASGU,ASGLU>
end

message = 'Starting data acquisition...';
DrawFormattedText(w, message, 'center', 'center', cfg.text.basicTextColor, cfg.text.instructCharWidth);
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
Screen('Flip', w);
WaitSecs(5.000);

continueMsg = sprintf('Ready to continue.\nPress any key to go to the %s.',phaseName);
% just draw straight into the main window since we don't need speed here
DrawFormattedText(w, continueMsg, 'center', 'center', cfg.text.instructColor, cfg.text.instructCharWidth);
if cfg.stim.photoCell
  Screen('FillRect', w, cfg.stim.photoCellAntiRectColor, cfg.stim.photoCellRect);
end
Screen('Flip', w);
% listen for any keypress on any keyboard
KbWait(-1,2);

end
