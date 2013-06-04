function et_showTextInstruct(w,instructions,continueKey,instructTextColor,instructTextSize,instructCharWidth,origText,replacementText)
% function et_showTextInstruct(w,instructions,continueKey,instructTextColor,instructTextSize,instructCharWidth,origText,replacementText)

if ~exist('continueKey','var') || isempty(continueKey)
  continueKey = 'any';
end

if ~exist('instructColor','var') || isempty(instructTextColor)
  instructTextColor = WhiteIndex(w);
end

if ~exist('instructTextSize','var') || isempty(instructTextSize)
  instructTextSize = 32;
end

if ~exist('instructCharWidth','var') || isempty(instructCharWidth)
  instructCharWidth = 80;
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
    [findOrig] = strfind(instructions.text,origText{i});
    fprintf('replacing %d instances of ''%s'' with ''%s''.\n',length(findOrig),origText{i},replacementText{i});
    instructions.text = strrep(instructions.text,origText{i},replacementText{i});
  end
end

% if we want to display an image with the instructions, put it at the
% bottom of the screen
if isfield(instructions,'image') && ~isempty(instructions.image)
  if ~isfield(instructions,'imageScale') || isempty(instructions.imageScale)
    instructions.imageScale = 1;
  end
  
  instructImage = imread(instructions.image);
  instructImageHeight = size(instructImage,1) * instructions.imageScale;
  instructImageWidth = size(instructImage,2) * instructions.imageScale;
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
DrawFormattedText(w, instructions.text, 'center', 'center', instructTextColor, instructCharWidth);
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

if isfield(instructions,'image') && ~isempty(instructions.image)
  Screen('Close', instructImage);
end

end % function