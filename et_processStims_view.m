function [cfg,expParam] = et_processStims_view(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_view(cfg,expParam,sesName,phaseName,phaseCount)

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

if ~isfield(cfg.stim.(sesName).(phaseName)(phaseCount),'viewMaxConsecFamily')
  cfg.stim.(sesName).(phaseName)(phaseCount).viewMaxConsecFamily = 0;
end

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);

if ~isfield(phaseCfg,'familyNames')
  if ~phaseCfg.isExp
    phaseCfg.familyNames = cfg.stim.practice.familyNames;
  else
    phaseCfg.familyNames = cfg.stim.familyNames;
  end
end

% initialize to hold the trained stimuli
expParam.session.(sesName).(phaseName)(phaseCount).viewStims = [];

if ~phaseCfg.isExp
  % for the practice, put all the practice stimuli together
  for f = 1:length(cfg.stim.practice.familyNames)
    if ismember(cfg.stim.practice.familyNames{f},phaseCfg.familyNames)
      expParam.session.(sesName).(phaseName)(phaseCount).viewStims = cat(1,...
        expParam.session.(sesName).(phaseName)(phaseCount).viewStims,expParam.session.(sprintf('f%dPractice',f)));
    end
  end
else
  % for the real experiment, put all the trained stimuli together
  for f = 1:length(cfg.stim.familyNames)
    if ismember(cfg.stim.familyNames{f},phaseCfg.familyNames)
      expParam.session.(sesName).(phaseName)(phaseCount).viewStims = cat(1,...
        expParam.session.(sesName).(phaseName)(phaseCount).viewStims,expParam.session.(sprintf('f%dTrained',f)));
    end
  end
end

% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming (%d) task stimuli.\n',sesName,phaseCount);
[expParam.session.(sesName).(phaseName)(phaseCount).viewStims] = et_shuffleStims(...
  expParam.session.(sesName).(phaseName)(phaseCount).viewStims,'familyNum',phaseCfg.viewMaxConsecFamily);

fprintf('Done.\n');

end % function
