function [chosenStims,origStims] = et_divvyStims(origStims,chosenStims,nStims,rmStims,shuffleFirst,newField,newValue)
% [chosenStims,origStims] = et_divvyStims(origStims,chosenStims,nStims,rmStims,shuffleFirst,newField,newValue)
%
% Description:
%  Shuffle a stimulus set (origStims) and slice out a subset (nStims) of
%  each available species into a new struct (chosenStims). If desired, add
%  new fields and values to the chosen stimuli (newField and newValue).
%
% Input:
%  origStims:    Stimulus structure that you want to select from.
%  chosenStims:  Empty array or existing struct to add the chosen to. If
%                it's an existing struct, must have the same fields as what
%                you're expecting to return (i.e., newField/newValue).
%  nStims:       Integer. The number of stimuli to choose from each species.
%  rmStims:      True or false. Whether to remove stimuli. (default = true)
%  shuffleFirst: True or false. Randomly shuffle stimuli before selecting
%                nStim from each species. False = select first nStim for
%                each species. Optional (default = true).
%  newField:     String(s) in a cell. In case you want to add a new field to
%                all these stimuli (e.g., targ or lure).
%                Optional (default = {}).
%  newValue:     Cell (same number of elements as newField). The value(s)
%                for the new field(s). Optional (default = {}).
%
% Output:
%  chosenStims: Struct containing the chosen stimuli from each available
%               species. New fields and values are added to these stims.
%  origStims:   Original stimulus structure with the chosen stimuli removed
%               if rmStims = true.
%

if ~exist('rmStims','var') || isempty(rmStims)
  rmStims = true;
end

if ~exist('newField','var') || isempty(newField)
  newField = {};
end

if ~exist('newValue','var') || isempty(newValue)
  newValue = {};
end

if isempty(origStims)
  error('There are no stimuli in origStims to divvy out! You might have run out of stimuli because rmStims=true and they all got divvied out for other phases.');
end

if ~isempty(newField)
  if length(newField) ~= length(newValue)
    error('newField and newValue are not the same length');
  end
end

% add the new field to all stims so we can concatenate
if ~isempty(newField)
  for f = 1:length(newField)
    origStims(1).(newField{f}) = [];
  end
end

% only go through the species in the available stimuli
theseSpecies = unique([origStims.speciesNum]);

% loop through every species
for s = 1:length(theseSpecies)
  % which indices does this species occupy?
  sInd = find([origStims.speciesNum] == theseSpecies(s));
  
  % shuffle the stimulus index
  if shuffleFirst
    randind = randperm(length(sInd));
  else
    randind = 1:length(sInd);
  end
  % get the indices of the stimuli that we want
  chosenInd = sInd(randind(1:nStims));
  
  if ~isempty(newField)
    % add new fields and values to these stimuli
    for f = 1:length(newField)
      for e = 1:length(chosenInd)
        origStims(chosenInd(e)).(newField{f}) = newValue{f};
      end
    end
  end
  
  % add them to the list
  chosenStims = cat(1,chosenStims,origStims(chosenInd));
  
  if rmStims
    origStims(chosenInd) = [];
  end
end

if ~isempty(newField)
  % remove the field from the stims struct
  for f = 1:length(newField)
    origStims = rmfield(origStims,newField{f});
  end
end

end
