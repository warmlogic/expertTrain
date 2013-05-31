function [cfg,expParam,varargout] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount,varargin)
% function [cfg,expParam,varargout] = et_processStims_match(cfg,expParam,sesName,phaseName,phaseCount,varargin)

% TODO: don't need to store expParam.session.(sesName).match.same and
% expParam.session.(sesName).match.diff because allStims gets created and
% is all we need. Instead, replace them with sameStims and diffStims.

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);

% initialize to hold all the same and different stimuli
expParam.session.(sesName).(phaseName)(phaseCount).same = [];
expParam.session.(sesName).(phaseName)(phaseCount).diff = [];

% initialize output for families
nout = max(nargout,1) - 2;
varargout = cell(1,nout);

if ~phaseCfg.isExp
  % this is the practice session
  for f = 1:length(cfg.stim.familyNames)
    thisFam = varargin{f};
    
    % practice stimuli
    [expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff] = et_divvyStims_match(...
      thisFam,...
      expParam.session.(sesName).(phaseName)(phaseCount).same,expParam.session.(sesName).(phaseName)(phaseCount).diff,...
      phaseCfg.nSame,phaseCfg.nDiff,...
      phaseCfg.rmStims_orig,phaseCfg.rmStims_pair,phaseCfg.shuffleFirst,...
      (phaseCfg.nSame + phaseCfg.nDiff));
    
    % store the (altered) family stimuli for output
    varargout{f} = thisFam;
  end
  % add in the 'trained' field because we need it for running the task
  for e = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).same)
    expParam.session.(sesName).(phaseName)(phaseCount).same(e).trained = -1;
  end
  for e = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).diff)
    expParam.session.(sesName).(phaseName)(phaseCount).diff(e).trained = -1;
  end
else
  % this is the real experiment
  for f = 1:length(cfg.stim.familyNames)
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

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,phaseCount);
[expParam.session.(sesName).(phaseName)(phaseCount).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).(phaseName)(phaseCount).same,...
  expParam.session.(sesName).(phaseName)(phaseCount).diff,...
  phaseCfg.stim2MinRepeatSpacing);

fprintf('Done.\n');

end % function
