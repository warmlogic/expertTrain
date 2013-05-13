function [logFile] = et_matching(w,cfg,expParam,logFile,sesName,phase)
% function [logFile] = et_matching(w,cfg,expParam,logFile,sesName,phase)
%
% Description:
%  This function runs the matching task. There are no blocks, only short
%  (blink) breaks.
%  TODO: Maybe add a longer break in the middle and tell subjects that this
%  is the middle of the experiment.
%
%  The stimuli for the matching task must already be in presentation order.
%  They are stored in expParam.session.(sesName).(phase).allStims as a
%  struct.
%
%
% Inputs:
%
%
% Outputs:
%
%
%
% NB:
%  Once agian, stimuli must already be sorted in presentation order!
%
% NB:
%  Field 'matchStimNum' denotes whether a stimulus is stim1 or stim2.
%  Field 'matchPairNum' denotes which two stimuli are paired. matchPairNum
%   overlaps in the same and different condition
%
% NB:
%  When same and diff stimuli are combined, to find the corresponding pair
%  search for a matching familyNum (basic or subordinate), a matching or
%  different speciesNum field (same or diff condition), a matching or
%  different trained field, the same matchPairNum, and the opposite
%  matchStimNum (1 or 2).

% EBUG stimuli are basic/subordinate x trained/untrained x same/different.

% debug
sesName = 'pretest';
phase = 'match';

% % durations, in seconds
% cfg.stim.(sesName).(phase).isi = 0.5;
% cfg.stim.(sesName).(phase).stim1 = 0.8;
% cfg.stim.(sesName).(phase).stim2 = 0.8;
% % random intervals are generated on the fly
% %cfg.stim.(sesName).(phase).preStim1 = 0.5 to 0.7;
% %cfg.stim.(sesName).(phase).preStim2 = 1.0 to 1.2;
% % TODO: do we need response?
% cfg.stim.(sesName).(phase).response = 1.0;

% cfg.keys.matchSame
% cfg.keys.matchDiff

% debug


phaseCfg = cfg.stim.(sesName).(phase);
allStims = expParam.session.(sesName).(phase).allStims;

% get the indices of all stimulus 2s
allStims2Ind = find([allStims.matchStimNum] == 2);

for i = 1:length(allStims2Ind)
  % get the stimulus for stim2
  stim2 =  allStims(allStims2Ind(i));
  % find its corresponding pair, contingent upon whether this is a same or
  % diff stimulus
  
  % same (same species)
  if stim2.same
    stim1 = allStims(([allStims.familyNum] == allStims(allStims2Ind(i)).familyNum) &...
      ([allStims.speciesNum] == allStims(allStims2Ind(i)).speciesNum) &...
      ([allStims.trained] == allStims(allStims2Ind(i)).trained) &...
      ([allStims.matchPairNum] == allStims(allStims2Ind(i)).matchPairNum) &...
      ([allStims.matchStimNum] ~= allStims(allStims2Ind(i)).matchStimNum));
    
    %   stim1 = allStims(([allStims.familyNum] == allStims(allStims2Ind(i)).familyNum) &...
    %     ([allStims.trained] == allStims(allStims2Ind(i)).trained) &...
    %     ([allStims.matchPairNum] == allStims(allStims2Ind(i)).matchPairNum) &...
    %     ([allStims.matchStimNum] ~= allStims(allStims2Ind(i)).matchStimNum));
    
  else
    % diff (different species)
    stim1 = allStims(([allStims.familyNum] == allStims(allStims2Ind(i)).familyNum) &...
      ([allStims.speciesNum] ~= allStims(allStims2Ind(i)).speciesNum) &...
      ([allStims.trained] == allStims(allStims2Ind(i)).trained) &...
      ([allStims.matchPairNum] == allStims(allStims2Ind(i)).matchPairNum) &...
      ([allStims.matchStimNum] ~= allStims(allStims2Ind(i)).matchStimNum));
  end
  
  % generate random durations for fixation crosses
  preStim1 = 0.5 + (0.7 - 0.5).*rand(1,1);
  preStim2 = 1.0 + (1.2 - 1.0).*rand(1,1);
  
  if stim1.familyNum == cfg.stim.famNumBasic
    % expect a basic level response
    
  elseif stim1.familyNum == cfg.stim.famNumSubord
    % expect a subordinate level response
    
  end

end


end