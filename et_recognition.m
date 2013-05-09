function [logFile] = et_recognition(cfg,expParam,logFile,sesName,phase)

% cfg.keys.recogOld
% cfg.stim.recogNew

phaseCfg = cfg.stim.(sesName).(phase);


% Concatenate target and lure stimuli for test task
allStims = cat(1,expParam.session.(sesName).(phase).targ,expParam.session.(sesName).(phase).lure);
% shuffle so there are only a given number of targets or lures in a row
[allStims] = et_shuffleStims(allStims,'targ',phaseCfg.testMaxConsec);



% Run study task


% Run test task


end