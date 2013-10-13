% SPACE timing
home

nCategories = 2;

isExp = true;

testOnePres = false;

useNS = true;

if ~isExp
  % practice
  eegSetupTime = 0;
  nImpedance = 0;
  impedanceTime = 0;
  
  nBlocks = 1;
  
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
    nImpedance = 3;
  else
    eegSetupTime = 0;
    nImpedance = 0;
    impedanceTime = 0;
  end
  
  %   nBlocks = 2;
% 
%   spaced = 16;
%   massed = 16;
%   onePres = 16;
%   buffers = 2; % start + end together
%   lures = 16;

%   nBlocks = 3;
% 
%   spaced = 9;
%   massed = 9;
%   onePres = 9;
%   buffers = 2; % start + end together
%   lures = 9;
  
%   nBlocks = 4; % behavioral
  nBlocks = 7; % EEG?

  spaced = 7;
  massed = 7;
  onePres = 7;
  buffers = 4; % start + end together
  lures = 7;
  
  nDist = 50;
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

expo_isi = 0;
expo_preStim = mean([1.0 1.2]);
expo_stim = 1.0;
expo_resp = 0.4;

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
dist_prob = 2;

dist_trial = dist_preStim + dist_prob;
distTime = dist_trial * nDist; 

% cued recall

cr_isi = 0;
cr_preStim = mean([1.0 1.2]);
cr_stim = 1.0;
cr_recogResp = 1.0;
cr_recallResp = 2;

cr_trial = cr_isi + cr_preStim + cr_stim + cr_recogResp + cr_recallResp;
testTime = cr_trial * nTestStimuli; 

% total time

totalTime = expoTime + studyTime + distTime + testTime;

totalExpTime = (totalTime * nBlocks) + eegSetupTime + (nImpedance * impedanceTime);

fprintf('Exposure to %d images:\t%.2f minutes.\n',nExpoStimuli,(expoTime / 60));
fprintf('\t# spaced per category: %d (%d in %d blocks)\n',spaced, spaced * nBlocks, nBlocks);
fprintf('\t# massed per category: %d (%d in %d blocks)\n',massed, massed * nBlocks, nBlocks);
fprintf('\t# onePres per category: %d (%d in %d blocks)\n',onePres, onePres * nBlocks, nBlocks);
fprintf('\t# buffers (start+end) per category: %d (%d in %d blocks)\n',buffers, buffers * nBlocks, nBlocks);

fprintf('Study %d word+image pair presentations:\t%.2f minutes.\n',nStudyStimuli,(studyTime / 60));
fprintf('\t# spaced per category: %d (%d in %d blocks)\n',spaced, spaced * nBlocks, nBlocks);
fprintf('\t# massed per category: %d (%d in %d blocks)\n',massed, massed * nBlocks, nBlocks);
fprintf('\t# onePres per category: %d (%d in %d blocks)\n',onePres, onePres * nBlocks, nBlocks);
fprintf('\t# buffers (start+end) per category: %d (%d in %d blocks)\n',buffers, buffers * nBlocks, nBlocks);

fprintf('Distractor: %d math problems:\t%.2f minutes.\n',nDist,(distTime / 60));

fprintf('Cued recall for %d images:\t%.2f minutes.\n',nTestStimuli,(testTime / 60));
fprintf('\t# spaced per category: %d (%d in %d blocks)\n',spaced, spaced * nBlocks, nBlocks);
fprintf('\t# massed per category: %d (%d in %d blocks)\n',massed, massed * nBlocks, nBlocks);
if testOnePres
  fprintf('\t# onePres per category: %d (%d in %d blocks)\n',onePres, onePres * nBlocks, nBlocks);
end
fprintf('\t# lures per category: %d (%d in %d blocks)\n',lures, lures * nBlocks, nBlocks);


fprintf('\nTotal time per list: %.2f minutes\n',(totalTime / 60));

fprintf('Total experiment (%d blocks): %.2f minutes\n\n',nBlocks,(totalExpTime / 60));
