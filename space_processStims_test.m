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

% initialize to hold the test stimuli
expParam.session.(sesName).(phaseName)(phaseCount).testStims_img = [];
expParam.session.(sesName).(phaseName)(phaseCount).testStims_word = [];

% collect the lure stimuli
if ~phaseCfg.isExp
  % for the practice
  
  % put all the practice image stimuli together, across categories
  for cn = 1:length(cfg.stim.practice.categoryNames)
    if ismember(cfg.stim.practice.categoryNames{cn},phaseCfg.categoryNames)
      [expParam.session.(sesName).(phaseName)(phaseCount).testStims_img,imgStimStruct(cn).catStims] = space_divvyStims(...
        imgStimStruct(cn).catStims,expParam.session.(sesName).(phaseName)(phaseCount).testStims_img,...
        cfg.stim.practice.nPairs_test_lure,...
        cfg.stim.practice.rmStims_init,cfg.stim.practice.shuffleFirst_init,{'practice','targ','spaced','lag','presNum','pairNum','pairOrd'},{true,false,[],[],[],[],[]});
    end
  end
  
  % do the word stimuli
  [expParam.session.(sesName).(phaseName)(phaseCount).testStims_word,wordStimStruct.wordStims] = space_divvyStims(...
    wordStimStruct.wordStims,expParam.session.(sesName).(phaseName)(phaseCount).testStims_word,...
    cfg.stim.practice.nPairs_test_lure * length(phaseCfg.categoryNames),...
    cfg.stim.practice.rmStims_init,cfg.stim.practice.shuffleFirst_init,{'practice','targ','spaced','lag','presNum','pairNum','pairOrd'},{true,false,[],[],[],[],[]});
else
  % for the real experiment
  
  % put all the image stimuli together, across categories
  for cn = 1:length(cfg.stim.categoryNames)
    if ismember(cfg.stim.categoryNames{cn},phaseCfg.categoryNames)
      [expParam.session.(sesName).(phaseName)(phaseCount).testStims_img,imgStimStruct(cn).catStims] = space_divvyStims(...
        imgStimStruct(cn).catStims,expParam.session.(sesName).(phaseName)(phaseCount).testStims_img,...
        cfg.stim.nPairs_test_lure,...
        cfg.stim.rmStims_init,cfg.stim.shuffleFirst_init,{'practice','targ','spaced','lag','presNum','pairNum','pairOrd'},{false,false,[],[],[],[],[]});
    end
  end
  
  % do the word stimuli
  [expParam.session.(sesName).(phaseName)(phaseCount).testStims_word,wordStimStruct.wordStims] = space_divvyStims(...
    wordStimStruct.wordStims,expParam.session.(sesName).(phaseName)(phaseCount).testStims_word,...
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

% combine the study and test stimuli and shuffle again
expParam.session.(sesName).(phaseName)(phaseCount).testStims_img = cat(1,p1_StudyStims_img',expParam.session.(sesName).(phaseName)(phaseCount).testStims_img);
expParam.session.(sesName).(phaseName)(phaseCount).testStims_word = cat(1,p1_StudyStims_word',expParam.session.(sesName).(phaseName)(phaseCount).testStims_word);

% Reshuffle images for the experiment. No more than X conecutive stimuli
% from the same category
fprintf('Shuffling %s test (%d) task stimuli.\n',sesName,phaseCount);
[expParam.session.(sesName).(phaseName)(phaseCount).testStims_img,randind] = et_shuffleStims(...
  expParam.session.(sesName).(phaseName)(phaseCount).testStims_img,'categoryNum',phaseCfg.crMaxConsecCategory);
  %expParam.session.(sesName).(phaseName)(phaseCount).testStims_img,'targ',phaseCfg.crMaxConsecTarg);

% put the word stimuli in the same shuffled order
expParam.session.(sesName).(phaseName)(phaseCount).testStims_word = expParam.session.(sesName).(phaseName)(phaseCount).testStims_word(randind);

% give them pair numbers
%for i = 1:((cfg.stim.nPairs_study_targ_spaced + cfg.stim.nPairs_study_targ_massed + cfg.stim.nPairs_study_targ_onePres + cfg.stim.nPairs_test_lure) * length(phaseCfg.categoryNames))
for i = 1:length(expParam.session.(sesName).(phaseName)(phaseCount).testStims_img)
  expParam.session.(sesName).(phaseName)(phaseCount).testStims_img(i).pairNum = i;
  expParam.session.(sesName).(phaseName)(phaseCount).testStims_word(i).pairNum = i;
end

fprintf('Done.\n');

end % function
