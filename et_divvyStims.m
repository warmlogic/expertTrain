function [stim,expParam] = et_divvyStims(cfg,expParam,stim,nStim,destFields,rmStims)
% [stim,expParam] = et_divvyStims(cfg,expParam,stim,nStim,destFields,rmStims)
%
% Description:
%  Shuffle a stimulus set and slice out a subset of each species.  Return
%  in a specific heirarchy of struct fields.
%
% Input:
%  cfg:        config structure.
%  expParam:   experiment parameter structure.
%  stim:       stimulus structure that you want to select from.
%  nStim:      integer denoting the number of stimuli for this condition.
%  destFields: 3-element cell array denoting the fields in expParam.session
%              to store the chosen stimuli for this condition.
%              e.g., {'pretest','recog','targ'} or {'pretest','recog','lure'}
%  rmStims:    true or false, whether to remove stimuli. (default = true)
%
% Output:
%  stim:     original stimulus structure with the chosen stimuli removed if
%            rmStims = true.
%  expParam: experiment parameter structure with the chosen stimuli
%
% NB:
%  You must initialize the destination field manually.
%   e.g., expParam.session.pretest.recog.targ = [];
%      or expParam.session.pretest.recog.lure = [];
%

if ~exist('rmStims','var') || isempty(rmStims)
  rmStims = true;
end

% Make sure the destination fields exist
if ~isfield(expParam.session,destFields{1})
  error('Must initialize the expParam.session.%s field and all subfields!',destFields{1});
elseif ~isfield(expParam.session.(destFields{1}),destFields{2})
  error('Must initialize the expParam.session.%s.%s field and its subfield!',destFields{1},destFields{2});
elseif ~isfield(expParam.session.(destFields{1}).(destFields{2}),destFields{3})
  error('Must initialize the expParam.session.%s.%s.%s field!',destFields{1},destFields{2},destFields{3});
end

% loop through every species
for s = 1:cfg.stim.nSpecies
  % which indices does this species occupy?
  sInd = find([stim.speciesNum] == s);
  
  % shuffle the stimulus index
  %randsel = randperm(length(sInd));
  % debug
  randsel = 1:length(sInd);
  fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  % get the indices of the stimuli that we want
  chosenInd = sInd(randsel(1:nStim));
  % add them to the list
  expParam.session.(destFields{1}).(destFields{2}).(destFields{3}) = cat(1,expParam.session.(destFields{1}).(destFields{2}).(destFields{3}),stim(chosenInd));
  
  if rmStims
    stim(chosenInd) = [];
  end
end

end
