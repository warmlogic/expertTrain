function [cfg,expParam] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount)
%

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);

% initialize for storing both families together
expParam.session.(sesName).(phaseName)(phaseCount).targStims = cell(1,phaseCfg.nBlocks);
expParam.session.(sesName).(phaseName)(phaseCount).lureStims = cell(1,phaseCfg.nBlocks);

if ~phaseCfg.isExp
  nFamilies = length(cfg.stim.practice.familyNames);
else
  nFamilies = length(cfg.stim.familyNames);
end

for b = 1:phaseCfg.nBlocks
  % this is for both practice and the real experiment
  
  for f = 1:nFamilies
    % targets
    [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},expParam.session.(sesName).(phaseName)(phaseCount).allStims{b}] = et_divvyStims(...
      expParam.session.(sesName).(phaseName)(phaseCount).allStims{b},expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},phaseCfg.nStudyTarg,...
      phaseCfg.rmStims,phaseCfg.shuffleFirst,{'targ'},{1});
    % lures
    [expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b},expParam.session.(sesName).(phaseName)(phaseCount).allStims{b}] = et_divvyStims(...
      expParam.session.(sesName).(phaseName)(phaseCount).allStims{b},expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b},phaseCfg.nTestLure,...
      phaseCfg.rmStims,phaseCfg.shuffleFirst,{'targ'},{0});
  end
  
  % shuffle the study stims so no more than X of the same family appear in
  % a row, if desired
  fprintf('Shuffling %s recognition study (%d) task stimuli.\n',sesName,phaseCount);
  [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},'familyNum',phaseCfg.studyMaxConsecFamily);
  
  % put the test stims together
  expParam.session.(sesName).(phaseName)(phaseCount).allStims{b} = cat(1,...
    expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},...
    expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b});
  % shuffle so there are no more than X targets or lures in a row
  fprintf('Shuffling %s recognition test (%d) task stimuli.\n',sesName,phaseCount);
  [expParam.session.(sesName).(phaseName)(phaseCount).allStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).(phaseName)(phaseCount).allStims{b},'targ',phaseCfg.testMaxConsec);
end

fprintf('Done.\n');

end % function
