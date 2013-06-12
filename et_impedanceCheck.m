function et_impedanceCheck(w, cfg)
% function et_impedanceCheck(w, cfg)
%
% Run an impedance check.
%
% Input:
%  w:   The psychtoolbox window
%  cfg: The experiment config struct
%

Screen('TextSize', w, cfg.text.basicTextSize);
pauseMsg = sprintf('The experimenter will now check the EEG cap.');
% just draw straight into the main window since we don't need speed here
DrawFormattedText(w, pauseMsg, 'center', 'center', cfg.text.experimenterColor);
Screen('Flip', w);

WaitSecs(5.000);
% stop recording
[NSStopStatus, NSStopError] = NetStation('StopRecording');

% wait until g key is held for ~1 seconds
KbCheckHold(1000, {cfg.keys.expContinue}, -1);

% start recording
[NSStopStatus, NSStopError] = NetStation('StartRecording');

message = 'Starting data acquisition...';
DrawFormattedText(w, message, 'center', 'center', cfg.text.basicTextColor, cfg.text.instructCharWidth);
Screen('Flip', w);
WaitSecs(5.000);

end
