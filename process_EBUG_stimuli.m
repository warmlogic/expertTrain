function [expParam] = process_EBUG_stimuli(cfg,expParam)
% function [expParam] = process_EBUG_stimuli(cfg,expParam)
%
% Description:
%  Prepares the stimuli, mostly in experiment presentation order. This
%  function is run by config_EBUG.
%
% see also: config_EBUG, et_divvyStims, et_divvyStims_match,
% et_shuffleStims, et_shuffleStims_match

%% Initial processing of the stimuli

% read in the stimulus list
fprintf('Loading stimulus list: %s...',cfg.stim.file);
fid = fopen(cfg.stim.file);
stim_fieldnames = regexp(fgetl(fid),'\t','split');
stimuli = textscan(fid,'%s%s%d%s%d%d%d%d','Delimiter','\t');
% % old method
% stimuli = textscan(fid,'%s%s%d%s%d%d%d%d','Delimiter','\t','Headerlines',1);
fclose(fid);
fprintf('Done.\n');

% create a structure for each family with all the stim information
f1Ind = stimuli{3} == 1;
f1Stim = struct(...
  stim_fieldnames{1},stimuli{1}(f1Ind),...
  stim_fieldnames{2},stimuli{2}(f1Ind),...
  stim_fieldnames{3},num2cell(stimuli{3}(f1Ind)),...
  stim_fieldnames{4},stimuli{4}(f1Ind),...
  stim_fieldnames{5},num2cell(stimuli{5}(f1Ind)),...
  stim_fieldnames{6},num2cell(stimuli{6}(f1Ind)),...
  stim_fieldnames{7},num2cell(stimuli{7}(f1Ind)),...
  stim_fieldnames{8},num2cell(stimuli{8}(f1Ind)));

f2Ind = stimuli{3} == 2;
f2Stim = struct(...
  stim_fieldnames{1},stimuli{1}(f2Ind),...
  stim_fieldnames{2},stimuli{2}(f2Ind),...
  stim_fieldnames{3},num2cell(stimuli{3}(f2Ind)),...
  stim_fieldnames{4},stimuli{4}(f2Ind),...
  stim_fieldnames{5},num2cell(stimuli{5}(f2Ind)),...
  stim_fieldnames{6},num2cell(stimuli{6}(f2Ind)),...
  stim_fieldnames{7},num2cell(stimuli{7}(f2Ind)),...
  stim_fieldnames{8},num2cell(stimuli{8}(f2Ind)));

% % old method
% f1Stim = struct(...
%   'filename',stimuli{1}(f1Ind),...
%   'familyStr',stimuli{2}(f1Ind),...
%   'familyNum',num2cell(stimuli{3}(f1Ind)),...
%   'speciesStr',stimuli{4}(f1Ind),...
%   'speciesNum',num2cell(stimuli{5}(f1Ind)),...
%   'exemplarName',num2cell(stimuli{6}(f1Ind)),...
%   'exemplarNum',num2cell(stimuli{7}(f1Ind)),...
%   'number',num2cell(stimuli{8}(f1Ind)));
%
% f2Stim = struct(...
%   'filename',stimuli{1}(f2Ind),...
%   'familyStr',stimuli{2}(f2Ind),...
%   'familyNum',num2cell(stimuli{3}(f2Ind)),...
%   'speciesStr',stimuli{4}(f2Ind),...
%   'speciesNum',num2cell(stimuli{5}(f2Ind)),...
%   'exemplarName',num2cell(stimuli{6}(f2Ind)),...
%   'exemplarNum',num2cell(stimuli{7}(f2Ind)),...
%   'number',num2cell(stimuli{8}(f2Ind)));

%% Decide which will be the trained and untrained stimuli from each family

rmStims = true;
shuffleFirst = true;

% family 1 trained
expParam.session.f1Trained = [];
[f1Stim,expParam.session.f1Trained] = et_divvyStims(...
  f1Stim,[],cfg.stim.nTrained,rmStims,shuffleFirst,{'trained'},{1});

% family 1 untrained
expParam.session.f1Untrained = [];
[f1Stim,expParam.session.f1Untrained] = et_divvyStims(...
  f1Stim,[],cfg.stim.nUntrained,rmStims,shuffleFirst,{'trained'},{0});

% family 2 trained
expParam.session.f2Trained = [];
[f2Stim,expParam.session.f2Trained] = et_divvyStims(...
  f2Stim,[],cfg.stim.nTrained,rmStims,shuffleFirst,{'trained'},{1});

% family 2 untrained
expParam.session.f2Untrained = [];
[f2Stim,expParam.session.f2Untrained] = et_divvyStims(...
  f2Stim,[],cfg.stim.nUntrained,rmStims,shuffleFirst,{'trained'},{0});

%% Pretest

sesName = 'pretest';
fprintf('Configuring %s...\n',sesName);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

% TODO: don't need to store expParam.session.(sesName).match.same and
% expParam.session.(sesName).match.diff because allStims gets created and
% is all we need. Instead, replace them with sameStims and diffStims.

% rmStims_orig is false because we're using all stimuli in both conds
rmStims_orig = false;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match.same = [];
expParam.session.(sesName).match.diff = [];

% family 1 trained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching task stimuli.\n',sesName);
[expParam.session.(sesName).match.allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match.same,...
  expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.stim2MinRepeatSpacing);

%%%%%%%%%%%%%%%%%%%%%%
% Recognition task
%%%%%%%%%%%%%%%%%%%%%%

rmStims = true;
shuffleFirst = true;

% initialize for storing both families together
expParam.session.(sesName).recog.targStims = cell(1,cfg.stim.(sesName).recog.nBlocks);
expParam.session.(sesName).recog.lureStims = cell(1,cfg.stim.(sesName).recog.nBlocks);
expParam.session.(sesName).recog.allStims = cell(1,cfg.stim.(sesName).recog.nBlocks);

for b = 1:cfg.stim.(sesName).recog.nBlocks
  % family 1
  
  % targets
  [f1Stim,expParam.session.(sesName).recog.targStims{b}] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % lures
  [f1Stim,expParam.session.(sesName).recog.lureStims{b}] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  % family 2
  
  % add targets to the existing list
  [f2Stim,expParam.session.(sesName).recog.targStims{b}] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.targStims{b},cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % add lures to the existing list
  [f2Stim,expParam.session.(sesName).recog.lureStims{b}] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.lureStims{b},cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  % shuffle the study stims so no more than X of the same family appear in
  % a row, if desired
  fprintf('Shuffling %s recognition study task stimuli.\n',sesName);
  [expParam.session.(sesName).recog.targStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).recog.targStims{b},'familyNum',cfg.stim.(sesName).recog.studyMaxConsecFamily);
  
  % put the test stims together
  expParam.session.(sesName).recog.allStims{b} = cat(1,expParam.session.(sesName).recog.targStims{b},expParam.session.(sesName).recog.lureStims{b});
  % shuffle so there are no more than X targets or lures in a row
  fprintf('Shuffling %s recognition test task stimuli.\n',sesName);
  [expParam.session.(sesName).recog.allStims{b}] = et_shuffleStims(expParam.session.(sesName).recog.allStims{b},'targ',cfg.stim.(sesName).recog.testMaxConsec);
end

%% Training Day 1

sesName = 'train1';
fprintf('Configuring %s...\n',sesName);

%%%%%%%%%%%%%%%%%%%%%%
% Viewing+Naming task
%%%%%%%%%%%%%%%%%%%%%%

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
expParam.session.(sesName).viewname.viewStims = cell(1,length(cfg.stim.(sesName).viewname.blockSpeciesOrder));
expParam.session.(sesName).viewname.nameStims = cell(1,length(cfg.stim.(sesName).viewname.blockSpeciesOrder));

for b = 1:length(cfg.stim.(sesName).viewname.blockSpeciesOrder)
  for s = 1:length(cfg.stim.(sesName).viewname.blockSpeciesOrder{b})
    % family 1
    
    sInd_f1 = find([f1Trained.speciesNum] == speciesOrder_f1(cfg.stim.(sesName).viewname.blockSpeciesOrder{b}(s)));
    % shuffle the stimulus index
    randind_f1 = randperm(length(sInd_f1));
    % % debug
    % randind_f1 = 1:length(sInd_f1);
    % fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
    
    % shuffle the exemplars
    thisSpecies_f1 = f1Trained(sInd_f1(randind_f1));
    
    % add them to the viewing list
    %fprintf('view f1: block %d, species %d, exemplar %d\n',b,cfg.stim.(sesName).viewname.blockSpeciesOrder{b}(s),cfg.stim.(sesName).viewname.viewIndices{b}(s));
    expParam.session.(sesName).viewname.viewStims{b} = cat(1,...
      expParam.session.(sesName).viewname.viewStims{b},...
      thisSpecies_f1(cfg.stim.(sesName).viewname.viewIndices{b}(s)));
    
    % add them to the naming list
    %fprintf('\tname f1: block %d, species %d, exemplar%s\n',b,cfg.stim.(sesName).viewname.blockSpeciesOrder{b}(s),...
    %  sprintf(repmat(' %d',1,length(cfg.stim.(sesName).viewname.nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName))))...
    %  ,cfg.stim.(sesName).viewname.nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName))));
    expParam.session.(sesName).viewname.nameStims{b} = cat(1,...
      expParam.session.(sesName).viewname.nameStims{b},...
      thisSpecies_f1(cfg.stim.(sesName).viewname.nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName))));
    
    % family 2
    
    sInd_f2 = find([f1Trained.speciesNum] == speciesOrder_f2(cfg.stim.(sesName).viewname.blockSpeciesOrder{b}(s)));
    % shuffle the stimulus index
    randind_f2 = randperm(length(sInd_f2));
    % % debug
    % randind_f2 = 1:length(sInd_f2);
    % fprintf('%s, NB: Debug code. Not actually randomizing!\n',mfilename);
    
    % shuffle the exemplars
    thisSpecies_f2 = f2Trained(sInd_f2(randind_f2));
    
    % add them to the viewing list
    %fprintf('view f2: block %d, species %d, exemplar %d\n',b,cfg.stim.(sesName).viewname.blockSpeciesOrder{b}(s),cfg.stim.(sesName).viewname.viewIndices{b}(s));
    % NB: not actually using cfg.stim.(sesName).viewname.exemplarPerView.
    % This needs to be modified if there's more than 1 exemplar per
    % view from a species. Currently "hardcoded" because number of
    % exemplars = cfg.stim.(sesName).viewname.viewIndices{b}(s).
    expParam.session.(sesName).viewname.viewStims{b} = cat(1,...
      expParam.session.(sesName).viewname.viewStims{b},...
      thisSpecies_f2(cfg.stim.(sesName).viewname.viewIndices{b}(s)));
    
    % add them to the naming list
    %fprintf('\tname f2: block %d, species %d, exemplar%s\n',b,cfg.stim.(sesName).viewname.blockSpeciesOrder{b}(s),...
    %  sprintf(repmat(' %d',1,length(cfg.stim.(sesName).viewname.nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName)))),...
    %  cfg.stim.(sesName).viewname.nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName))));
    expParam.session.(sesName).viewname.nameStims{b} = cat(1,...
      expParam.session.(sesName).viewname.nameStims{b},...
      thisSpecies_f2(cfg.stim.(sesName).viewname.nameIndices{b}(((s*cfg.stim.(sesName).viewname.exemplarPerName)-1):(s*cfg.stim.(sesName).viewname.exemplarPerName))));
  end
  
  % if there are more than X consecutive exemplars from the same
  % family, reshuffle for the experiment. There's probably a better way
  % to do this but it works.
  
  % viewing
  fprintf('Shuffling %s viewing task stimuli.\n',sesName);
  [expParam.session.(sesName).viewname.viewStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).viewname.viewStims{b},'familyNum',cfg.stim.(sesName).viewname.viewMaxConsecFamily);
  % naming
  fprintf('Shuffling %s naming task stimuli.\n',sesName);
  [expParam.session.(sesName).viewname.nameStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).viewname.nameStims{b},'familyNum',cfg.stim.(sesName).viewname.nameMaxConsecFamily);
  
end % for each block

%%%%%%%%%%%%%%%%%%%%%%
% Naming task (all stimuli)
%%%%%%%%%%%%%%%%%%%%%%

% put all the trained stimuli together
expParam.session.(sesName).name.nameStims = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming task stimuli.\n',sesName);
[expParam.session.(sesName).name.nameStims] = et_shuffleStims(...
  expParam.session.(sesName).name.nameStims,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match.same = [];
expParam.session.(sesName).match.diff = [];

% family 1 trained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching task stimuli.\n',sesName);
[expParam.session.(sesName).match.allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match.same,...
  expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.stim2MinRepeatSpacing);

%% Training Day 2

sesName = 'train2';
fprintf('Configuring %s...\n',sesName);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 1;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%%%%%%%%%%%%%%%%%%%%%%
% Naming task (all stimuli)
%%%%%%%%%%%%%%%%%%%%%%

% put all the trained stimuli together
expParam.session.(sesName).name.nameStims = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming task stimuli.\n',sesName);
[expParam.session.(sesName).name.nameStims] = et_shuffleStims(...
  expParam.session.(sesName).name.nameStims,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 2;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%% Training Day 3

sesName = 'train3';
fprintf('Configuring %s...\n',sesName);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 1;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%%%%%%%%%%%%%%%%%%%%%%
% Naming task (all stimuli)
%%%%%%%%%%%%%%%%%%%%%%

% put all the trained stimuli together
expParam.session.(sesName).name.nameStims = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming task stimuli.\n',sesName);
[expParam.session.(sesName).name.nameStims] = et_shuffleStims(...
  expParam.session.(sesName).name.nameStims,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 2;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%% Training Day 4

sesName = 'train4';
fprintf('Configuring %s...\n',sesName);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 1;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%%%%%%%%%%%%%%%%%%%%%%
% Naming task (all stimuli)
%%%%%%%%%%%%%%%%%%%%%%

% put all the trained stimuli together
expParam.session.(sesName).name.nameStims = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming task stimuli.\n',sesName);
[expParam.session.(sesName).name.nameStims] = et_shuffleStims(...
  expParam.session.(sesName).name.nameStims,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 2;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%% Training Day 5

sesName = 'train5';
fprintf('Configuring %s...\n',sesName);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 1;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%%%%%%%%%%%%%%%%%%%%%%
% Naming task (all stimuli)
%%%%%%%%%%%%%%%%%%%%%%

% put all the trained stimuli together
expParam.session.(sesName).name.nameStims = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming task stimuli.\n',sesName);
[expParam.session.(sesName).name.nameStims] = et_shuffleStims(...
  expParam.session.(sesName).name.nameStims,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 2;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%% Training Day 6

sesName = 'train6';
fprintf('Configuring %s...\n',sesName);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 1;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%%%%%%%%%%%%%%%%%%%%%%
% Naming task (all stimuli)
%%%%%%%%%%%%%%%%%%%%%%

% put all the trained stimuli together
expParam.session.(sesName).name.nameStims = cat(1,expParam.session.f1Trained,expParam.session.f2Trained);
% Reshuffle for the experiment. No more than X conecutive exemplars from
% the same family.
fprintf('Shuffling %s naming task stimuli.\n',sesName);
[expParam.session.(sesName).name.nameStims] = et_shuffleStims(...
  expParam.session.(sesName).name.nameStims,'familyNum',cfg.stim.(sesName).name.nameMaxConsecFamily);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

matchNum = 2;
% rmStims_orig is true because we're using half of stimuli in each cond
rmStims_orig = true;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match(matchNum).same = [];
expParam.session.(sesName).match(matchNum).diff = [];

% family 1 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match(matchNum).same,expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).nSame,cfg.stim.(sesName).match(matchNum).nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching (%d) task stimuli.\n',sesName,matchNum);
[expParam.session.(sesName).match(matchNum).allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match(matchNum).same,...
  expParam.session.(sesName).match(matchNum).diff,...
  cfg.stim.(sesName).match(matchNum).stim2MinRepeatSpacing);

%% Posttest

sesName = 'posttest';
fprintf('Configuring %s...\n',sesName);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

% rmStims_orig is false because we're using all stimuli in both conds
rmStims_orig = false;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match.same = [];
expParam.session.(sesName).match.diff = [];

% family 1 trained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching task stimuli.\n',sesName);
[expParam.session.(sesName).match.allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match.same,...
  expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.stim2MinRepeatSpacing);

%%%%%%%%%%%%%%%%%%%%%%
% Recognition task
%%%%%%%%%%%%%%%%%%%%%%

rmStims = true;
shuffleFirst = true;

% initialize for storing both families together
expParam.session.(sesName).recog.targStims = cell(1,cfg.stim.(sesName).recog.nBlocks);
expParam.session.(sesName).recog.lureStims = cell(1,cfg.stim.(sesName).recog.nBlocks);
expParam.session.(sesName).recog.allStims = cell(1,cfg.stim.(sesName).recog.nBlocks);

for b = 1:cfg.stim.(sesName).recog.nBlocks
  % family 1
  
  % targets
  [f1Stim,expParam.session.(sesName).recog.targStims{b}] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % lures
  [f1Stim,expParam.session.(sesName).recog.lureStims{b}] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  % family 2
  
  % add targets to the existing list
  [f2Stim,expParam.session.(sesName).recog.targStims{b}] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.targStims{b},cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % add lures to the existing list
  [f2Stim,expParam.session.(sesName).recog.lureStims{b}] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.lureStims{b},cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  % shuffle the study stims so no more than X of the same family appear in
  % a row
  fprintf('Shuffling %s recognition study task stimuli.\n',sesName);
  [expParam.session.(sesName).recog.targStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).recog.targStims{b},'familyNum',cfg.stim.(sesName).recog.studyMaxConsecFamily);
  
  % put the test stims together
  expParam.session.(sesName).recog.allStims{b} = cat(1,expParam.session.(sesName).recog.targStims{b},expParam.session.(sesName).recog.lureStims{b});
  % shuffle so there are no more than X targets or lures in a row
  fprintf('Shuffling %s recognition test task stimuli.\n',sesName);
  [expParam.session.(sesName).recog.allStims{b}] = et_shuffleStims(expParam.session.(sesName).recog.allStims{b},'targ',cfg.stim.(sesName).recog.testMaxConsec);
end

%% Posttest Delayed

sesName = 'posttest_delay';
fprintf('Configuring %s...\n',sesName);

%%%%%%%%%%%%%%%%%%%%%%
% Matching task
%%%%%%%%%%%%%%%%%%%%%%

% rmStims_orig is false because we're using all stimuli in both conds
rmStims_orig = false;
rmStims_pair = true;
shuffleFirst = true;

% initialize to hold all the same and different stimuli
expParam.session.(sesName).match.same = [];
expParam.session.(sesName).match.diff = [];

% family 1 trained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f1Trained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 1 untrained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f1Untrained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 trained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f2Trained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% family 2 untrained
[expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff] = et_divvyStims_match(...
  expParam.session.f2Untrained,...
  expParam.session.(sesName).match.same,expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.nSame,cfg.stim.(sesName).match.nDiff,rmStims_orig,rmStims_pair,shuffleFirst);

% shuffle same and diff together for the experiment
fprintf('Shuffling %s matching task stimuli.\n',sesName);
[expParam.session.(sesName).match.allStims] = et_shuffleStims_match(...
  expParam.session.(sesName).match.same,...
  expParam.session.(sesName).match.diff,...
  cfg.stim.(sesName).match.stim2MinRepeatSpacing);

%%%%%%%%%%%%%%%%%%%%%%
% Recognition task
%%%%%%%%%%%%%%%%%%%%%%

rmStims = true;
shuffleFirst = true;

% initialize for storing both families together
expParam.session.(sesName).recog.targStims = cell(1,cfg.stim.(sesName).recog.nBlocks);
expParam.session.(sesName).recog.lureStims = cell(1,cfg.stim.(sesName).recog.nBlocks);
expParam.session.(sesName).recog.allStims = cell(1,cfg.stim.(sesName).recog.nBlocks);

for b = 1:cfg.stim.(sesName).recog.nBlocks
  % family 1
  
  % targets
  [f1Stim,expParam.session.(sesName).recog.targStims{b}] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % lures
  [f1Stim,expParam.session.(sesName).recog.lureStims{b}] = et_divvyStims(...
    f1Stim,[],cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  % family 2
  
  % add targets to the existing list
  [f2Stim,expParam.session.(sesName).recog.targStims{b}] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.targStims{b},cfg.stim.(sesName).recog.nStudyTarg,rmStims,shuffleFirst,{'targ'},{1});
  % add lures to the existing list
  [f2Stim,expParam.session.(sesName).recog.lureStims{b}] = et_divvyStims(...
    f2Stim,expParam.session.(sesName).recog.lureStims{b},cfg.stim.(sesName).recog.nTestLure,rmStims,shuffleFirst,{'targ'},{0});
  
  % shuffle the study stims so no more than X of the same family appear in
  % a row
  fprintf('Shuffling %s recognition study task stimuli.\n',sesName);
  [expParam.session.(sesName).recog.targStims{b}] = et_shuffleStims(...
    expParam.session.(sesName).recog.targStims{b},'familyNum',cfg.stim.(sesName).recog.studyMaxConsecFamily);
  
  % put the test stims together
  expParam.session.(sesName).recog.allStims{b} = cat(1,expParam.session.(sesName).recog.targStims{b},expParam.session.(sesName).recog.lureStims{b});
  % shuffle so there are no more than X targets or lures in a row
  fprintf('Shuffling %s recognition test task stimuli.\n',sesName);
  [expParam.session.(sesName).recog.allStims{b}] = et_shuffleStims(expParam.session.(sesName).recog.allStims{b},'targ',cfg.stim.(sesName).recog.testMaxConsec);
end

