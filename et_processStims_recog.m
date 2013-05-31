function [cfg,expParam,varargout] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount,varargin)
% function [cfg,expParam,varargout] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount,varargin)
%
% e.g., [cfg,expParam,stimStruct.fStims] = et_processStims_recog(cfg,expParam,sesName,phaseName,phaseCount,stimStruct.fStims);
%       where stimStruct(f).fStims is a struct for each family
%

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);

% initialize for storing both families together
expParam.session.(sesName).(phaseName)(phaseCount).targStims = cell(1,phaseCfg.nBlocks);
expParam.session.(sesName).(phaseName)(phaseCount).lureStims = cell(1,phaseCfg.nBlocks);
expParam.session.(sesName).(phaseName)(phaseCount).allStims = cell(1,phaseCfg.nBlocks);

% initialize output for families
nout = max(nargout,1) - 2;
varargout = cell(1,nout);

for b = 1:phaseCfg.nBlocks
  if ~phaseCfg.isExp
    % this is the practice session
    while length(expParam.session.(sesName).(phaseName)(phaseCount).targStims{b}) < phaseCfg.nStudyTarg
      for f = 1:length(cfg.stim.familyNames)
        thisFam = varargin{f};
        
        % targets
        [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},thisFam] = et_divvyStims(...
          thisFam,expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},1,...
          phaseCfg.rmStims,phaseCfg.shuffleFirst,{'targ'},{1},...
          ceil(phaseCfg.nStudyTarg / length(cfg.stim.familyNames)));
        % store the (altered) family stimuli for output
        varargout{f} = thisFam;
      end
    end
    while length(expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b}) < phaseCfg.nTestLure
      for f = 1:length(cfg.stim.familyNames)
        thisFam = varargin{f};
        % lures
        [expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b},thisFam] = et_divvyStims(...
          thisFam,expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b},1,...
          phaseCfg.rmStims,phaseCfg.shuffleFirst,{'targ'},{0},...
          ceil(phaseCfg.nTestLure / length(cfg.stim.familyNames)));
        
        % store the (altered) family stimuli for output
        varargout{f} = thisFam;
      end
    end
  else
    % this is the real experiment
    for f = 1:length(cfg.stim.familyNames)
      thisFam = varargin{f};
      
      % targets
      [expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},thisFam] = et_divvyStims(...
        thisFam,expParam.session.(sesName).(phaseName)(phaseCount).targStims{b},phaseCfg.nStudyTarg,...
        phaseCfg.rmStims,phaseCfg.shuffleFirst,{'targ'},{1});
      % lures
      [expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b},thisFam] = et_divvyStims(...
        thisFam,expParam.session.(sesName).(phaseName)(phaseCount).lureStims{b},phaseCfg.nTestLure,...
        phaseCfg.rmStims,phaseCfg.shuffleFirst,{'targ'},{0});
      
      % store the (altered) family stimuli for output
      varargout{f} = thisFam;
    end
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
