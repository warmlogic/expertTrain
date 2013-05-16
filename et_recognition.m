function [logFile] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName)
% function [logFile] = et_recognition(w,cfg,expParam,logFile,sesName,phaseName)
%
% Description:
%  This function runs the recognition study and test tasks.
%
%  Study targets are stored in expParam.session.(sesName).(phaseName).targStims
%  and intermixed test targets and lures are stored in
%  expParam.session.(sesName).(phaseName).allStims as structs. Both study
%  targets and target+lure test stimuli must already be sorted in
%  presentation order.
%
%
% Inputs:
%
%
% Outputs:
%
%
% NB:
%  Once agian, study targets and test targets+lures must already be sorted
%  in presentation order!
%
% NB:
%  Test response time is measured from when response key image appears on
%  screen.
%

% % keys
% cfg.keys.recogKeyNames
% cfg.keys.recogDefUn
% cfg.keys.recogMayUn
% cfg.keys.recogMayF
% cfg.keys.recogDefF
% cfg.keys.recogRecoll

% % durations, in seconds
% cfg.stim.(sesName).(phaseName).study_isi = 0.8;
% cfg.stim.(sesName).(phaseName).study_preTarg = 0.2;
% cfg.stim.(sesName).(phaseName).study_targ = 2.0;
% cfg.stim.(sesName).(phaseName).test_isi = 0.8;
% cfg.stim.(sesName).(phaseName).test_preStim = 0.2;
% cfg.stim.(sesName).(phaseName).test_stim = 1.5;

% TODO: make instruction files. read in during config?

% TODO: blink breaks

% TODO: NS logging

fprintf('Running recognition task for %s %s...\n',sesName,phaseName);

%% preparation

phaseCfg = cfg.stim.(sesName).(phaseName);

% read the proper response key image
testRespImgFile = fullfile(cfg.files.resDir,sprintf('recog_test_resp%d.jpg',cfg.keys.recogKeySet));
testRespImg = imread(testRespImgFile);
testRespImgHeight = size(testRespImg,1);
testRespImgWidth = size(testRespImg,2);
testRespImg = Screen('MakeTexture',w,testRespImg);

% set some text color
instructColor = WhiteIndex(w);
fixationColor = WhiteIndex(w);

for b = 1:phaseCfg.nBlocks
  
  %% Run the recognition study task
  
  recogphase = 'recog_study';
  
  % TODO: instructions
  instructions = sprintf('Press ''%s'' to begin Recognition study task.','space');
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

  % debug
  fprintf('study block %d\n',b);
  
  % load up the stimuli for this block
  blockStims = nan(1,length(expParam.session.(sesName).(phaseName).targStims{b}));
  for i = 1:length(expParam.session.(sesName).(phaseName).targStims{b})
    % this image
    stimImgFile = fullfile(cfg.files.stimDir,expParam.session.(sesName).(phaseName).targStims{b}(i).familyStr,expParam.session.(sesName).(phaseName).targStims{b}(i).fileName);
    if exist(stimImgFile,'file')
      stimImg = imread(stimImgFile);
      blockStims(i) = Screen('MakeTexture',w,stimImg);
      % TODO: optimized?
      %blockStims(i) = Screen('MakeTexture',w,stimImg,[],1);
    else
      error('Study stimulus %s does not exist!',stimImgFile);
    end
  end
  
  % get the width and height of the final stimulus image
  stimImgHeight = size(stimImg,1);
  stimImgWidth = size(stimImg,2);
  % set the stimulus image rectangle
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);
  
  % set the fixation size
  Screen('TextSize', w, cfg.text.fixsize);
  % draw fixation
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
  Screen('Flip',w);
  
  for i = 1:length(blockStims)
    % ISI between trials
    WaitSecs(phaseCfg.study_isi);
    
    % fixation on screen before starting trial
    WaitSecs(phaseCfg.study_preTarg);
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStims(i), [], stimImgRect);
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'startrt':
    [imgOnScreen, dispTime] = Screen('Flip', w);
    
    % while loop to show stimulus until subjects response or until
    % "duration" seconds elapsed.
    while (GetSecs - dispTime) <= phaseCfg.study_targ
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    % Write presentation to file:
    fprintf(logFile,'%f %s %s %s %s %s %i %i %s %s %i %i\n',...
      imgOnScreen,...
      expParam.subject,...
      'RECOGSTUDY_TARG',...
      sesName,...
      phaseName,...
      recogphase,...
      b,...
      i,...
      expParam.session.(sesName).(phaseName).targStims{b}(i).familyStr,...
      expParam.session.(sesName).(phaseName).targStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phaseName).targStims{b}(i).exemplarName,...
      expParam.session.(sesName).(phaseName).targStims{b}(i).targ);
    
    % Clear screen to background color after fixed 'duration' and draw fixation
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
    Screen('Flip', w);
    
    % Flush out screens before next trial
    Screen('Close', blockStims(i));
    
  end % for stimuli
  
  %% Run the recognition test task
  
  recogphase = 'recog_test';
  
  % TODO: instructions
  instructions = sprintf('Press ''%s'' to begin Recognition test task.','space');
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
  
  % debug
  fprintf('test block %d\n',b);
  
  % load up the stimuli for this block
  blockStims = nan(1,length(expParam.session.(sesName).(phaseName).allStims{b}));
  for i = 1:length(expParam.session.(sesName).(phaseName).allStims{b})
    % this image
    stimImgFile = fullfile(cfg.files.stimDir,expParam.session.(sesName).(phaseName).allStims{b}(i).familyStr,expParam.session.(sesName).(phaseName).allStims{b}(i).fileName);
    if exist(stimImgFile,'file')
      stimImg = imread(stimImgFile);
      blockStims(i) = Screen('MakeTexture',w,stimImg);
      % TODO: optimized?
      %blockStims(i) = Screen('MakeTexture',w,stimImg,[],1);
    else
      error('Test stimulus %s does not exist!',stimImgFile);
    end
  end
  
  % get the width and height of the final stimulus image
  stimImgHeight = size(stimImg,1);
  stimImgWidth = size(stimImg,2);
  % set the stimulus image rectangle
  stimImgRect = [0 0 stimImgWidth stimImgHeight];
  stimImgRect = CenterRect(stimImgRect,cfg.screen.wRect);
  
  % set the response key rectangle
  respKeyImgRect = CenterRect([0 0 testRespImgWidth testRespImgHeight],stimImgRect);
  respKeyImgRect = AdjoinRect(respKeyImgRect,stimImgRect,RectBottom);
  
  % only check these keys
  RestrictKeysForKbCheck([cfg.keys.recogDefUn, cfg.keys.recogMayUn, cfg.keys.recogMayF, cfg.keys.recogDefF, cfg.keys.recogRecoll]);
  
  % set the fixation size
  Screen('TextSize', w, cfg.text.fixsize);
  % draw fixation
  DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
  Screen('Flip',w);
  
  for i = 1:length(blockStims)
    % ISI between trials
    WaitSecs(phaseCfg.test_isi);
    
    % fixation on screen before starting trial
    WaitSecs(phaseCfg.test_preStim);
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStims(i), [], stimImgRect);
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'stimOnset':
    [imgOnScreen, stimOnset] = Screen('Flip', w);
    
    % Write presentation to file:
    fprintf(logFile,'%f %s %s %s %s %s %i %i %s %s %i %i\n',...
      imgOnScreen,...
      expParam.subject,...
      'RECOGTEST_STIM',...
      sesName,...
      phaseName,...
      recogphase,...
      b,...
      i,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).familyStr,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).exemplarName,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).targ);
    
    % while loop to show stimulus until subjects response or until
    % "duration" seconds elapsed.
    while (GetSecs - stimOnset) <= phaseCfg.test_stim
      % Wait <1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.0001);
    end
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStims(i), [], stimImgRect);
    % draw the response key image
    Screen('DrawTexture', w, testRespImg, [], respKeyImgRect);
    % put them on the screen; measure RT from when response key img appears
    [respOnScreen, startRT] = Screen('Flip', w);
    
    % poll for a resp
    while 1
      [keyIsDown, endRT, keyCode] = KbCheck;
      % if they push more than one key, don't accept it
      if keyIsDown && sum(keyCode) == 1
        % wait for key to be released
        while KbCheck(-1)
          WaitSecs(.0001);
        end
        % % debug
        % fprintf('"%s" typed at time %.3f seconds\n', KbName(keyCode), endRT - startRT);
        if (keyCode(cfg.keys.recogDefUn) == 1 && all(keyCode(~cfg.keys.recogDefUn) == 0)) ||...
            (keyCode(cfg.keys.recogMayUn) == 1 && all(keyCode(~cfg.keys.recogMayUn) == 0)) ||...
            (keyCode(cfg.keys.recogMayF) == 1 && all(keyCode(~cfg.keys.recogMayF) == 0)) ||...
            (keyCode(cfg.keys.recogDefF) == 1 && all(keyCode(~cfg.keys.recogDefF) == 0)) ||...
            (keyCode(cfg.keys.recogRecoll) == 1 && all(keyCode(~cfg.keys.recogRecoll) == 0))
          break
        end
      end
      % wait so we don't overload the system
      WaitSecs(.0001);
    end
    
    % Clear screen to background color after response and draw fixation
    DrawFormattedText(w,cfg.text.fixSymbol,'center','center',fixationColor);
    Screen('Flip', w);
    
    % Close this stimulus before next trial
    Screen('Close', blockStims(i));
    
    % compute response time
    rt = round(1000 * (endRT - startRT));
    
    % compute accuracy
    if expParam.session.(sesName).(phaseName).allStims{b}(i).targ && (keyCode(cfg.keys.recogMayF) == 1 || keyCode(cfg.keys.recogDefF) == 1 || keyCode(cfg.keys.recogRecoll) == 1)
      % target (hit)
      acc = 1;
    elseif ~expParam.session.(sesName).(phaseName).allStims{b}(i).targ && (keyCode(cfg.keys.recogDefUn) == 1 || keyCode(cfg.keys.recogMayUn) == 1)
      % lure (correct rejection)
      acc = 1;
    else
      % miss or false alarm
      acc = 0;
    end
    
    % get key pressed by subject
    resp = KbName(keyCode);
    
    % Write trial result to file:
    fprintf(logFile,'%f %s %s %s %s %s %i %i %s %i %i %i %s %i %i\n',...
      endRT,...
      expParam.subject,...
      'RECOGTEST_RESP',...
      sesName,...
      phaseName,...
      recogphase,...
      b,...
      i,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).familyStr,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).exemplarName,...
      expParam.session.(sesName).(phaseName).allStims{b}(i).targ,...
      resp,...
      acc,...
      rt);
    
  end % for stimuli
  
  % reset the KbCheck
  RestrictKeysForKbCheck([]);
  
end % for nBlocks

end % function
