screens = Screen('Screens');
screenNumber = max(screens);

grayInd = GrayIndex(screenNumber);

% Open a double buffered fullscreen window on the stimulation screen
% 'screenNumber' and choose/draw a gray background. 'w' is the handle
% used to direct all drawing commands to that window - the "Name" of
% the window. 'wRect' is a rectangle defining the size of the window.
% See "help PsychRects" for help on such rectangles and useful helper
% functions:
[w, wRect] = Screen('OpenWindow',screenNumber, grayInd);

% Screen('FillRect', w, grayInd);

%%

Screen('Preference','DefaultFontName','Courier New');
% Screen('Preference','DefaultFontName','Monaco');
Screen('Preference','DefaultFontStyle',1);
Screen('Preference','DefaultFontSize',18);

textSize = 58;
nFlips = 500;
textStr = 'ASDFASDFASDFASDF';

Screen('TextSize', w, textSize);
strRect = Screen('TextBounds', w, textStr);
% center it in the middle of the screen
fixRect = CenterRect(strRect, wRect);
% get the X and Y coordinates
fixRectX = fixRect(1);
fixRectY = fixRect(2);

priorityLevel = MaxPriority(w);
Priority(priorityLevel);

Screen('Flip',w);

%%

tic;
for i = 1:nFlips;
  Screen('TextSize', w, textSize);
  DrawFormattedText(w,textStr,'center','center');
  Screen('Flip',w);
end
t = toc;
DrawFormattedText(w,sprintf('TextSize with DrawFormattedText\n%.4f sec',t),'center','center');
Screen('Flip',w);
fprintf('TextSize with DrawFormattedText: %.4f sec\n',t);

%%

% DrawText requires the TextSize command

textSize2 = 12;

tic;
for i = 1:nFlips
  Screen('TextSize', w, textSize2);
  Screen('DrawText', w, textStr, fixRectX, fixRectY);
  Screen('Flip',w);
end
t = toc;
DrawFormattedText(w,sprintf('TextSize with DrawText\n%.4f sec',t),'center','center');
Screen('Flip',w);
fprintf('TextSize with DrawText: %.4f sec\n',t);

%%

Screen('CloseAll');

Priority(0);
