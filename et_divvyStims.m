function [stims,expParam] = et_divvyStims(cfg,expParam,stims,nStim,destFields,rmStims,newField,newValue)
% [stim,expParam] = et_divvyStims(cfg,expParam,stim,nStim,destFields,rmStims,newField,newValue)
%
% Description:
%  Shuffle a stimulus set and slice out a subset of each species.  Return
%  in a specific heirarchy of struct fields.
%
% Input:
%  cfg:        config structure.
%  expParam:   experiment parameter structure.
%  stims:      stimulus structure that you want to select from.
%  nStim:      integer denoting the number of stimuli for this condition.
%  destFields: 3-element cell array denoting the fields in expParam.session
%              to store the chosen stimuli for this condition.
%              e.g., {'pretest','recog','targ'} or {'pretest','recog','lure'}
%  rmStims:    true or false, whether to remove stimuli. (default = true)
%  newField:   in case you want to add a new field to all these stimuli
%              (e.g., targ or lure). Optional.
%  newValue:   the value for the new field. Optional.
%
% Output:
%  stims:    original stimulus structure with the chosen stimuli removed if
%            rmStims = true.
%  expParam: experiment parameter structure with the chosen stimuli. This
%            is where the new field and value get added.
%
% NB:
%  You must initialize the destination field manually.
%   e.g., expParam.session.pretest.recog.targ = [];
%      or expParam.session.pretest.recog.lure = [];
%

% Make sure the destination fields exist
if ~isfield(expParam.session,destFields{1})
  error('Must initialize the expParam.session.%s field and all subfields!',destFields{1});
elseif ~isfield(expParam.session.(destFields{1}),destFields{2})
  error('Must initialize the expParam.session.%s.%s field and its subfield!',destFields{1},destFields{2});
elseif ~isfield(expParam.session.(destFields{1}).(destFields{2}),destFields{3})
  error('Must initialize the expParam.session.%s.%s.%s field!',destFields{1},destFields{2},destFields{3});
end

if ~exist('rmStims','var') || isempty(rmStims)
  rmStims = true;
end

if ~exist('newField','var') || isempty(newField)
  newField = {};
end

if ~exist('newValue','var') || isempty(newValue)
  newValue = {};
end

if ~isempty(newField)
  if length(newField) ~= length(newValue)
    error('newField and newValue are not the same length');
  end
end

% add the new field to all stims so we can concatenate
if ~isempty(newField)
  for f = 1:length(newField)
    stims(1).(newField{f}) = [];
  end
end

% only go through the species in the available stimuli
theseSpecies = unique([stims.speciesNum]);

% loop through every species
for s = 1:length(theseSpecies)
  % which indices does this species occupy?
  sInd = find([stims.speciesNum] == theseSpecies(s));
  
  % shuffle the stimulus index
  %randsel = randperm(length(sInd));
  % debug
  randsel = 1:length(sInd);
  fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
  % get the indices of the stimuli that we want
  chosenInd = sInd(randsel(1:nStim));
  
  if ~isempty(newField)
    for f = 1:length(newField)
      % add the new field and value to these stimuli
      for e = 1:length(chosenInd)
        stims(chosenInd(e)).(newField{f}) = newValue{f};
      end
    end
  end
  
  % add them to the list
  expParam.session.(destFields{1}).(destFields{2}).(destFields{3}) = cat(1,expParam.session.(destFields{1}).(destFields{2}).(destFields{3}),stims(chosenInd));
  
  if rmStims
    stims(chosenInd) = [];
  end
end

if ~isempty(newField)
  % remove the field from the stims struct
  for f = 1:length(newField)
    stims = rmfield(stims,newField{f});
  end
end

end
