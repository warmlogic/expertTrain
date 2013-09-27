function [cfg,expParam,imgStimStruct,wordStimStruct] = space_processStims_test(cfg,expParam,sesName,phaseName,phaseCount,imgStimStruct,wordStimStruct,studyPhaseName)
% function [cfg,expParam,imgStimStruct,wordStimStruct] = space_processStims_test(cfg,expParam,sesName,phaseName,phaseCount,imgStimStruct,wordStimStruct,studyPhaseName)

fprintf('Configuring %s %s (%d)...\n',sesName,phaseName,phaseCount);

phaseCfg = cfg.stim.(sesName).(phaseName)(phaseCount);

if ~isfield(phaseCfg,'categoryNames')
  if ~phaseCfg.isExp
    phaseCfg.categoryNames = cfg.stim.practice.categoryNames;
  else
    phaseCfg.categoryNames = cfg.stim.categoryNames;
  end
end

if ~isfield(cfg.stim,'testOnePres')
  cfg.stim.testOnePres = true;
end

if ~isfield(cfg.stim,'testInOrderedGroups')
  cfg.stim.testInOrderedGroups = 0;
end

if cfg.stim.testInOrderedGroups == 1
  warning('cfg.stim.testInOrderedGroups is set to 1. This does not make sense. Setting to 0.');
  cfg.stim.testInOrderedGroups = 0;
end

% initialize to hold the test stimuli
testStims_img = [];
testStims_word = [];
expParam.session.(sesName).(phaseName)(phaseCount).testStims_img = [];
expParam.session.(sesName).(phaseName)(phaseCount).testStims_word = [];

% collect the lure stimuli
if ~phaseCfg.isExp
  % for the practice
  
  % put all the practice image stimuli together, across categories
  for cn = 1:length(cfg.stim.practice.categoryNames)
    if ismember(cfg.stim.practice.categoryNames{cn},phaseCfg.categoryNames)
      [testStims_img,imgStimStruct(cn).catStims] = space_divvyStims(...
        imgStimStruct(cn).catStims,testStims_img,...
        cfg.stim.practice.nPairs_test_lure,...
        cfg.stim.practice.rmStims_init,cfg.stim.practice.shuffleFirst_init,{'practice','targ','spaced','lag','presNum','pairNum','pairOrd'},{true,false,[],[],[],[],[]});
    end
  end
  
  % do the word stimuli
  [testStims_word,wordStimStruct.wordStims] = space_divvyStims(...
    wordStimStruct.wordStims,testStims_word,...
    cfg.stim.practice.nPairs_test_lure * length(phaseCfg.categoryNames),...
    cfg.stim.practice.rmStims_init,cfg.stim.practice.shuffleFirst_init,{'practice','targ','spaced','lag','presNum','pairNum','pairOrd'},{true,false,[],[],[],[],[]});
else
  % for the real experiment
  
  % put all the image stimuli together, across categories
  for cn = 1:length(cfg.stim.categoryNames)
    if ismember(cfg.stim.categoryNames{cn},phaseCfg.categoryNames)
      [testStims_img,imgStimStruct(cn).catStims] = space_divvyStims(...
        imgStimStruct(cn).catStims,testStims_img,...
        cfg.stim.nPairs_test_lure,...
        cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice','targ','spaced','lag','presNum','pairNum','pairOrd'},{false,false,[],[],[],[],[]});
    end
  end
  
  % do the word stimuli
  [testStims_word,wordStimStruct.wordStims] = space_divvyStims(...
    wordStimStruct.wordStims,testStims_word,...
    cfg.stim.nPairs_test_lure * length(phaseCfg.categoryNames),...
    cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice','targ','spaced','lag','presNum','pairNum','pairOrd'},{false,false,[],[],[],[],[]});
end

% get the study stimuli
p1_StudyStims_img = expParam.session.(sesName).(studyPhaseName)(phaseCount).studyStims_img([expParam.session.(sesName).(studyPhaseName)(phaseCount).studyStims_img.presNum] == 1);
p1_StudyStims_word = expParam.session.(sesName).(studyPhaseName)(phaseCount).studyStims_word([expParam.session.(sesName).(studyPhaseName)(phaseCount).studyStims_word.presNum] == 1);

% if desired, do not keep the single presentation stimuli
if ~cfg.stim.testOnePres
  p1_StudyStims_img = p1_StudyStims_img([p1_StudyStims_img.lag] ~= -1);
  p1_StudyStims_word = p1_StudyStims_word([p1_StudyStims_word.lag] ~= -1);
end

% if desired, divide study stimuli into ordered groups
if cfg.stim.testInOrderedGroups > 1
  % targets
  targStimsPerGroup = floor(length(p1_StudyStims_img) / cfg.stim.testInOrderedGroups);
  targStimsInFinalGroup = mod(length(p1_StudyStims_img),cfg.stim.testInOrderedGroups);
  
  % lures
  lureStimsPerGroup = floor(length(testStims_img) / cfg.stim.testInOrderedGroups);
  lureStimsInFinalGroup = mod(length(testStims_img),cfg.stim.testInOrderedGroups);
  
  % shuffle the lures before we select from them
  fprintf('Shuffling %s test (%d) task stimuli.\n',sesName,phaseCount);
  [testStims_img,randind] = et_shuffleStims(...
    testStims_img,'categoryNum',phaseCfg.crMaxConsecCategory);
  % put the word stimuli in the same shuffled order
  testStims_word = testStims_word(randind);
  
%   % initialize to hold the final ordered target and lure groups
%   fn_img = fieldnames(p1_StudyStims_img);
%   fn_img_str = sprintf('''%s'',[]',fn_img{1});
%   fn_img_str = cat(2,fn_img_str,sprintf(repmat(',''%s'',[]',1,length(fn_img) - 1),fn_img{2:end}));
%   fn_word = fieldnames(p1_StudyStims_word);
%   fn_word_str = sprintf('''%s'',[]',fn_word{1});
%   fn_word_str = cat(2,fn_word_str,sprintf(repmat(',''%s'',[]',1,length(fn_word) - 1),fn_word{2:end}));
%   orderedGroups_img = eval(sprintf('struct(%s)',fn_img_str));
%   orderedGroups_word = eval(sprintf('struct(%s)',fn_word_str));
  
  %orderedGroups_img = struct;
  %orderedGroups_word = struct;
  %orderedLureGroups_img = struct;
  %orderedLureGroups_word = struct;
  
  for i = 1:(cfg.stim.testInOrderedGroups)
    % set the indices for this group
    targStartInd = (i * targStimsPerGroup) - targStimsPerGroup + 1;
    targEndInd = (i * targStimsPerGroup);
    lureStartInd = (i * lureStimsPerGroup) - lureStimsPerGroup + 1;
    lureEndInd = (i * lureStimsPerGroup);
    
    % put this group of targets and lures together
    thisOrderedGroup_img = cat(1,p1_StudyStims_img(targStartInd:targEndInd)',testStims_img(lureStartInd:lureEndInd));
    thisOrderedGroup_word = cat(1,p1_StudyStims_word(targStartInd:targEndInd)',testStims_word(lureStartInd:lureEndInd));
    
    % shuffle this group of targets and lures together
    fprintf('Shuffling %s test (%d) task stimuli.\n',sesName,phaseCount);
    [thisOrderedGroup_img,randind] = et_shuffleStims(...
      thisOrderedGroup_img,'categoryNum',phaseCfg.crMaxConsecCategory);
    % put the word stimuli in the same shuffled order
    thisOrderedGroup_word = thisOrderedGroup_word(randind);
    
    % concatenate targets and lures from this group, initialize if needed
    if ~exist('orderedGroups_img','var')
      orderedGroups_img = thisOrderedGroup_img;
    else
      orderedGroups_img = cat(1,orderedGroups_img,thisOrderedGroup_img);
    end
    if ~exist('orderedGroups_word','var')
      orderedGroups_word = thisOrderedGroup_word;
    else
      orderedGroups_word = cat(1,orderedGroups_word,thisOrderedGroup_word);
    end
    
    %orderedLureGroups_img = cat(1,orderedLureGroups_img,testStims_img(lureStartInd:lureEndInd));
    %orderedLureGroups_word = cat(1,orderedLureGroups_word,testStims_word(lureStartInd:lureEndInd));
  end
  
  % do the final group if there were remainders
  if targStimsInFinalGroup ~= 0
    finalTargGroup_img = p1_StudyStims_img(targEndInd + 1:end);
    finalTargGroup_word = p1_StudyStims_word(targEndInd + 1:end);
  else
    finalTargGroup_img = [];
    finalTargGroup_word = [];
  end
  
  if lureStimsInFinalGroup ~= 0
    finalLureGroup_img = testStims_img(lureEndInd + 1:end);
    finalLureGroup_word = testStims_word(lureEndInd + 1:end);
  else
    finalLureGroup_img = [];
    finalLureGroup_word = [];
  end
  
  if targStimsInFinalGroup ~= 0 || lureStimsInFinalGroup ~= 0
    finalGroup_img = cat(1,finalTargGroup_img',finalLureGroup_img);
    finalGroup_word = cat(1,finalTargGroup_word',finalLureGroup_word);
    
    [finalGroup_img,randind] = et_shuffleStims(finalGroup_img);
    finalGroup_word = finalGroup_word(randind);
    
    orderedGroups_img = cat(1,orderedGroups_img,finalGroup_img);
    orderedGroups_word = cat(1,orderedGroups_word,finalGroup_word);
  end
  
  % set these as the stimuli to test
  testStims_img = orderedGroups_img;
  testStims_word = orderedGroups_word;
  
else
  % combine the study and test stimuli and shuffle again
  testStims_img = cat(1,p1_StudyStims_img',testStims_img);
  testStims_word = cat(1,p1_StudyStims_word',testStims_word);
  
  % Reshuffle images for the experiment. No more than X conecutive stimuli
  % from the same category
  fprintf('Shuffling %s test (%d) task stimuli.\n',sesName,phaseCount);
  [testStims_img,randind] = et_shuffleStims(...
    testStims_img,'categoryNum',phaseCfg.crMaxConsecCategory);
  %expParam.session.(sesName).(phaseName)(phaseCount).testStims_img,'targ',phaseCfg.crMaxConsecTarg);
  
  % put the word stimuli in the same shuffled order
  testStims_word = testStims_word(randind);
end

% give them pair numbers
%for i = 1:((cfg.stim.nPairs_study_targ_spaced + cfg.stim.nPairs_study_targ_massed + cfg.stim.nPairs_study_targ_onePres + cfg.stim.nPairs_test_lure) * length(phaseCfg.categoryNames))
for i = 1:length(testStims_img)
  testStims_img(i).pairNum = i;
  testStims_word(i).pairNum = i;
end

expParam.session.(sesName).(phaseName)(phaseCount).testStims_img = testStims_img;
expParam.session.(sesName).(phaseName)(phaseCount).testStims_word = testStims_word;

fprintf('Done.\n');

end % function
