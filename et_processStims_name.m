function [cfg,expParam] = et_processStims_name(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_name(cfg,expParam,sesName,phaseName,phaseCount)

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

% initialize to hold the trained stimuli
expParam.session.(sesName).(phaseName)(phaseCount).nameStims = [];
% put all the trained stimuli together
for f = 1:length(cfg.stim.familyNames)
  expParam.session.(sesName).(phaseName)(phaseCount).nameStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).nameStims,expParam.session.(sprintf('f%dTrained',f)));
end

% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming (%d) task stimuli.\n',sesName,phaseCount);
[expParam.session.(sesName).(phaseName)(phaseCount).nameStims] = et_shuffleStims(...
  expParam.session.(sesName).(phaseName)(phaseCount).nameStims,'familyNum',cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily);

fprintf('Done.\n');

end % function
