function [cfg,expParam,varargout] = et_processStims_name(cfg,expParam,sesName,phaseName,phaseCount,varargin)
% function [cfg,expParam,varargout] = et_processStims_name(cfg,expParam,sesName,phaseName,phaseCount,varargin)

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);

% initialize to hold the trained stimuli
expParam.session.(sesName).(phaseName)(phaseCount).nameStims = [];

% initialize output for families
nout = max(nargout,1) - 2;
varargout = cell(1,nout);

if ~phaseCfg.isExp
  % for the practice, put get stimuli from the remaining pool
  for f = 1:length(cfg.stim.familyNames)
    thisFam = varargin{f};
    
    % run et_divvyStims
    [expParam.session.(sesName).(phaseName)(phaseCount).nameStims,thisFam] = et_divvyStims(...
      thisFam,expParam.session.(sesName).(phaseName)(phaseCount).nameStims,1,...
      phaseCfg.rmStims,phaseCfg.shuffleFirst,{},{},...
      phaseCfg.nTrials);
    
    % store the (altered) family stimuli for output
    varargout{f} = thisFam;
  end
else
  % for the real experiment, put all the trained stimuli together
  for f = 1:length(cfg.stim.familyNames)
    expParam.session.(sesName).(phaseName)(phaseCount).nameStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).nameStims,expParam.session.(sprintf('f%dTrained',f)));
  end
end

% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming (%d) task stimuli.\n',sesName,phaseCount);
[expParam.session.(sesName).(phaseName)(phaseCount).nameStims] = et_shuffleStims(...
  expParam.session.(sesName).(phaseName)(phaseCount).nameStims,'familyNum',phaseCfg.nameMaxConsecFamily);

fprintf('Done.\n');

end % function
