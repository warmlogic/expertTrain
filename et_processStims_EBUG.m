function [expParam] = et_processStims_EBUG(cfg,expParam)
% function [expParam] = et_processStims_EBUG(cfg,expParam)
%
% Description:
%  Prepares the stimuli, mostly in experiment presentation order. This
%  function is run by config_EBUG.
%
% see also: config_EBUG, et_divvyStims, et_divvyStims_match,
% et_shuffleStims, et_shuffleStims_match, et_processStims_match,
% et_processStims_recog, et_processStims_viewname,
% et_processStims_nametrain, et_processStims_name

%% Initial processing of the stimuli

% read in the stimulus list
fprintf('Loading stimulus list: %s...',cfg.stim.file);
fid = fopen(cfg.stim.file);
% the header line becomes the fieldnames
stim_fieldnames = regexp(fgetl(fid),'\t','split');
stimuli = textscan(fid,'%s%s%d%s%d%d%d%d','Delimiter','\t');
fclose(fid);
fprintf('Done.\n');

% create a structure for each family with all the stim information

% familyNum is field 3
familyNumFieldNum = 3;
% speciesNum is field 5
speciesNumFieldNum = 5;

% find the indices for each family and select only cfg.stim.nSpecies
fprintf('Selecting %d of %d possible species for each family.\n',cfg.stim.nSpecies,length(unique(stimuli{speciesNumFieldNum})));

% initialize to store the stimuli
stimStruct = struct();

% get the indices of each family and only the number of species wanted
for f = 1:length(cfg.stim.familyNames)
  fInd = eval([sprintf('stimuli{%d} == %d & (stimuli{%d} == %d',familyNumFieldNum,f,speciesNumFieldNum,1),...
    sprintf(repmat([' | ',sprintf('stimuli{%d}',speciesNumFieldNum),' == %d'],1,(cfg.stim.nSpecies - 1)),2:cfg.stim.nSpecies), ')']);
  stimStruct(f).fStims = struct(...
    stim_fieldnames{1},stimuli{1}(fInd),...
    stim_fieldnames{2},stimuli{2}(fInd),...
    stim_fieldnames{3},num2cell(stimuli{3}(fInd)),...
    stim_fieldnames{4},stimuli{4}(fInd),...
    stim_fieldnames{5},num2cell(stimuli{5}(fInd)),...
    stim_fieldnames{6},num2cell(stimuli{6}(fInd)),...
    stim_fieldnames{7},num2cell(stimuli{7}(fInd)),...
    stim_fieldnames{8},num2cell(stimuli{8}(fInd)));
end

%% Decide which will be the trained and untrained stimuli from each family

for f = 1:length(cfg.stim.familyNames)
  % trained
  expParam.session.(sprintf('f%dTrained',f)) = [];
  [expParam.session.(sprintf('f%dTrained',f)),stimStruct(f).fStims] = et_divvyStims(...
    stimStruct(f).fStims,[],cfg.stim.nTrained,...
    cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'trained'},{1});
  
  % untrained
  expParam.session.(sprintf('f%dUntrained',f)) = [];
  [expParam.session.(sprintf('f%dUntrained',f)),stimStruct(f).fStims] = et_divvyStims(...
    stimStruct(f).fStims,[],cfg.stim.nUntrained,...
    cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'trained'},{0});
end

%% Configure each session and phase

for s = 1:expParam.nSessions
  
  sesName = expParam.sesTypes{s};
  
  % counting the phases, in case any sessions have the same phase type
  % multiple times
  viewnameCount = 0;
  nametrainCount = 0;
  nameCount = 0;
  matchCount = 0;
  recogCount = 0;
  prac_recogCount = 0;
  
  % for each phase in this session, run the appropriate config function
  for p = 1:length(expParam.session.(sesName).phases)
    
    phaseName = expParam.session.(sesName).phases{p};
    
    switch phaseName
      
      case {'practice'}
        % TODO: not sure what they'll do for practice
        warning('Not sure what to do for practice\n');
        
      case {'viewname'}
        viewnameCount = viewnameCount + 1;
        
        [cfg,expParam] = et_processStims_viewname(cfg,expParam,sesName,phaseName,viewnameCount);
        
      case {'nametrain'}
        nametrainCount = nametrainCount + 1;
        
        [cfg,expParam] = et_processStims_nametrain(cfg,expParam,sesName,phaseName,nametrainCount);
        
      case {'name'}
        nameCount = nameCount + 1;
        
        [cfg,expParam] = et_processStims_name(cfg,expParam,sesName,phaseName,nameCount);
        
      case {'match'}
        matchCount = matchCount + 1;
        
        [cfg,expParam] = et_processStims_match(cfg,expParam,sesName,phaseName,matchCount);
        
      case {'recog'}
        recogCount = recogCount + 1;
        
        [cfg,expParam,stimStruct.fStims] = et_processStims_recog(cfg,expParam,sesName,phaseName,recogCount,stimStruct.fStims);
        
      case {'prac_recog'}
        prac_recogCount = prac_recogCount + 1;
        
        [cfg,expParam,stimStruct.fStims] = et_processStims_recog(cfg,expParam,sesName,phaseName,prac_recogCount,stimStruct.fStims);
        
    end % switch
  end % for p
end % for s

end % function
