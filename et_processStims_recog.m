function [cfg,expParam,varargout] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount,varargin)
% function [cfg,expParam,varargout] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount,varargin)
%
% e.g., [cfg,expParam,stimStruct.fStims] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount,stimStruct.fStims);
%       where stimStruct(f).fStims is a struct for each family
%

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

% initialize for storing both families together
expParam.session.(sesName).(phaseName)(phaseCount).targStims = cell(1,cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks);
expParam.session.(sesName).(phaseName)(phaseCount).lureStims = cell(1,cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks);
expParam.session.(sesName).(phaseName)(phaseCount).allStims = cell(1,cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks);

% initialize output for families
nout = max(nargout,1) - 2;
varargout = cell(1,nout);
%varargout = cell(1,length(cfg.stim.familyNames));

for b = 1:cfg.stim.(sesName).(phaseName)(phaseCount).nBlocks
  
  for f = 1:length(cfg.stim.familyNames)
    thisFam = varargin{f};
    
    % targets
    [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},thisFam] = et_divvyStims(...
      thisFam,[],cfg.stim.(sesName).(phaseName)(phaseCount).nStudyTarg,...
      cfg.stim.(sesName).(phaseName)(phaseCount).rmStims,cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst,{'targ'},{1});
    % lures
    [expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b},thisFam] = et_divvyStims(...
      thisFam,[],cfg.stim.(sesName).(phaseName)(phaseCount).nTestLure,...
      cfg.stim.(sesName).(phaseName)(phaseCount).rmStims,cfg.stim.(sesName).(phaseName)(phaseCount).shuffleFirst,{'targ'},{0});
    
    % store the (altered) family stimuli for output
    varargout{f} = thisFam;
  end
  
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
