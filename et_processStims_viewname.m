function [cfg,expParam] = et_processStims_viewname(cfg,expParam,sesName,phaseName,phaseCount)
% function [cfg,expParam] = et_processStims_viewname(cfg,expParam,sesName,phaseName,phaseCount)

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

% get the stimuli from both families for selection (will shuffle later)
f1Trained = expParam.session.f1Trained;
f2Trained = expParam.session.f2Trained;

% add the species in order from 1 to nSpecies; this is ok because, for each
% subject, each species number corresonds to a random species letter
speciesOrder_f1 = (1:cfg.stim.nSpecies);
speciesOrder_f2 = (1:cfg.stim.nSpecies);
% % randomize the order in which species are added; order is different
% % for each family
% speciesOrder_f1 = randperm(cfg.stim.nSpecies);
% speciesOrder_f2 = randperm(cfg.stim.nSpecies);

% initialize viewing and naming cells, one for each block
expParam.session.(sesName).(phaseName)(phaseCount).viewStims = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));
expParam.session.(sesName).(phaseName)(phaseCount).nameStims = cell(1,length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder));

for b = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder)
  for s = 1:length(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{b})
    % family 1
    
    sInd_f1 = find([f1Trained.speciesNum] == speciesOrder_f1(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{b}(s)));
    % shuffle the stimulus index
    randind_f1 = randperm(length(sInd_f1));
    
    % shuffle the exemplars
    thisSpecies_f1 = f1Trained(sInd_f1(randind_f1));
    
    % add them to the viewing list
    expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b} = cat(1,...
      expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b},...
      thisSpecies_f1(cfg.stim.(sesName).(phaseName)(phaseCount).viewIndices{b}{s}));
    
    % add them to the naming list
    expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b} = cat(1,...
      expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b},...
      thisSpecies_f1(cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices{b}{s}));
    
    % family 2
    
    sInd_f2 = find([f1Trained.speciesNum] == speciesOrder_f2(cfg.stim.(sesName).(phaseName)(phaseCount).blockSpeciesOrder{b}(s)));
    % shuffle the stimulus index
    randind_f2 = randperm(length(sInd_f2));
    
    % shuffle the exemplars
    thisSpecies_f2 = f2Trained(sInd_f2(randind_f2));
    
    % add them to the viewing list
    expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b} = cat(1,...
      expParam.session.(sesName).(phaseName)(phaseCount).viewStims{b},...
      thisSpecies_f2(cfg.stim.(sesName).(phaseName)(phaseCount).viewIndices{b}{s}));
    
    % add them to the naming list
    expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b} = cat(1,...
      expParam.session.(sesName).(phaseName)(phaseCount).nameStims{b},...
      thisSpecies_f2(cfg.stim.(sesName).(phaseName)(phaseCount).nameIndices{b}{s}));
  end
  
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
