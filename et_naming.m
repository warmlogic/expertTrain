function [logFile] = et_naming(cfg,expParam,logFile,sesName,phase)
% function [logFile] = et_naming(cfg,expParam,logFile,sesName,phase)
%
% Description:
%  This function runs the naming task.
%
%  The stimuli for the naming task must already be in presentation order.
%  They are stored in expParam.session.(sesName).(phase).nameStims as a
%  struct.
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

% debug
sesName = 'train1';
phase = 'name';

% % durations, in seconds
% cfg.stim.(sesName).(phase).name_isi = 0.5;
% % cfg.stim.(sesName).(phase).name_preStim = 0.5 to 0.7;
% cfg.stim.(sesName).(phase).name_stim = 1.0;
% cfg.stim.(sesName).(phase).name_response = 2.0;
% cfg.stim.(sesName).(phase).name_feedback = 1.0;

% cfg.keys.sXX, where XX is an integer, buffered with a zero if i <= 9

phaseCfg = cfg.stim.(sesName).(phase);


% generate random display times for fixation cross
name_preStim = 0.5 + (0.7 - 0.5).*rand(1,1);


  
end