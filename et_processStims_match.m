function [cfg,expParam] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount)

% TODO: don't need to store expParam.session.(sesName).match.same and
% expParam.session.(sesName).match.diff because allStims gets created and
% is all we need. Instead, replace them with sameStims and diffStims.

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);

if ~isfield(phaseCfg,'familyNames')
  if ~phaseCfg.isExp
    phaseCfg.familyNames = cfg.stim.practice.familyNames;
  else
    phaseCfg.familyNames = cfg.stim.familyNames;
  end
end

% initialize to hold all the same and different stimuli
expParam.session.(sesName).(phaseName)(phaseCount).same = [];
expParam.session.(sesName).(phaseName)(phaseCount).diff = [];

if ~phaseCfg.isExp
  % this is the practice session
  for f = 1:length(cfg.stim.practice.familyNames)
    if ismember(cfg.stim.practice.familyNames{f},phaseCfg.familyNames)
      [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff] = et_divvyStims_match(...
        expParam.session.(sprintf('f%dPractice',f)),...
        expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
        phaseCfg.nSame,phaseCfg.nDiff,...
        phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst);
    end
  end
  % add in the 'trained' field because we need it for running the task
  for e = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).same)
    expParam.session.(sesName).(phaseName)(phaseCount).same(e).trained = false;
  end
  for e = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).diff)
    expParam.session.(sesName).(phaseName)(phaseCount).diff(e).trained = false;
  end
else
  % this is the real experiment
  for f = 1:length(cfg.stim.familyNames)
    if ismember(cfg.stim.familyNames{f},phaseCfg.familyNames)
      % trained
      [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff] = et_divvyStims_match(...
        expParam.session.(sprintf('f%dTrained',f)),...
        expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
        phaseCfg.nSame,phaseCfg.nDiff,...
        phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst);
      
      % untrained
      [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff] = et_divvyStims_match(...
        expParam.session.(sprintf('f%dUntrained',f)),...
        expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
        phaseCfg.nSame,phaseCfg.nDiff,...
        phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst);
    end
  end
end

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,phaseCount);
[expParam.session.(sesName).(phaseName)(phaseCount).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).(phaseName)(phaseCount).same,...
  expParam.session.(sesName).(phaseName)(phaseCount).diff,...
  phaseCfg.stim2MinRepeatSpacing);

fprintf('Done.\n');

end % function
