function [logFile] = et_viewing(cfg,expParam,logFile,sesName,phase)
% function [logFile] = et_viewing(cfg,expParam,logFile,sesName,phase)
%
% Descrption:
%  This function runs the viewing task.
%
%  The stimuli for the viewing task must already be in presentation order.
%  They are stored in expParam.session.(sesName).(phase).viewStims as a
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
phase = 'view';
%phase = 'viewname';

% % durations, in seconds
% cfg.stim.(sesName).(phase).view_isi = 0.8;
% cfg.stim.(sesName).(phase).view_preStim = 0.2;
% cfg.stim.(sesName).(phase).view_stim = 4.0;

% cfg.keys.sXX, where XX is an integer, buffered with a zero if i <= 9

% cfg.keys.s00 is "other" (basic) family

phaseCfg = cfg.stim.(sesName).(phase);


end