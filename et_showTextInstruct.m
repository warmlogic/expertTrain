function et_showTextInstruct(w,instructions,continueKey,instructTextColor,instructTextSize,instructTextWidth,instructImageFile,origText,replacementText)
% function et_showTextInstruct(w,instructions,continueKey,instructTextColor,instructTextSize,instructTextWidth,instructImageFile,origText,replacementText)

if ~exist('continueKey','var') || isempty(continueKey)
  continueKey = 'any';
end

if ~exist('instructColor','var') || isempty(instructTextColor)
  instructTextColor = WhiteIndex(w);
end

if ~exist('instructSize','var') || isempty(instructTextSize)
  instructTextSize = 32;
end

if ~exist('instructTextWidth','var') || isempty(instructTextWidth)
  instructTextWidth = 80;
end

if ~exist('instructImageFile','var') || isempty(instructImageFile)
  instructImageFile = [];
end

if ~exist('origText','var') || isempty(origText)
  origText = {};
end

if ~exist('replacementText','var') || isempty(replacementText)
  replacementText = {};
end

if length(origText) ~= length(replacementText)
  error('origText and replacementText must be the same length.');
end

if ~isempty(origText)
  for i = 1:length(origText)
    [findOrig] = strfind(instructions,origText{i});
    fprintf('replacing %d instances of ''%s'' with ''%s''.\n',length(findOrig),origText{i},replacementText{i});
    instructions = strrep(instructions,origText{i},replacementText{i});
  end
end

% if we want to display an image with the instructions, put it at the
% bottom of the screen
if ~isempty(instructImageFile)
  instructImage = imread(instructImageFile);
  instructImageHeight = size(instructImage,1);
  instructImageWidth = size(instructImage,2);
  instructImage = Screen('MakeTexture',w,instructImage);
  
  % put the image at the bottom of the screen
  wRect = Screen('Rect', w);
  instructImageRect = CenterRect([0 0 instructImageWidth instructImageHeight], wRect);
  instructImageRect = AlignRect(instructImageRect, wRect, RectBottom);
  
  % draw the response key image
  Screen('DrawTexture', w, instructImage, [], instructImageRect);
end

Screen('TextSize', w, instructTextSize);
% put the instructions on the screen
DrawFormattedText(w, instructions, 'center', 'center', instructTextColor, instructTextWidth);
% Update the display to show the instruction text:
Screen('Flip', w);

% wait until the key is pressed
if ~strcmp(continueKey,'any')
  RestrictKeysForKbCheck(KbName(continueKey));
end

KbWait(-1,2);
RestrictKeysForKbCheck([]);

% Clear screen to background color (our 'gray' as set at the beginning):
Screen('Flip', w);

if ~isempty(instructImageFile)
  Screen('Close', instructImage);
end

end % function