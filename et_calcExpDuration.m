function et_calcExpDuration(cfg,expParam,durLimit)
% function et_calcExpDuration(cfg,expParam,durLimit)
% 
% calculates the experiment duration
%
% durLimit can be 'min','med', or 'max'.
%  'min': responses limits are 0 sec
%  'med': responses limits are half length
%  'max': responses limits are maximum length
%

% set some constant durations (in seconds)
instructDur = 30;
blinkBreakDur = 5;
initialNetSetup = 600; % 5 min = 300 seconds
impedanceDur = 300; % 5 min = 300 seconds

% initialize
expDur = 0;

if ~exist('durLimit','var') || isempty(durLimit)
  error('durLimit variable not set properly! Must be ''min'',''med'', or ''max''.');
end

if strcmp(durLimit,'min')
  fprintf('MINIMUM %s experiment duration (responses limits are 0 sec).',expParam.expName);
elseif strcmp(durLimit,'med')
  fprintf('MEDIUM %s experiment duration (responses limits are half length).',expParam.expName);
elseif strcmp(durLimit,'max')
  fprintf('MAXIMUM %s experiment duration (responses limits are maximum length).',expParam.expName);
end

if expParam.useNS
  fprintf(' Using EEG.\n');
else
  fprintf(' Not using EEG.\n');
end

fprintf('Assuming %.1f min initial setup, %d sec instructions per phase, %d sec blink breaks, and %.1f min impedance breaks.\n',(initialNetSetup / 60),instructDur,blinkBreakDur,(impedanceDur / 60));

for s = 1:expParam.nSessions
  % initialize
  sesDur = 0;
  
  % get the session name
  sesName = expParam.sesTypes{s};
  fprintf('\n\tSession %s (%d/%d)...\n',sesName,s,expParam.nSessions);
  
  % counting the phases, in case any sessions have the same phase type
  % multiple times
  matchCount = 0;
  nameCount = 0;
  recogCount = 0;
  nametrainCount = 0;
  viewnameCount = 0;
  
  prac_matchCount = 0;
  prac_nameCount = 0;
  prac_recogCount = 0;
  
  % for each phase in this session, run the correct function
  for p = 1:length(expParam.session.(sesName).phases)
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case{'match'}
        % Subordinate Matching task (same/different)
        matchCount = matchCount + 1;
        phaseCount = matchCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1) + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_response;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).match_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).match_response / 2);
        end
        
        % divide match trials in half because allStims contains stim1+stim2
        nTrials = length(expParam.session.(sesName).(phaseName)(phaseCount).allStims) / 2;
        
      case {'name'}
        % Naming task
        nameCount = nameCount + 1;
        phaseCount = nameCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_isi + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_response + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).name_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).name_response / 2);
        end
        
        nTrials = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
        
      case {'recog'}
        % Recognition (old/new) task
        recogCount = recogCount + 1;
        phaseCount = recogCount;
        
        trialDur_study = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_preTarg + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_targ;
        trialDur_test = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_preStim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_response;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur_test = trialDur_test - cfg.stim.(sesName).(phaseName)(phaseCount).recog_response;
        elseif strcmp(durLimit,'med')
          trialDur_test = trialDur_test - round(cfg.stim.(sesName).(phaseName)(phaseCount).recog_response / 2);
        end
        
        nTrials_study = 0;
        nTrials_test = 0;
        nBlocks = cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks;
        
        for b = 1:nBlocks
          nTrials_study = nTrials_study + length(expParam.session.(sesName).(phaseName)(phaseCount).targStims{b});
          nTrials_test = nTrials_test + length(expParam.session.(sesName).(phaseName)(phaseCount).allStims{b});
        end
        
      case {'nametrain'}
        % Name training task
        nametrainCount = nametrainCount + 1;
        phaseCount = nametrainCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_isi + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_response + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).name_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).name_response / 2);
        end
        
        nTrials = 0;
        nBlocks = length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder);
        
        % for each view/name block
        for b = 1:nBlocks
          nTrials = nTrials + length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b});
        end
        
      case {'viewname'}
        % Viewing task, with category response; intermixed with
        % Naming task
        viewnameCount = viewnameCount + 1;
        phaseCount = viewnameCount;
        
        trialDur_view = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).view_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).view_preStim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).view_stim;
        
        trialDur_name = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_isi + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_response + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur_name = trialDur_name - cfg.stim.(sesName).(phaseName)(phaseCount).name_response;
        elseif strcmp(durLimit,'med')
          trialDur_name = trialDur_name - round(cfg.stim.(sesName).(phaseName)(phaseCount).name_response / 2);
        end
        
        nTrials_view = 0;
        nTrials_name = 0;
        
        nBlocks = length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder);
        
        % for each view/name block
        for b = 1:nBlocks
          nTrials_view = nTrials_view + length(expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b});
          nTrials_name = nTrials_name + length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b});
        end
        
        nTrials = nTrials_view + nTrials_name;
        
      case{'prac_match'}
        % Subordinate Matching task (same/different)
        prac_matchCount = prac_matchCount + 1;
        phaseCount = prac_matchCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_stim1 + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_stim2 + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim1) + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).match_preStim2) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).match_response;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).match_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).match_response / 2);
        end
        
        % divide match trials in half because allStims contains stim1+stim2
        nTrials = length(expParam.session.(sesName).(phaseName)(phaseCount).allStims) / 2;
        
      case {'prac_name'}
        % Naming task
        prac_nameCount = prac_nameCount + 1;
        phaseCount = prac_nameCount;
        
        trialDur = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_isi + ...
          mean(cfg.stim.(sesName).(phaseName)(phaseCount).name_preStim) + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_response + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).name_feedback;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur = trialDur - cfg.stim.(sesName).(phaseName)(phaseCount).name_response;
        elseif strcmp(durLimit,'med')
          trialDur = trialDur - round(cfg.stim.(sesName).(phaseName)(phaseCount).name_response / 2);
        end
        
        nTrials = length(expParam.session.(sesName).(phaseName)(phaseCount).nameStims);
        
      case {'prac_recog'}
        % Recognition (old/new) task
        prac_recogCount = prac_recogCount + 1;
        phaseCount = prac_recogCount;
        
        trialDur_study = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_preTarg + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_study_targ;
        trialDur_test = ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_isi + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_preStim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_test_stim + ...
          cfg.stim.(sesName).(phaseName)(phaseCount).recog_response;
        
        % subtract out the response limit if we want the minimum duration
        if strcmp(durLimit,'min')
          trialDur_test = trialDur_test - cfg.stim.(sesName).(phaseName)(phaseCount).recog_response;
        elseif strcmp(durLimit,'med')
          trialDur_test = trialDur_test - round(cfg.stim.(sesName).(phaseName)(phaseCount).recog_response / 2);
        end
        
        nTrials_study = 0;
        nTrials_test = 0;
        nBlocks = cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks;
        
        for b = 1:nBlocks
          nTrials_study = nTrials_study + length(expParam.session.(sesName).(phaseName)(phaseCount).targStims{b});
          nTrials_test = nTrials_test + length(expParam.session.(sesName).(phaseName)(phaseCount).allStims{b});
        end
        
      otherwise
        warning('%s is not a configured phase in this session (%s)!\n',phaseName,sesName);
    end % switch
    
    % calculate the number of impedance breaks
    if expParam.useNS
      if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
        if isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nTrials')
          nImpedanceBreaks = floor(nTrials / cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials) - 1;
        elseif isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nBlocks')
          if strcmp(phaseName,'nametrain')
            % only has 1 impedance break, so we don't want to subtract it
            nImpedanceBreaks = floor(nBlocks / cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks);
          elseif strcmp(phaseName,'viewname')
            % only has 1 impedance break, so we don't want to subtract it
            nImpedanceBreaks_view = floor(nBlocks / cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks);
            nImpedanceBreaks_name = floor(nBlocks / cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks);
            nImpedanceBreaks = nImpedanceBreaks_view + nImpedanceBreaks_name;
          elseif strcmp(phaseName,'recog') || strcmp(phaseName,'prac_recog')
            nImpedanceBreaks_study = floor(nBlocks / cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks) - 1;
            nImpedanceBreaks_test = floor(nBlocks / cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks) - 1;
            nImpedanceBreaks = nImpedanceBreaks_study + nImpedanceBreaks_test;
          else
            nImpedanceBreaks = floor(nBlocks / cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks) - 1;
          end
        end
      else
        if strcmp(phaseName,'viewname')
          nImpedanceBreaks_view = 0;
          nImpedanceBreaks_name = 0;
        elseif strcmp(phaseName,'recog') || strcmp(phaseName,'prac_recog')
          nImpedanceBreaks_study = 0;
          nImpedanceBreaks_test = 0;
        end
        nImpedanceBreaks = 0;
      end
    else
      if strcmp(phaseName,'viewname')
        nImpedanceBreaks_view = 0;
        nImpedanceBreaks_name = 0;
      elseif strcmp(phaseName,'recog') || strcmp(phaseName,'prac_recog')
        nImpedanceBreaks_study = 0;
        nImpedanceBreaks_test = 0;
      end
      nImpedanceBreaks = 0;
    end
    
    if strcmp(phaseName,'viewname')
      % calculate the phase duration without blink breaks
      phaseDur_view = instructDur + (trialDur_view * nTrials_view) + (nImpedanceBreaks_view * impedanceDur);
      phaseDur_name = instructDur + (trialDur_name * nTrials_name) + (nImpedanceBreaks_name * impedanceDur);
      
      % calculate the number of blink breaks
      nBlinkBreaks_view = floor((trialDur_view * nTrials_view) / cfg.stim.secUntilBlinkBreak);
      nBlinkBreaks_name = floor((trialDur_name * nTrials_name) / cfg.stim.secUntilBlinkBreak);
      nBlinkBreaks = nBlinkBreaks_view + nBlinkBreaks_name;
      
      % calculate the full phase duration
      phaseDur_view = phaseDur_view + (nBlinkBreaks_view * blinkBreakDur);
      phaseDur_name = phaseDur_name + (nBlinkBreaks_name * blinkBreakDur);
      phaseDur = phaseDur_view + phaseDur_name;
    elseif strcmp(phaseName,'recog') || strcmp(phaseName,'prac_recog')
      % calculate the phase duration without blink breaks
      phaseDur_study = instructDur + (trialDur_study * nTrials_study) + (nImpedanceBreaks_study * impedanceDur);
      phaseDur_test = instructDur + (trialDur_test * nTrials_test) + (nImpedanceBreaks_test * impedanceDur);
      
      % calculate the number of blink breaks
      nBlinkBreaks_study = floor((trialDur_study * nTrials_study) / cfg.stim.secUntilBlinkBreak);
      nBlinkBreaks_test = floor((trialDur_test * nTrials_test) / cfg.stim.secUntilBlinkBreak);
      nBlinkBreaks = nBlinkBreaks_study + nBlinkBreaks_test;
      
      % calculate the full phase duration
      phaseDur_study = phaseDur_study + (nBlinkBreaks_study * blinkBreakDur);
      phaseDur_test = phaseDur_test + (nBlinkBreaks_test * blinkBreakDur);
      phaseDur = phaseDur_study + phaseDur_test;
    else
      % calculate the phase duration without blink breaks
      phaseDur = instructDur + (trialDur * nTrials) + (nImpedanceBreaks * impedanceDur);
      % calculate the number of blink breaks
      nBlinkBreaks = floor((trialDur * nTrials) / cfg.stim.secUntilBlinkBreak);
      % calculate the full phase duration
      phaseDur = phaseDur + (nBlinkBreaks * blinkBreakDur);
    end
    
    % print out some info
    if strcmp(durLimit,'min')
      fprintf('\t\tMINIMUM ');
    elseif strcmp(durLimit,'med')
      fprintf('\t\tMEDIUM ');
    elseif strcmp(durLimit,'max')
      fprintf('\t\tMAXIMUM ');
    end
    fprintf('phase %s (%d/%d):\t%.2f min.\n',phaseName,p,length(expParam.session.(sesName).phases),(phaseDur / 60));
    
    if strcmp(phaseName,'nametrain')
      fprintf('\t\t\t%d blocks:\n',nBlocks);
    end
    if strcmp(phaseName,'viewname')
      fprintf('\t\t\t%d blocks:\n',nBlocks);
      fprintf('\t\t\t%d view trials (%.2f min/phase @ %.2f sec/trial)',nTrials_view,((trialDur_view * nTrials_view) / 60),trialDur_view);
      fprintf(', %d blink breaks (every %d sec)',nBlinkBreaks_view,cfg.stim.secUntilBlinkBreak);
      if expParam.useNS
        if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
          fprintf(', %d impedance breaks',nImpedanceBreaks_view);
          if isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nTrials')
            fprintf(' (every %d trials).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials);
          elseif isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nBlocks')
            fprintf(' (every %d blocks).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks);
          end
        else
          fprintf(', no impdance breaks during practice.\n');
        end
      else
        fprintf('.\n');
      end
      fprintf('\t\t\t%d name trials (%.2f min/phase @ %.2f sec/trial)',nTrials_name,((trialDur_name * nTrials_name) / 60),trialDur_name);
      fprintf(', %d blink breaks (every %d sec)',nBlinkBreaks_name,cfg.stim.secUntilBlinkBreak);
      if expParam.useNS
        if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
          fprintf(', %d impedance breaks',nImpedanceBreaks_name);
          if isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nTrials')
            fprintf(' (every %d trials).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials);
          elseif isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nBlocks')
            fprintf(' (every %d blocks).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks);
          end
        else
          fprintf(', no impdance breaks during practice.\n');
        end
      else
        fprintf('.\n');
      end
      
    elseif strcmp(phaseName,'recog') || strcmp(phaseName,'prac_recog')
      fprintf('\t\t\t%d blocks:\n',nBlocks);
      fprintf('\t\t\t%d study trials (%.2f min/phase @ %.2f sec/trial)',nTrials_study,((trialDur_study * nTrials_study) / 60),trialDur_study);
      fprintf(', %d blink breaks (every %d sec)',nBlinkBreaks_study,cfg.stim.secUntilBlinkBreak);
      if expParam.useNS
        if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
          fprintf(', %d impedance breaks',nImpedanceBreaks_study);
          if isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nTrials')
            fprintf(' (every %d trials).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials);
          elseif isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nBlocks')
            fprintf(' (every %d blocks).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks);
          end
        else
          fprintf(', no impdance breaks during practice.\n');
        end
      else
        fprintf('.\n');
      end
      fprintf('\t\t\t%d test trials (%.2f min/phase @ %.2f sec/trial)',nTrials_test,((trialDur_test * nTrials_test) / 60),trialDur_test);
      fprintf(', %d blink breaks (every %d sec)',nBlinkBreaks_test,cfg.stim.secUntilBlinkBreak);
      if expParam.useNS
        if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
          fprintf(', %d impedance breaks',nImpedanceBreaks_test);
          if isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nTrials')
            fprintf(' (every %d trials).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials);
          elseif isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nBlocks')
            fprintf(' (every %d blocks).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks);
          end
        else
          fprintf(', no impdance breaks during practice.\n');
        end
      else
        fprintf('.\n');
      end
      
    else
      fprintf('\t\t\t%d trials (%.2f sec/trial)',nTrials,trialDur);
      fprintf(', %d blink breaks (every %d sec)',nBlinkBreaks,cfg.stim.secUntilBlinkBreak);
      if expParam.useNS
        if cfg.stim.(sesName).(phaseName)(phaseCount).isExp
          fprintf(', %d impedance breaks',nImpedanceBreaks);
          if isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nTrials')
            fprintf(' (every %d trials).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nTrials);
          elseif isfield(cfg.stim.(sesName).(phaseName),'impedanceAfter_nBlocks')
            fprintf(' (every %d blocks).\n',cfg.stim.(sesName).(phaseName)(phaseCount).impedanceAfter_nBlocks);
          end
        else
          fprintf(', no impdance breaks during practice.\n');
        end
      else
        fprintf('.\n');
      end
    end
    
    % add this phase to the session
    sesDur = sesDur + phaseDur + initialNetSetup;
  end % p
  
  if strcmp(durLimit,'min')
    fprintf('\tMINIMUM ');
  elseif strcmp(durLimit,'med')
    fprintf('\tMEDIUM ');
  elseif strcmp(durLimit,'max')
    fprintf('\tMAXIMUM ');
  end
  fprintf('session %s (%d/%d): %.2f min.\n',sesName,s,expParam.nSessions,(sesDur / 60));
  
  % add this session to the entire experiment
  expDur = expDur + sesDur;
end % s

if strcmp(durLimit,'min')
  fprintf('\nMINIMUM ');
elseif strcmp(durLimit,'med')
  fprintf('\nMEDIUM ');
elseif strcmp(durLimit,'max')
  fprintf('\nMAXIMUM ');
end
fprintf('%s experiment: %.2f min (across %d sessions).\n\n',expParam.expName,(expDur / 60),expParam.nSessions);

end