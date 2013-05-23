function [cfg,expParam] = et_processStims_name(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_name(cfg,expParam,sesName,phaseName,phaseCount)

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

% put all the trained stimuli together
expParam.session.(sesName).(phaseName)(phaseCount).nameStims = eval(['cat(1',sprintf(repmat(',expParam.session.f%dTrained',1,length(cfg.stim.familyNames)),1:length(cfg.stim.familyNames)),');']);
% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming (%d) task stimuli.\n',sesName,phaseCount);
[expParam.session.(sesName).(phaseName)(phaseCount).nameStims] = et_shuffleStims(...
  expParam.session.(sesName).(phaseName)(phaseCount).nameStims,'familyNum',cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily);

fprintf('Done.\n');

end % function
