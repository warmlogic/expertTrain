function [cfg,expParam] = et_processStims_viewname(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_viewname(cfg,expParam,sesName,phaseName,phaseCount)

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

% add the species in order from 1 to nSpecies; this is ok because, for each
% subject, each species number corresonds to a random species letter, as
% determined in et_saveStimList()
speciesOrder = nan(length(cfg.stim.familyNames),cfg.stim.nSpecies);
for f = 1:length(cfg.stim.familyNames)
  speciesOrder(f,:) = (1:cfg.stim.nSpecies);
end

% initialize viewing and naming cells, one for each block
expParam.session.(sesName).(phaseName)(phaseCount).viewStims = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
expParam.session.(sesName).(phaseName)(phaseCount).nameStims = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));

for b = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder)
  for s = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{b})
    for f = 1:length(cfg.stim.familyNames)
      % get the indices for this species
      sInd = find([expParam.session.(sprintf('f%dTrained',f)).speciesNum] == speciesOrder(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{b}(s)));
      % shuffle the stimulus index
      randind = randperm(length(sInd));
      
      % shuffle the exemplars
      thisSpecies = expParam.session.(sprintf('f%dTrained',f))(sInd(randind));
      
      % add them to the viewing list
      expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b} = cat(1,...
        expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b},...
        thisSpecies(cfg.stim.(sesName).(phaseName)(phaseCount).viewIndices{b}{s}));
    
      % add them to the naming list
      expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b} = cat(1,...
        expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b},...
        thisSpecies(cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices{b}{s}));
    end % for each family
  end % for each species
  
  % if there are more than X consecutive exemplars from the same
  % family, reshuffle for the experiment. There's probably a better way
  % to do this but it works.
  
  % viewing
  fprintf('Shuffling %s viewing (%d) task stimuli.\n',sesName,phaseCount);
  [expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b},'familyNum',cfg.stim.(sesName).(phaseName)(phaseCount).viewMaxConsecFamily);
  % naming
  fprintf('Shuffling %s naming (%d) task stimuli.\n',sesName,phaseCount);
  [expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b},'familyNum',cfg.stim.(sesName).(phaseName)(phaseCount).nameMaxConsecFamily);
  
end % for each block

fprintf('Done.\n');

end % function
