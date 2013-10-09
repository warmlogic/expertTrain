% SPACE timing
home

nCategories = 2;

isExp = true;

if ~isExp
  % practice
  nBlocks = 1;
  
  spaced = 2;
  massed = 2;
  onePres = 2;
  buffers = 0; % start + end
  lures = 2;
  
  nDist = 5;
  
elseif isExp
  % real experiment
  
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
  
  nBlocks = 4;

  spaced = 7;
  massed = 7;
  onePres = 7;
  buffers = 2; % start + end together
  lures = 7;
  
  nDist = 50;
end

nExpoStimuli = (spaced + massed + onePres + buffers) * nCategories;
nStudyStimuli = (((spaced + massed)*2) + onePres + buffers) * nCategories;

nTestStimuli = (spaced + massed + onePres + lures) * nCategories;

% % don't test single presentation items
% nTestStimuli = (spaced + massed + lures) * nCategories;

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

fprintf('Exposure to %d images:\t%.2f minutes.\n',nExpoStimuli,(expoTime / 60));
fprintf('\t# spaced per category: %d\n',spaced);
fprintf('\t# massed per category: %d\n',massed);
fprintf('\t# onePres per category: %d\n',onePres);
fprintf('\t# buffers (start+end) per category: %d\n',buffers);
fprintf('Study %d word+image pairs:\t%.2f minutes.\n',nStudyStimuli,(studyTime / 60));
fprintf('Distractor: %d math problems:\t%.2f minutes.\n',nDist,(distTime / 60));
fprintf('Cued recall for %d images:\t%.2f minutes.\n',nTestStimuli,(testTime / 60));

fprintf('\nTotal time per list: %.2f minutes\n',(totalTime / 60));

fprintf('Total experiment (%d blocks): %.2f minutes\n\n',nBlocks,(totalTime * nBlocks / 60));
