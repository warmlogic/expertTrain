function [cfg,expParam] = et_processStims_compare(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_compare(cfg,expParam,sesName,phaseName,phaseCount)

% TODO: don't need to store expParam.session.(sesName).match.same and
% expParam.session.(sesName).match.diff because allStims gets created and
% is all we need. Instead, replace them with sameStims and diffStims.

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);

if ~isfield(phaseCfg,'familyNames')
  if ~phaseCfg.isExp
    phaseCfg.familyNames = cfg.stim.practice.familyNames;
  else
    phaseCfg.familyNames = cfg.stim.familyNames;
  end
end

% initialize to store the stimuli

% view half of the stims (60)
expParam.session.(sesName).(phaseName)(phaseCount).viewStims = [];
% between species comparisons (collapsing across families) (190 x 2)
expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims = [];
% within species comparisons (120 x 2)
expParam.session.(sesName).(phaseName)(phaseCount).wiSpeciesStims = [];

if ~phaseCfg.isExp
  error('practice is not set up for comparison');
else
  % this is the real experiment
  
  betweenStims = [];
  withinStims = [];
  for f = 1:length(cfg.stim.familyNames)
    % add them to the viewing list
    expParam.session.(sesName).(phaseName)(phaseCount).viewStims = cat(1,...
      expParam.session.(sesName).(phaseName)(phaseCount).viewStims,...
      expParam.session.(sprintf('f%dTrained',f)));
    
    % gather this family together
    thisFamilyBt = [];
    thisFamilyBt = cat(1,...
      thisFamilyBt,...
      expParam.session.(sprintf('f%dTrained',f)));
    thisFamilyBt = cat(1,...
      thisFamilyBt,...
      expParam.session.(sprintf('f%dUntrained',f)));
    
    thisFamilyWi = thisFamilyBt;
    
    % add it to the list of between stimuli
    %
    % half are stim 1 (e.g., presented on the left)
    [betweenStims,thisFamilyBt] = et_divvyStims(...
      thisFamilyBt,betweenStims,cfg.stim.nTrained,phaseCfg.rmStims_orig,phaseCfg.shuffleFirst,...
      {'compStimNum', 'compPairNum'},{1, []},[]);
    % half are stim 2 (e.g., presented on the right)
    [betweenStims] = et_divvyStims(...
      thisFamilyBt,betweenStims,cfg.stim.nTrained,phaseCfg.rmStims_orig,phaseCfg.shuffleFirst,...
      {'compStimNum', 'compPairNum'},{2, []},[]);
    
    % add it to the list of within stimuli
    %
    % half are stim 1 (e.g., presented on the left)
    [withinStims,thisFamilyWi] = et_divvyStims(...
      thisFamilyWi,withinStims,cfg.stim.nTrained,phaseCfg.rmStims_orig,phaseCfg.shuffleFirst,...
      {'compStimNum', 'compPairNum'},{1, []},[]);
    % half are stim 2 (e.g., presented on the right)
    [withinStims] = et_divvyStims(...
      thisFamilyWi,withinStims,cfg.stim.nTrained,phaseCfg.rmStims_orig,phaseCfg.shuffleFirst,...
      {'compStimNum', 'compPairNum'},{2, []},[]);
  end
  
  % between species comparisons

  % only go through the species in the available stimuli
  theseSpecies = unique([betweenStims.speciesNum]);
  theseFamilies = unique([betweenStims.familyNum]);
  
  nExemplar = length(unique([betweenStims.exemplarNum]));
  
  % which species comparisons to make
  theseBtComps = nchoosek(1:(length(theseSpecies) * length(theseFamilies)),2);
  % randomize the order
  compOrder = randperm(size(theseBtComps,1));
  theseBtComps = theseBtComps(compOrder,:);
  
  % set up a matrix to keep track of which exemplar to choose next
  thisFullExempInd = ones(length(theseSpecies) * length(theseFamilies),length(theseSpecies));
  % set up random indices for which exemplars to re-use
  for i = 1:size(thisFullExempInd,2)
    thisFullExempInd(1:nExemplar,i) = 1:nExemplar;
    randExemplar = randperm(nExemplar);
    thisFullExempInd(nExemplar+1:size(thisFullExempInd,1),i) = randExemplar(1:size(thisFullExempInd,1) - nExemplar);
  end
  
  % initialize to keep track of the current index
  thisExempInd = 1;
  thatPartExempInd = struct;
  thatPartExempInd.s1 = 1;
  thatPartExempInd.s2 = 1;
  
  for i = 1:size(theseBtComps,1)
    % reset the index if the count gets high enough
    if thisExempInd > (length(theseSpecies) * length(theseFamilies))
      thisExempInd = 1;
    end
    if thatPartExempInd.s1 > nExemplar/2
      thatPartExempInd.s1 = 1;
    end
    if thatPartExempInd.s2 > nExemplar/2
      thatPartExempInd.s2 = 1;
    end
    
    % get species and family number of the current comparison
    thisSpeciesNum = theseBtComps(i,1);
    thatSpeciesNum = theseBtComps(i,2);
    
    if thisSpeciesNum <= length(theseSpecies)
      thisFamilyNum = 1;
    else
      thisFamilyNum = 2;
      thisSpeciesNum = thisSpeciesNum - length(theseSpecies);
    end
    if thatSpeciesNum <= length(theseSpecies)
      thatFamilyNum = 1;
    else
      thatFamilyNum = 2;
      thatSpeciesNum = thatSpeciesNum - length(theseSpecies);
    end
    
    % find the first exemplar
    thisExemplar = betweenStims([betweenStims.familyNum] == thisFamilyNum & [betweenStims.speciesNum] == thisSpeciesNum & [betweenStims.exemplarNum] == thisFullExempInd(thisExempInd,thisSpeciesNum));
    
    % find the list of other species members that can be the pair
    thatSpecies = betweenStims([betweenStims.familyNum] == thatFamilyNum & [betweenStims.speciesNum] == thatSpeciesNum & [betweenStims.compStimNum] ~= thisExemplar.compStimNum);
    % find the other exemplar
    thatExemplar = thatSpecies(thatPartExempInd.(sprintf('s%d',thatSpecies(1).compStimNum)));
    
    % mark that these go together
    thisExemplar.compPairNum = i;
    thatExemplar.compPairNum = i;
    
    % add them to the full "between" list
    expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims,thisExemplar,thatExemplar);
    
    % increment index for next time
    thisExempInd = thisExempInd + 1;
    thatPartExempInd.(sprintf('s%d',thatSpecies(1).compStimNum)) = thatPartExempInd.(sprintf('s%d',thatSpecies(1).compStimNum)) + 1;
  end

  % within species comparisons
  fprintf('Shuffling %s compare within species (%d) prep stimuli.\n',sesName,phaseCount);
  [withinStims] = et_shuffleStims(withinStims,'familyNum',5);
  
  withinS1 = withinStims([withinStims.compStimNum] == 1);
  withinS2 = withinStims([withinStims.compStimNum] == 2);
  
  compCount = 1;
  for e = 1:length(withinS1)
    thisExemplar = withinS1(e);
    thisFamilyNum = thisExemplar.familyNum;
    thisSpeciesNum = thisExemplar.speciesNum;
    
    % find the indiices of eligible stim2 species to go along with stim1
    thisSpeciesS2ind = find([withinS2.familyNum] == thisFamilyNum & [withinS2.speciesNum] == thisSpeciesNum);
    
    % choose the first one
    thatExemplar = withinS2(thisSpeciesS2ind(1));
    % and remove it from the list
    withinS2 = withinS2([withinS2.familyNum] ~= thatExemplar.familyNum | [withinS2.speciesNum] ~= thatExemplar.speciesNum | [withinS2.exemplarNum] ~= thatExemplar.exemplarNum);
    % withinS2 = withinS2(~ismember({withinS2.fileName},thatExemplar.fileName));
    
    % mark that these go together
    thisExemplar.compPairNum = compCount;
    thatExemplar.compPairNum = compCount;
    
    % add them to the full "within" list
    expParam.session.(sesName).(phaseName)(phaseCount).wiSpeciesStims = cat(1,expParam.session.(sesName).(phaseName)(phaseCount).wiSpeciesStims,thisExemplar,thatExemplar);
    
    % increment the counter
    compCount = compCount + 1;
  end
end

% shuffle the viewing stimuli
fprintf('Shuffling %s compare viewing (%d) task stimuli.\n',sesName,phaseCount);
[expParam.session.(sesName).(phaseName)(phaseCount).viewStims] = et_shuffleStims(...
  expParam.session.(sesName).(phaseName)(phaseCount).viewStims,'familyNum',phaseCfg.viewMaxConsecFamily);

% % give the between stims a good shuffle
% fprintf('Shuffling %s compare between species (%d) task stimuli.\n',sesName,phaseCount);
% [expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims] = et_shuffleStims(...
%   expParam.session.(sesName).(phaseName)(phaseCount).btSpeciesStims,'familyNum',5);
% 
% % give the within stims a good shuffle
% fprintf('Shuffling %s compare within species (%d) task stimuli.\n',sesName,phaseCount);
% [expParam.session.(sesName).(phaseName)(phaseCount).wiSpeciesStims] = et_shuffleStims(...
%   expParam.session.(sesName).(phaseName)(phaseCount).wiSpeciesStims,'familyNum',5);
  
fprintf('Done.\n');

end % function
