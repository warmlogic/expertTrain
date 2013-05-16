function [logFile] = et_matching(w,cfg,expParam,logFile,sesName,phaseName)
% function [logFile] = et_matching(w,cfg,expParam,logFile,sesName,phaseName)
%
% Description:
%  This function runs the matching task. There are no blocks, only short
%  (blink) breaks.
%  TODO: Maybe add a longer break in the middle and tell subjects that this
%  is the middle of the experiment.
%
%  The stimuli for the matching task must already be in presentation order.
%  They are stored in expParam.session.(sesName).(phaseName).allStims as a
%  struct.
%
%
% Inputs:
%
%
% Outputs:
%
%
%
% NB:
%  Once agian, stimuli must already be sorted in presentation order!
%
% NB:
%  Field 'matchStimNum' denotes whether a stimulus is stim1 or stim2.
%  Field 'matchPairNum' denotes which two stimuli are paired. matchPairNum
%   overlaps in the same and different condition
%
% NB:
%  When same and diff stimuli are combined, to find the corresponding pair
%  search for a matching familyNum (basic or subordinate), a matching or
%  different speciesNum field (same or diff condition), a matching or
%  different trained field, the same matchPairNum, and the opposite
%  matchStimNum (1 or 2).

% % durations, in seconds
% cfg.stim.(sesName).(phaseName).isi = 0.5;
% cfg.stim.(sesName).(phaseName).stim1 = 0.8;
% cfg.stim.(sesName).(phaseName).stim2 = 0.8;
% % % random intervals are generated on the fly
% % cfg.stim.(sesName).(phaseName).preStim1 = 0.5 to 0.7;
% % cfg.stim.(sesName).(phaseName).preStim2 = 1.0 to 1.2;

% % keys
% cfg.keys.matchSame
% cfg.keys.matchDiff

% TODO: make instruction files. read in during config?

% TODO: blink breaks

% TODO: NS logging

fprintf('Running matching task for %s %s...\n',sesName,phaseName);

%% preparation

phaseCfg = cfg.stim.(sesName).(phaseName);
allStims = expParam.session.(sesName).(phaseName).allStims;

% set some text color
instructColor = WhiteIndex(w);
fixationColor = WhiteIndex(w);

promptWithResp = true;
% if we're using promptWithResp
if promptWithResp
  if strcmp(KbName(cfg.keys.matchSame),'f')
    leftKey = 'Same';
    rightKey = 'Diff';
  elseif strcmp(KbName(cfg.keys.matchSame),'j')
    leftKey = 'Diff';
    rightKey = 'Same';
  end
end

%% preload all stimuli for presentation

% get the stimulus 2s
stim2 = expParam.session.(sesName).(phaseName).allStims([expParam.session.(sesName).(phaseName).allStims.matchStimNum] == 2);
% initialize for storing stimulus 1s
stim1 = struct([]);
fn = fieldnames(stim2);
for i = 1:length(fn)
  stim1(1).(fn{i}) = [];
end

stim1Tex = nan(1,length(stim2));
stim2Tex = nan(1,length(stim2));

message = sprintf('Preparing images, please wait...');
% put the instructions on the screen
DrawFormattedText(w, message, 'center', 'center', instructColor);
% Update the display to show the message:
Screen('Flip', w);

for i = 1:length(stim2)
  % find stim2's corresponding pair, contingent upon whether this is a same
  % or diff stimulus
  if stim2(i).same
    % same (same species)
    stim1(i) = expParam.session.(sesName).(phaseName).allStims(...
      ([allStims.familyNum] == stim2(i).familyNum) &...
      ([allStims.speciesNum] == stim2(i).speciesNum) &...
      ([allStims.trained] == stim2(i).trained) &...
      ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
      ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
    
  else
    % diff (different species)
    stim1(i) = expParam.session.(sesName).(phaseName).allStims(...
      ([allStims.familyNum] == stim2(i).familyNum) &...
      ([allStims.speciesNum] ~= stim2(i).speciesNum) &...
      ([allStims.trained] == stim2(i).trained) &...
      ([allStims.matchPairNum] == stim2(i).matchPairNum) &...
      ([allStims.matchStimNum] ~= stim2(i).matchStimNum));
  end
  
  % load up stim2's texture
  stim2ImgFile = fullfile(cfg.files.stimDir,stim2(i).familyStr,stim2(i).fileName);
  if exist(stim2ImgFile,'file')
    stim2Img = imread(stim2ImgFile);
    stim2Tex(i) = Screen('MakeTexture',w,stim2Img);
    % TODO: optimized?
    %stim2tex(i) = Screen('MakeTexture',w,stim2Img,[],1);
  else
    error('Study stimulus %s does not exist!',stim2ImgFile);
  end
  
  % load up stim1's texture
  stim1ImgFile = fullfile(cfg.files.stimDir,stim1(i).familyStr,stim1(i).fileName);
  if exist(stim1ImgFile,'file')
    stim1Img = imread(stim1ImgFile);
    stim1Tex(i) = Screen('MakeTexture',w,stim1Img);
    % TODO: optimized?
    %stim1tex(i) = Screen('MakeTexture',w,stim1Img,[],1);
  else
    error('Study stimulus %s does not exist!',stim1ImgFile);
  end
end

%% run the matching task

instructions = sprintf(['Press ''%s'' if the creatures are from the same species.\n',...
  'Press ''%s'' if the creatures are from different species.\n',...
  '\nPress ''%s'' to begin matching task.'],...
  KbName(cfg.keys.matchSame),KbName(cfg.keys.matchDiff),'space');
% put the instructions on the screen
DrawFormattedText(w, instructions, 'center', 'center', instructColor);
% Update the display to show the instruction text:
Screen('Flip', w);
% wait until spacebar is pressed
RestrictKeysForKbCheck(KbName('space'));
KbWait(-1,2);
RestrictKeysForKbCheck([]);
% Clear screen to background color (our 'gray' as set at the
% beginning):
Screen('Flip', w);

% Wait a second before starting trial
WaitSecs(1.000);

% set the fixation size
Screen('TextSize', w, cfg.text.fixsize);
% % draw fixation
% DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
% Screen('Flip',w);

% only check these keys
RestrictKeysForKbCheck([cfg.keys.matchSame, cfg.keys.matchDiff]);

for i = 1:length(stim2Tex)
  % generate random durations for fixation crosses
  preStim1 = 0.5 + ((0.7 - 0.5).*rand(1,1));
  preStim2 = 1.0 + ((1.2 - 1.0).*rand(1,1));
  
  % ISI between trials
  WaitSecs(phaseCfg.isi);
  
  % draw fixation
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
  [preStim1FixOn] = Screen('Flip',w);
  
  % fixation on screen before stim1
  WaitSecs(preStim1);
  
  % draw the stimulus
  Screen('DrawTexture', w, stim1Tex(i));
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'stimOnset':
  [img1On, stim1Onset] = Screen('Flip', w);
  
  % while loop to show stimulus until subjects response or until
  % "duration" seconds elapsed.
  while (GetSecs - stim1Onset) <= phaseCfg.stim1
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  % draw fixation
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
  [preStim2FixOn] = Screen('Flip',w);
  
  % fixation on screen before stim2
  WaitSecs(preStim2);
  
  % draw the stimulus
  Screen('DrawTexture', w, stim2Tex(i));
  
  % Show stimulus on screen at next possible display refresh cycle,
  % and record stimulus onset time in 'stimOnset':
  [img2On, stim2Onset] = Screen('Flip', w);
  
  % while loop to show stimulus until subjects response or until
  % "duration" seconds elapsed.
  while (GetSecs - stim2Onset) <= phaseCfg.stim2
    % Wait <1 ms before checking the keyboard again to prevent
    % overload of the machine at elevated Priority():
    WaitSecs(0.0001);
  end
  
  % draw response prompt
  if promptWithResp
    promptWithRespTxt = sprintf('%s  %s  %s',leftKey,cfg.text.respSymbol,rightKey);
    DrawFormattedText(w,promptWithRespTxt,'center','center',fixationColor);
  else
    DrawFormattedText(w,cfg.text.respSymbol,'center','center',fixationColor);
  end
  [respPromptOn, startRT] = Screen('Flip',w);
  
  % poll for a resp
  while 1
    [keyIsDown, endRT, keyCode] = KbCheck;
    % if they push more than one key, don't accept it
    if keyIsDown && sum(keyCode) == 1
      % wait for key to be released
      while KbCheck(-1)
        WaitSecs(0.0001);
      end
      % % debug
      % fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
      if (keyCode(cfg.keys.matchSame) == 1 && all(keyCode(~cfg.keys.matchSame) == 0)) ||...
          (keyCode(cfg.keys.matchDiff) == 1 && all(keyCode(~cfg.keys.matchDiff) == 0))
        break
      end
    end
    % wait so we don't overload the system
    WaitSecs(0.0001);
  end
  
  % Clear screen to background color after response
  % % and draw fixation
  % DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
  Screen('Flip', w);
  
  % Close this stimulus before next trial
  Screen('Close', stim1Tex(i));
  Screen('Close', stim2Tex(i));
  
  % compute response time
  rt = round(1000 * (endRT - startRT));
  
  % compute accuracy
  if stim1(i).same && keyCode(cfg.keys.matchSame) == 1
    % same
    acc = 1;
  elseif ~stim1(i).same && keyCode(cfg.keys.matchDiff) == 1
    % different
    acc = 1;
  else
    % incorrect
    acc = 0;
  end
  
  % get key pressed by subject
  resp = KbName(keyCode);
  
  % Write stim1 presentation to file:
  fprintf(logFile,'%f %s %s %s %s %i %i %s %s %i\n',...
    img1On,...
    expParam.subject,...
    'MATCH_STIM1',...
    sesName,...
    phaseName,...
    i,...
    stim1(i).same,...
    stim1(i).familyStr,...
    stim1(i).speciesStr,...
    stim1(i).exemplarName);
  
  % Write stim2 presentation to file:
  fprintf(logFile,'%f %s %s %s %s %i %i %s %s %i\n',...
    img2On,...
    expParam.subject,...
    'MATCH_STIM2',...
    sesName,...
    phaseName,...
    i,...
    stim2(i).same,...
    stim2(i).familyStr,...
    stim2(i).speciesStr,...
    stim2(i).exemplarName);
  
  % Write trial result to file:
  fprintf(logFile,'%f %s %s %s %s %i %i %s %i %i\n',...
    endRT,...
    expParam.subject,...
    'MATCH_RESP',...
    sesName,...
    phaseName,...
    i,...
    stim1(i).same,...
    resp,...
    acc,...
    rt);
end

% reset the KbCheck
RestrictKeysForKbCheck([]);

end % function
