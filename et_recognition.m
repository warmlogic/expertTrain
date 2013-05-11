function [logFile] = et_recognition(cfg,expParam,logFile,sesName,phase)
% function [logFile] = et_matching(cfg,expParam,logFile,sesName,phase)
%
% Description:
%  This function runs the recognition study and test tasks.
%
%  Study targets are stored in expParam.session.(sesName).(phase).targStims
%  and test targets lures are stored in
%  expParam.session.(sesName).(phase).allStims as structs. Both study
%  targets and target+lure test stimuli must already be sorted in
%  presentation order.
%
%
% Inputs:
%
%
% Outputs:
%
%
% NB:
%  Once agian, study targets and test targets+lures must already be sorted
%  in presentation order!
%

% TODO:
%  make instruction files. read in during config? make images like simon?
%
%

% using these
% cfg.keys.recogKeyNames
% cfg.keys.recogDefUn
% cfg.keys.recogMayUn
% cfg.keys.recogMayF
% cfg.keys.recogDefF
% cfg.keys.recogRecoll

% % not using these
% cfg.keys.recogOld
% cfg.stim.recogNew

% % durations, in seconds
% cfg.stim.(sesName).(phase).study_isi = 0.8;
% cfg.stim.(sesName).(phase).study_preTarg = 0.2;
% cfg.stim.(sesName).(phase).test_isi = 0.8;
% cfg.stim.(sesName).(phase).test_preTarg = 0.2;
% cfg.stim.(sesName).(phase).test_stim = 1.5;
% % TODO: do we need response?
% cfg.stim.(sesName).(phase).response = 1.5;

% debug
sesName = 'pretest';
phase = 'recog';

phaseCfg = cfg.stim.(sesName).(phase);

% make sure we have enough stimuli
if (phaseCfg.nBlocks * phaseCfg.nTargPerBlock) > length(expParam.session.(sesName).(phase).targStims)
  error('Not enough target stimuli per study block!');
end
if (phaseCfg.nBlocks * phaseCfg.nLurePerBlock) > length(expParam.session.(sesName).(phase).lureStims)
  error('Not enough lure stimuli per test block!');
end

for i = 1:phaseCfg.nBlocks
  
  % Run study task
  
  
  % Run test task
  
  
end

end