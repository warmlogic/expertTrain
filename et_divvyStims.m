function [stim,expParam] = et_divvyStims(cfg,expParam,stim,nStim,destFields)
% [stim,expParam] = et_divvyStims(cfg,expParam,stim,nCond,dest)
%
% Input:
%  cfg:        config structure.
%  expParam:   experiment parameter structure.
%  stim:       stimulus structure that you want to select from.
%  nStim:      integer denoting the number of stimuli for this condition.
%  destFields: 3-element cell array denoting the fields in expParam.session
%              to store the chosen stimuli for this condition.
%              e.g., {'pretest','recog','targ'} or {'pretest','recog','lure'}
%
% Output:
%  stim:     original stimulus structure with the chosen stimuli removed
%  expParam: experiment parameter structure with the chosen stimuli
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

% loop through every species
for s = 1:cfg.stim.nSpecies
  % which indices does this species occupy?
  sInd = find([stim.speciesNum] == s);
  
  % shuffle the stimulus index
  %randsel = randperm(length(sInd));
  % debug
  randsel = 1:length(sInd);
  fprintf('NB: Debug code. Not actually randomizing!\n');
  % get the indices of the stimuli that we want
  chosenInd = sInd(randsel(1:nStim));
  % add them to the list
  expParam.session.(destFields{1}).(destFields{2}).(destFields{3}) = cat(1,expParam.session.(destFields{1}).(destFields{2}).(destFields{3}),stim(chosenInd));
  
  % remove the randomly chosen stimuli from the available pool
  for rm = 1:length(chosenInd)
    stim([stim.number] == chosenInd(rm)) = [];
  end
end

end

% original code

%ind2 = sInd(randsel(nCond+1:(nCond+nCond2)));
%expParam.session.(dest2{1}).(dest2{2}).(dest2{3}) = cat(1,expParam.session.(dest2{1}).(dest2{2}).(dest2{3}),stim(ind2));

% match

%     % family 1
%     expParam.session.pretest.match.f1Trained = [];
%     expParam.session.pretest.match.f1Untrained = [];
%     for s = 1:cfg.stim.nSpecies
%       % which indices does this species occupy?
%       sInd = find([f1Stim.speciesNum] == s);
%       thisSpecies_number = [f1Stim(sInd).number];
%       % shuffle the stimulus index
%       %randsel = randperm(length(sInd));
%       % debug
%       randsel = 1:length(sInd);
%       % get the indices of the stimuli that we want
%       tInd = thisSpecies_number(randsel(1:cfg.stim.pretest.match.nTrained));
%       utInd = thisSpecies_number(randsel(cfg.stim.pretest.match.nTrained+1:(cfg.stim.pretest.match.nTrained+cfg.stim.pretest.match.nUntrained)));
%       % add them to the list
%       expParam.session.pretest.match.f1Trained = cat(1,expParam.session.pretest.match.f1Trained,f1Stim(tInd));
%       expParam.session.pretest.match.f1Untrained = cat(1,expParam.session.pretest.match.f1Untrained,f1Stim(utInd));
%       
%       % remove the randomly chosen stimuli from the available pool
%       for rm = 1:length(tInd)
%         f1Stim([f1Stim.number] == tInd(rm)) = [];
%       end
%       for rm = 1:length(utInd)
%         f1Stim([f1Stim.number] == utInd(rm)) = [];
%       end
%     end

% recog

%     % family 1
%     expParam.session.pretest.recog.targ = [];
%     expParam.session.pretest.recog.lure = [];
%     for s = 1:cfg.stim.nSpecies
%       % which indices does this species occupy?
%       sInd = find([f1Stim.speciesNum] == s);
%       thisSpecies_number = [f1Stim(sInd).number];
%       % shuffle the stimulus index
%       %randsel = randperm(length(sInd));
%       % debug
%       randsel = 1:length(sInd);
%       % get the indices of the stimuli that we want
%       tInd = thisSpecies_number(randsel(1:cfg.stim.pretest.recog.nStudyTarg));
%       lInd = thisSpecies_number(randsel(cfg.stim.pretest.recog.nStudyTarg+1:(cfg.stim.pretest.recog.nStudyTarg+cfg.stim.pretest.recog.nTestLure)));
%       % add them to the list
%       expParam.session.pretest.recog.targ = cat(1,expParam.session.pretest.recog.targ,f1Stim(tInd));
%       expParam.session.pretest.recog.lure = cat(1,expParam.session.pretest.recog.lure,f1Stim(lInd));
%       
%       % remove the randomly chosen stimuli from the available pool
%       for rm = 1:length(tInd)
%         f1Stim([f1Stim.number] == tInd(rm)) = [];
%       end
%       for rm = 1:length(lInd)
%         f1Stim([f1Stim.number] == lInd(rm)) = [];
%       end
%     end
