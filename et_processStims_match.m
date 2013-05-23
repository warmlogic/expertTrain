function [cfg,expParam] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount)

% TODO: don't need to store expParam.session.(sesName).match.same and
% expParam.session.(sesName).match.diff because allStims gets created and
% is all we need. Instead, replace them with sameStims and diffStims.

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

% initialize to hold all the same and different stimuli
expParam.session.(sesName).(phaseName)(phaseCount).same = [];
expParam.session.(sesName).(phaseName)(phaseCount).diff = [];

for f = 1:length(cfg.stim.familyNames)
  % trained
  [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff] = et_divvyStims_match(...
    expParam.session.(sprintf('f%dTrained',f)),...
    expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
    cfg.stim.(sesName).(phaseName)(phaseCount).nSame,cfg.stim.(sesName).(phaseName)(phaseCount).nDiff,...
    cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig,cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair,cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst);
  
  % untrained
  [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff] = et_divvyStims_match(...
    expParam.session.(sprintf('f%dUntrained',f)),...
    expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
    cfg.stim.(sesName).(phaseName)(phaseCount).nSame,cfg.stim.(sesName).(phaseName)(phaseCount).nDiff,...
    cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_orig,cfg.stim.(sesName).(phaseName)(phaseCount).rmStims_pair,cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst);
end

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,phaseCount);
[expParam.session.(sesName).(phaseName)(phaseCount).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).(phaseName)(phaseCount).same,...
  expParam.session.(sesName).(phaseName)(phaseCount).diff,...
  cfg.stim.(sesName).(phaseName)(phaseCount).stim2MinRepeatSpacing);

fprintf('Done.\n');

end % function
