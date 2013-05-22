function [cfg,expParam,f1Stim,f2Stim] = et_processStims_recog(cfg,expParam,f1Stim,f2Stim,sesName,phaseName,phaseCount)
% function [cfg,expParam,f1Stim,f2Stim] = et_processStims_recog(cfg,expParam,f1Stim,f2Stim,sesName,phaseName,phaseCount)

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

% initialize for storing both families together
expParam.session.(sesName).(phaseName)(phaseCount).targStims = cell(1,cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks);
expParam.session.(sesName).(phaseName)(phaseCount).lureStims = cell(1,cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks);
expParam.session.(sesName).(phaseName)(phaseCount).allStims = cell(1,cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks);

for b = 1:cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks
  % family 1
  
  % targets
  [f1Stim,expParam.session.(sesName).(phaseName)(phaseCount).targStims{b}] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).(phaseName)(phaseCount).nStudyTarg,...
    cfg.stim.(sesName).(phaseName)(phaseCount).rmStims,cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst,{'targ'},{1});
  % lures
  [f1Stim,expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b}] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).(phaseName)(phaseCount).nTestLure,...
    cfg.stim.(sesName).(phaseName)(phaseCount).rmStims,cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst,{'targ'},{0});
  
  % family 2
  
  % add targets to the existing list
  [f2Stim,expParam.session.(sesName).(phaseName)(phaseCount).targStims{b}] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},cfg.stim.(sesName).(phaseName)(phaseCount).nStudyTarg,...
    cfg.stim.(sesName).(phaseName)(phaseCount).rmStims,cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst,{'targ'},{1});
  % add lures to the existing list
  [f2Stim,expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b}] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b},cfg.stim.(sesName).(phaseName)(phaseCount).nTestLure,...
    cfg.stim.(sesName).(phaseName)(phaseCount).rmStims,cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst,{'targ'},{0});
  
  % shuffle the study stims so no more than X of the same family appear in
  % a row, if desired
  fprintf('Shuffling %s recognition study (%d) task stimuli.\n',sesName,phaseCount);
  [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},'familyNum',cfg.stim.(sesName).(phaseName)(phaseCount).studyMaxConsecFamily);
  
  % put the test stims together
  expParam.session.(sesName).(phaseName)(phaseCount).allStims{b} = cat(1,...
    expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},...
    expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b});
  % shuffle so there are no more than X targets or lures in a row
  fprintf('Shuffling %s recognition test (%d) task stimuli.\n',sesName,phaseCount);
  [expParam.session.(sesName).(phaseName)(phaseCount).allStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).(phaseName)(phaseCount).allStims{b},'targ',cfg.stim.(sesName).(phaseName)(phaseCount).testMaxConsec);
end

fprintf('Done.\n');

end % function
