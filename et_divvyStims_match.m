function [chosenStimsSame,chosenStimsDiff,origStims] = et_divvyStims_match(origStims,sameStims,diffStims,nSame,nDiff,rmStims_orig,rmStims_pair,shuffleFirst,maxChosen)
%function [chosenStimsSame,chosenStimsDiff,origStims] = et_divvyStims_match(origStims,sameStims,diffStims,nSame,nDiff,rmStims_orig,rmStims_pair,shuffleFirst,maxChosen)
%
% Description:
%  Divide stimuli for the subordinate matching task.
%
% NB: Two fields are added: matchStimNum and matchPairNum.
%  Field 'matchStimNum' denotes whether a stimulus is stim1 or stim2.
%  Field 'matchPairNum' denotes which two stimuli are paired. matchPairNum
%   overlaps in the same and different condition; if same and diff stimuli
%   are combined, find the corresponding pair by searching for a matching
%   familyNum (basic or subordinate), a matching or different speciesNum
%   field (same or diff condition), a matching or different trained field,
%   the same matchPairNum, and the opposite matchStimNum (1 or 2).
%
% Input:
%  origStims:    Stimulus structure that you want to select from.
%  sameStims:    Empty array or existing struct to add the chosen "same"
%                condition stimuli to.
%  diffStims:    Empty array or existing struct to add the chosen "diff"
%                condition stimuli to.
%
%  nSame:        Integer. Number of "same" stimuli to choose from each
%                available species.
%  nDiff:        Integer. Number of "diff" stimuli to choose from each
%                available species.
%  rmStims_orig: True or false. Whether to remove stimuli during the
%                dividing of same and different stimuli into stim2 (from
%                origStims). If true, these conditions cannot overlap.
%                Use false when all stimuli should be in both same and
%                diff conditions (length(origStims) == nSame or nDiff).
%                Default = true.
%  rmStims_pair: Whether to remove stims when finding the stim1 pair for
%                the corresponding stim2. Default = true.
%  shuffleFirst: True or false. Randomly shuffle stimuli before selecting
%                nSame and nSiff from each species. False = select first
%                nSame/nDiff for each species. Optional (default = true).
%  origStims:    Original stimulus structure with the chosen stimuli
%                removed if rmStims_orig = true.
%  maxChosen:    Integer. Upper limit for choosing stimuli. Used in case
%                fewer than nStims x nSpecies are needed.
%
% Output:
%  chosenStimsSame: stimuli for the "same" condition.
%  chosenStimsDiff: stimuli for the "diff" condition.
%

if ~exist('rmStims_orig','var') || isempty(rmStims_orig)
  rmStims_orig = true;
end

if ~exist('rmStims_pair','var') || isempty(rmStims_pair)
  rmStims_pair = true;
end

if ~exist('shuffleFirst','var') || isempty(shuffleFirst)
  shuffleFirst = true;
end

if ~exist('maxChosen','var') || isempty(maxChosen)
  maxChosen = [];
end

if nSame == length(sameStims)
  warning('Setting rmStims_orig to false because nSame == length(sameStims). Otherwise you will run out of stimuli to divvy out.\n');
  rmStims_orig = false;
end

% only go through the species in the available stimuli
theseSpecies = unique([origStims.speciesNum]);

% same: half are stim2 in "same" condition
theseSameStims = [];
[theseSameStims,origStims] = et_divvyStims(...
  origStims,theseSameStims,nSame,rmStims_orig,shuffleFirst,...
  {'same', 'matchStimNum', 'matchPairNum'},{true, 2, []},maxChosen);
% different: other half are stim2 in "different" condition
theseDiffStims = [];
[theseDiffStims,origStims] = et_divvyStims(...
  origStims,theseDiffStims,nDiff,rmStims_orig,shuffleFirst,...
  {'same', 'matchStimNum', 'matchPairNum'},{false, 2, []},maxChosen);

% store the stimuli for slicing before modifying
stim2_same = theseSameStims;
stim2_diff = theseDiffStims;
stim1_same = theseDiffStims;
stim1_diff = theseSameStims;

% if we're doing a pratice session, we're probably using maxChosen, so we
% need to limit which species we can choose from
if ~isempty(maxChosen)
  theseSpecies = unique([theseSameStims.speciesNum]);
end

% same condition

% find stim1s for "same" cond (same species, stims from "diff" cond)
pairCount = 1;
for s = 1:length(theseSpecies)
  % get the stim2 for this species
  sInd_stim2 = find([stim2_same.speciesNum] == theseSpecies(s));
  % get the corresponding (same) stim1 indices
  sInd_stim1 = [stim1_same.speciesNum] == theseSpecies(s);
  % pull out these possible stim1s
  stim1_spec = stim1_same(sInd_stim1);
  
  not_good = true;
  while not_good
    % permute until each exemplar has a pair that is not the same number
    exemplarPair = randperm(length(sInd_stim2));
    if ~any([stim1_spec(exemplarPair).exemplarNum] == [theseSameStims(sInd_stim2).exemplarNum])
      not_good = false;
    end
  end
  % put them in the new order
  stim1_spec = stim1_spec(exemplarPair);
  
  for e = 1:length(sInd_stim2)
    theseSameStims(sInd_stim2(e)).matchPairNum = pairCount;
    % choose 1 stim1 for each stim2, setting the same pair number; don't
    % shuffleFirst so that we keep the new order
    [theseSameStims,stim1_spec] = et_divvyStims(...
      stim1_spec,theseSameStims,1,rmStims_pair,false,...
      {'same', 'matchStimNum', 'matchPairNum'},{true, 1, pairCount});
    pairCount = pairCount + 1;
  end
end

% different condition

% find stim1s for "diff" cond (diff species, stims from "same" cond)
pairCount = 1;
% find a species to pair each stim2 with
not_good = true;
while not_good
  % permute until each species has a pair that is not the same number
  speciesPair = randperm(length(theseSpecies));
  if ~any(speciesPair == theseSpecies)
    not_good = false;
  end
end
for s = 1:length(theseSpecies)
  % get the stim2 for this species
  sInd_stim2 = find([stim2_diff.speciesNum] == theseSpecies(s));
  % get the corresponding (diff) stim1 indices, from the permuted pairs
  sInd_stim1 = [stim1_diff.speciesNum] == speciesPair(theseSpecies(s));
  % pull out these possible stim1s
  stim1_spec = stim1_diff(sInd_stim1);
  for e = 1:length(sInd_stim2)
    theseDiffStims(sInd_stim2(e)).matchPairNum = pairCount;
    % choose 1 stim1 for each stim2, setting the same pair number
    [theseDiffStims,stim1_spec] = et_divvyStims(...
      stim1_spec,theseDiffStims,1,rmStims_pair,shuffleFirst,...
      {'same', 'matchStimNum', 'matchPairNum'},{false, 1, pairCount});
    pairCount = pairCount + 1;
  end
end

chosenStimsSame = cat(1,sameStims,theseSameStims);
chosenStimsDiff = cat(1,diffStims,theseDiffStims);

end