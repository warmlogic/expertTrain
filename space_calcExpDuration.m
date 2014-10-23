% SPACE timing
home

% expName = 'SPACE';
expName = 'SPACE2';

% face/house
nCategories = 2;

% isExp = false; % prac
isExp = true;

if strcmp(expName,'SPACE')
  testOnePres = false;
elseif strcmp(expName,'SPACE2')
  testOnePres = true;
end

useNS = true;
% useNS = false;

if ~isExp
  % practice
  eegSetupTime = 0;
  nImpedance = 0;
  impedanceTime = 0;
  
  nBlocks = 1;
  
  % number of stimuli per category (face/house)
  spaced = 2;
  massed = 2;
  onePres = 2;
  buffers = 0; % start + end
  lures = 2;
  
  nDist = 5;
  
elseif isExp
  % real experiment
  
  if useNS
    eegSetupTime = 30 * 60;
    impedanceTime = 5 * 60;
    if strcmp(expName,'SPACE')
      nImpedance = 3;
    elseif strcmp(expName,'SPACE2')
      nImpedance = 3;
    end
  else
    eegSetupTime = 0;
    nImpedance = 0;
    impedanceTime = 0;
  end
  
  %   nBlocks = 2;
%   % number of stimuli per category (face/house)
%   spaced = 16;
%   massed = 16;
%   onePres = 16;
%   buffers = 2; % start + end together
%   lures = 16;

%   nBlocks = 3;
%   % number of stimuli per category (face/house)
%   spaced = 9;
%   massed = 9;
%   onePres = 9;
%   buffers = 2; % start + end together
%   lures = 9;
  
  if strcmp(expName,'SPACE')
    %   nBlocks = 4; % behavioral
    nBlocks = 6; % EEG
    % number of stimuli per category (face/house)
    spaced = 7;
    massed = 7;
    onePres = 7;
    buffers = 4; % start + end together
    lures = 7;
    
    nDist = 50;
    
  elseif strcmp(expName,'SPACE2')
    nBlocks = 9; % EEG
    % number of stimuli per category (face/house)
    spaced = 9;
    massed = 3;
    onePres = 3;
    buffers = 4; % start + end together
    lures = 0;
    
%     nBlocks = 7; % EEG
%     % number of stimuli per category (face/house)
%     spaced = 12;
%     massed = 4;
%     onePres = 4;
%     buffers = 4; % start + end together
%     lures = 0;
    
%     nBlocks = 6; % EEG
%     % number of stimuli per category (face/house)
%     spaced = 15;
%     massed = 5;
%     onePres = 5;
%     buffers = 4; % start + end together
%     lures = 0;
    
%     nBlocks = 5; % EEG
%     % number of stimuli per category (face/house)
%     spaced = 18;
%     massed = 6;
%     onePres = 6;
%     buffers = 4; % start + end together
%     lures = 0;
    
    % math distractor
    nDist = 45;
  end
end

nExpoStimuli = (spaced + massed + onePres + buffers) * nCategories;
nStudyStimuli = (((spaced + massed)*2) + onePres + buffers) * nCategories;

if testOnePres
  nTestStimuli = (spaced + massed + onePres + lures) * nCategories;
else
  % don't test single presentation items
  nTestStimuli = (spaced + massed + lures) * nCategories;
end

% exposure

if strcmp(expName,'SPACE')
  expo_isi = 0;
  expo_preStim = mean([1.0 1.2]);
  expo_stim = 1.0;
  expo_resp = 0.75;
  
elseif strcmp(expName,'SPACE2')
  % no expo
  expo_isi = 0;
  expo_preStim = 0;
  expo_stim = 0;
  expo_resp = 0;
  
%   expo_isi = 0;
%   expo_preStim = mean([1.0 1.2]);
%   expo_stim = 1.0;
%   expo_resp = 0.75;
end

expo_trial = expo_isi + expo_preStim + expo_stim + expo_resp;
expoTime = expo_trial * nStudyStimuli; 

% study

study_isi = 0;
study_preStim = mean([1.0 1.2]);
study_stim1 = 1.0;
study_stim2 = 1.0;
study_resp = 0;

if study_resp > 0
  expoTime = 0;
end

study_trial = study_isi + study_preStim + study_stim1 + study_stim2 + study_resp;
studyTime = study_trial * nStudyStimuli; 

% math distractor

dist_preStim = mean([0.25 0.5]);
dist_prob = 2.5;

dist_trial = dist_preStim + dist_prob;
distTime = dist_trial * nDist; 

% cued recall

cr_isi = 0;
cr_preStim = mean([1.0 1.2]);
cr_stim = 1.0;
% % SPACE
% cr_recogResp = 1.0;
% SPACE2
cr_recogResp = 0;
cr_recallResp = 5;

cr_trial = cr_isi + cr_preStim + cr_stim + cr_recogResp + cr_recallResp;
testTime = cr_trial * nTestStimuli; 

% total time

totalTime = expoTime + studyTime + distTime + testTime;

totalExpTime = (totalTime * nBlocks) + eegSetupTime + (nImpedance * impedanceTime);

fprintf('==========================================================================\n');
fprintf('%d image categories:\n\n',nCategories);
if expoTime > 0
  fprintf('Exposure to %d images:\t%.2f minutes.\n',nExpoStimuli,(expoTime / 60));
  fprintf('\t# spaced per category: %d (%d in %d blocks)\n',spaced, spaced * nBlocks, nBlocks);
  fprintf('\t# massed per category: %d (%d in %d blocks)\n',massed, massed * nBlocks, nBlocks);
  fprintf('\t# onePres per category: %d (%d in %d blocks)\n',onePres, onePres * nBlocks, nBlocks);
  fprintf('\t# buffers (start+end) per category: %d (%d in %d blocks)\n',buffers, buffers * nBlocks, nBlocks);
  fprintf('\n');
end

fprintf('Study %d word+image pair presentations:\t%.2f minutes.\n',nStudyStimuli,(studyTime / 60));
fprintf('\t# spaced per category: %d (%d in %d blocks)\n',spaced, spaced * nBlocks, nBlocks);
fprintf('\t# massed per category: %d (%d in %d blocks)\n',massed, massed * nBlocks, nBlocks);
fprintf('\t# onePres per category: %d (%d in %d blocks)\n',onePres, onePres * nBlocks, nBlocks);
fprintf('\t# buffers (start+end) per category: %d (%d in %d blocks)\n',buffers, buffers * nBlocks, nBlocks);

fprintf('\n');
fprintf('Distractor: %d math problems:\t%.2f minutes.\n',nDist,(distTime / 60));

fprintf('\n');
fprintf('Cued recall for %d images:\t%.2f minutes.\n',nTestStimuli,(testTime / 60));
fprintf('\t# spaced per category: %d (%d in %d blocks)\n',spaced, spaced * nBlocks, nBlocks);
fprintf('\t# massed per category: %d (%d in %d blocks)\n',massed, massed * nBlocks, nBlocks);
if testOnePres
  fprintf('\t# onePres per category: %d (%d in %d blocks)\n',onePres, onePres * nBlocks, nBlocks);
end
fprintf('\t# lures per category: %d (%d in %d blocks)\n',lures, lures * nBlocks, nBlocks);

fprintf('\n===\n');

fprintf('\nTotal time per list: %.2f minutes\n',(totalTime / 60));

fprintf('\n===\n');

fprintf('\nTotal experiment (%d blocks): %.2f minutes\n\n',nBlocks,(totalExpTime / 60));

fprintf('==========================================================================\n');
