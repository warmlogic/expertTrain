function [logFile] = et_recognition(w,cfg,expParam,logFile,sesName,phase)
% function [logFile] = et_recognition(w,cfg,expParam,logFile,sesName,phase)
%
% Description:
%  This function runs the recognition study and test tasks.
%
%  Study targets are stored in expParam.session.(sesName).(phase).targStims
%  and intermixed test targets and lures are stored in
%  expParam.session.(sesName).(phase).allStims as structs. Both study
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

fprintf('Running recognition task for %s %s...\n',sesName,phase);

% TODO:
%  make instruction files. read in during config?

% using these
% cfg.keys.recogKeyNames
% cfg.keys.recogDefUn
% cfg.keys.recogMayUn
% cfg.keys.recogMayF
% cfg.keys.recogDefF
% cfg.keys.recogRecoll

% % not using these
% cfg.keys.recogOld
% cfg.stim.recogNew

% % durations, in seconds
% cfg.stim.(sesName).(phase).study_isi = 0.8;
% cfg.stim.(sesName).(phase).study_preTarg = 0.2;
% cfg.stim.(sesName).(phase).study_targ = 2.0;
% cfg.stim.(sesName).(phase).test_isi = 0.8;
% cfg.stim.(sesName).(phase).test_preStim = 0.2;
% cfg.stim.(sesName).(phase).test_stim = 1.5;
% % TODO: do we need response?
% cfg.stim.(sesName).(phase).response = 1.5;


% % debug
% sesName = 'pretest';
% phase = 'recog';

phaseCfg = cfg.stim.(sesName).(phase);

% % % Don't actually need to check this
% % make sure we have enough stimuli
% if (phaseCfg.nBlocks * phaseCfg.nTargPerBlock) > phaseCfg.nBlocks * length(expParam.session.(sesName).(phase).targStims{1})
%   error('Not enough target stimuli per study block!');
% end
% if (phaseCfg.nBlocks * phaseCfg.nLurePerBlock) > phaseCfg.nBlocks * length(expParam.session.(sesName).(phase).lureStims{1})
%   error('Not enough lure stimuli per test block!');
% end


for b = 1:phaseCfg.nBlocks
  % Run study task
  recogphase = 'study';
  
  % TODO: instructions
  instructions = sprintf('Press ''%s'' to begin study.',KbName(cfg.keys.s00));
  % put the instructions on the screen
  DrawFormattedText(w, instructions, 'center', 'center', WhiteIndex(w));
  % Update the display to show the instruction text:
  Screen('Flip', w);
  % wait until spacebar is pressed
  RestrictKeysForKbCheck(cfg.keys.s00);
  KbWait(-1);
  RestrictKeysForKbCheck([]);
  % Clear screen to background color (our 'gray' as set at the
  % beginning):
  Screen('Flip', w);
  Screen('Close');
  
  % Wait a second before starting trial
  WaitSecs(1.000);

  % debug
  fprintf('study block %d\n',b);
  
  % load up the stimuli for this block (TODO: should we load all blocks?)
  blockStims = cell(1,length(expParam.session.(sesName).(phase).targStims{b}));
  for i = 1:length(expParam.session.(sesName).(phase).targStims{b})
    % this image
    stimFile = fullfile(cfg.files.stimDir,expParam.session.(sesName).(phase).targStims{b}(i).familyStr,expParam.session.(sesName).(phase).targStims{b}(i).fileName);
    if exist(stimFile,'file')
      stimimg = imread(stimFile);
      blockStims{i} = Screen('MakeTexture',w,stimimg);
    else
      error('Study stimulus %s does not exist!',stimFile);
    end
  end
  
  for i = 1:length(blockStims)
    % debug
    fprintf('\tstim %d\n',i);
    
    % ISI between trials
    WaitSecs(cfg.stim.(sesName).(phase).study_isi);
    fprintf('wait\n');
    
    % draw fixation
    %Screen('TextSize', w, cfg.text.cfg.text.fixsize);
    %fprintf('textsize\n');
    DrawFormattedText(w,'+','center','center',WhiteIndex(w));
    fprintf('draw +\n');
    Screen('Flip',w);
    fprintf('flip\n');
    % fixation on screen before starting trial
    WaitSecs(cfg.stim.(sesName).(phase).study_preTarg);
    fprintf('wait\n');
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStims{i});
    fprintf('draw stim\n');
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'startrt':
    [VBLTimestamp, dispTime] = Screen('Flip', w);
    
    % while loop to show stimulus until subjects response or until
    % "duration" seconds elapsed.
    while (GetSecs - dispTime) <= cfg.stim.(sesName).(phase).study_targ
      % Wait 1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.001);
    end
    
    % Write presentation to file:
    fprintf(logFile,'%d %s %i %i %s %s %i %i %i\n',...
      VBLTimestamp,...
      recogphase,...
      b,...
      i,...
      'RECOGSTUDY_TARG',...
      expParam.session.(sesName).(phase).allStims{b}(i).familyStr,...
      expParam.session.(sesName).(phase).allStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phase).allStims{b}(i).exemplarName,...
      expParam.session.(sesName).(phase).allStims{b}(i).targ);
    
    % Clear screen to background color after fixed 'duration'
    Screen('Flip', w);
    
    % Flush out screens before next trial
    %Screen('Close');
    
  end % for stimuli
  
  
  
  
  % Run test task
  recogphase = 'test';
  
  % TODO: instructions
  instructions = sprintf('Press ''%s'' to begin test.',KbName(cfg.keys.s00));
  % put the instructions on the screen
  DrawFormattedText(w, instructions, 'center', 'center', WhiteIndex(w));
  % Update the display to show the instruction text:
  Screen('Flip', w);
  % wait until spacebar is pressed
  RestrictKeysForKbCheck(cfg.keys.s00);
  KbWait(-1);
  RestrictKeysForKbCheck([]);
  % Clear screen to background color (our 'gray' as set at the
  % beginning):
  Screen('Flip', w);
  
  % Wait a second before starting trial
  WaitSecs(1.000);
  
  % debug
  fprintf('test block %d\n',b);
  
  % load up the stimuli for this block (TODO: should we load all blocks?)
  blockStims = cell(1,length(expParam.session.(sesName).(phase).allStims{b}));
  for i = 1:length(expParam.session.(sesName).(phase).allStims{b})
    % this image
    stimFile = fullfile(cfg.files.stimDir,expParam.session.(sesName).(phase).allStims{b}(i).familyStr,expParam.session.(sesName).(phase).allStims{b}(i).fileName);
    if exist(stimFile,'file')
      stimimg = imread(stimFile);
      blockStims{i} = Screen('MakeTexture',w,stimimg);
    else
      error('Test stimulus %s does not exist!',stimFile);
    end
  end
  
  for i = 1:length(blockStims)
    % ISI between trials
    WaitSecs(cfg.stim.(sesName).(phase).test_isi);
    
    % draw fixation
    Screen('TextSize', w, cfg.text.fixsize);
    DrawFormattedText(w,'+','center','center',WhiteIndex(w));
    Screen('Flip',w);
    % fixation on screen before starting trial
    WaitSecs(cfg.stim.(sesName).(phase).test_preStim);
    
    % draw the stimulus
    Screen('DrawTexture', w, blockStims{i});
    
    % Show stimulus on screen at next possible display refresh cycle,
    % and record stimulus onset time in 'startRT':
    [VBLTimestamp, startRT] = Screen('Flip', w);
    
    % Write presentation to file:
    fprintf(logFile,'%d %s %i %i %s %s %s %i %i\n',...
      VBLTimestamp,...
      recogphase,...
      b,...
      i,...
      'RECOGTEST_STIM',...
      expParam.session.(sesName).(phase).allStims{b}(i).familyStr,...
      expParam.session.(sesName).(phase).allStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phase).allStims{b}(i).exemplarName,...
      expParam.session.(sesName).(phase).allStims{b}(i).targ);
    
    % while loop to show stimulus until subjects response or until
    % "duration" seconds elapsed.
    while (GetSecs - startRT) <= cfg.stim.(sesName).(phase).test_stim
      % Wait 1 ms before checking the keyboard again to prevent
      % overload of the machine at elevated Priority():
      WaitSecs(0.001);
    end
    
    % poll for a resp
    while keyCode(cfg.keys.recogDefUn) == 0 && keyCode(cfg.keys.recogMayUn) == 0 && keyCode(cfg.keys.recogMayF) == 0 && keyCode(cfg.keys.recogDefF) == 0 && keyCode(cfg.keys.recogRecoll) == 0
      [keyIsDown, endRT, keyCode] = KbCheck;
      WaitSecs(0.001);
    end
    %if keyCode(cfg.keys.recogDefUn) == 1 || keyCode(cfg.keys.recogMayUn) == 1 || keyCode(cfg.keys.recogMayF) == 1 || keyCode(cfg.keys.recogDefF) == 1 || keyCode(cfg.keys.recogRecoll) == 1
    %  break
    %end
    %[KeyIsDown, endRT, keyCode] = KbCheck;
    
    % Clear screen to background color after fixed 'duration'
    % or after subjects response (on test phase)
    Screen('Flip', w);
    
    % Flush out screens before next trial
    FlushEvents('keyDown');
    Screen('Close');
    
    % compute response time
    rt = round(1000 * (endRT - startRT));
    
    % compute accuracy
    if expParam.session.(sesName).(phase).allStims{b}(i).targ && (keyCode(cfg.keys.recogMayF) == 1 || keyCode(cfg.keys.recogDefF) == 1 || keyCode(cfg.keys.recogRecoll) == 1)
      acc = 1;
    elseif ~expParam.session.(sesName).(phase).allStims{b}(i).targ && (keyCode(cfg.keys.recogDefUn) == 1 || keyCode(cfg.keys.recogMayUn) == 1)
      acc = 1;
    else
      acc = 0;
    end
    
    % get key pressed by subject
    resp = KbName(keyCode);
    
    % Write trial result to file:
    fprintf(logFile,'%d %s %i %i %s %s %i %i %i %s %i %i\n',...
      endRT,...
      recogphase,...
      b,...
      i,...
      'RECOGTEST_RESP',...
      expParam.session.(sesName).(phase).allStims{b}(i).familyStr,...
      expParam.session.(sesName).(phase).allStims{b}(i).speciesStr,...
      expParam.session.(sesName).(phase).allStims{b}(i).exemplarName,...
      expParam.session.(sesName).(phase).allStims{b}(i).targ,...
      resp,...
      acc,...
      rt);
    
  end % for stimuli
  
end % for nBlocks

end % function