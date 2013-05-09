function [logFile] = et_naming(cfg,expParam,logFile,sesName,phase)

% cfg.keys.sXX, where XX is an integer, buffered with a zero if i <= 9

phaseCfg = cfg.stim.(sesName).(phase);


% generate random display times for fixation cross
name_preStim = 0.5 + (0.7 - 0.5).*rand(1,1);


  
end