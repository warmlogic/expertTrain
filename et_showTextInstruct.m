function et_showTextInstruct(w,instructFile,continueKey,instructColor,instructSize)
% function et_showTextInstruct(w,instructFile,continueKey,instructColor,instructSize)

if ~exist('continueKey','var') || isempty(continueKey)
  continueKey = 'any';
end

if ~exist('instructColor','var') || isempty(instructColor)
  instructColor = WhiteIndex(w);
end

if ~exist('instructSize','var') || isempty(instructSize)
  instructSize = 32;
end

if exist(instructFile,'file')
  fid = fopen(instructFile, 'rt');
else
  error('Instructions file does not exist: %s',instructFile);
end
instructions = fread(fid, [1, inf], '*char');
fclose(fid);

% turn carriage returns into newlines
instructions = strrep(instructions,sprintf('\r'),sprintf('\n'));

%instructions = sprintf('Press ''%s'' to begin Recognition study task.','space');
Screen('TextSize', w, instructSize);
% put the instructions on the screen
DrawFormattedText(w, instructions, 'center', 'center', instructColor, 80);
% Update the display to show the instruction text:
Screen('Flip', w);

% wait until the key is pressed
if ~strcmp(continueKey,'any')
  RestrictKeysForKbCheck(KbName(continueKey));
end

KbWait(-1,2);
RestrictKeysForKbCheck([]);

% Clear screen to background color (our 'gray' as set at the
% beginning):
Screen('Flip', w);
