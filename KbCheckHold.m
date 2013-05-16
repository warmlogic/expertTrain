function [state] = KbCheckHold(holdTime, acceptKeys, kbID)
% modification of KbCheck with hold time and acceptKeys -- needs FSA
% holdTime is the amount of time to wait in milliseconds
% acceptKeys is a cell array of acceptable key responses
% kbID is a device ID to check (for millisecond accurate keyboard)
%
% returns
% response: the response

% state enum
WAIT_FOR_ACCEPTKEY_PRESS = 1;
WAIT_FOR_HOLDTIME = 2;
HOLD_SUCCESS = 3;
state = WAIT_FOR_ACCEPTKEY_PRESS;

KbReleaseWait;
while state ~= HOLD_SUCCESS    
    
    switch state
        
        case{WAIT_FOR_ACCEPTKEY_PRESS}
            [keyIsDown, timeSecs, keyCode, deltaSecs] = KbCheck(kbID);
            if(keyIsDown)
                % strip garbage if any and check to see if matches keycode
                tmp = KbName(keyCode);
                tmp = tmp(1);
                if(strmatch(tmp, acceptKeys))
                    % start timers and reset key state
                    startSecs = GetSecs;
                    stopSecs = startSecs+(holdTime/1000);
                    
                    keyIsDown = 0;
                    state = WAIT_FOR_HOLDTIME;
                end
            end
            
        case{WAIT_FOR_HOLDTIME}
            [keyIsDown, timeSecs, keyCode, deltaSecs] = KbCheck(kbID);
            % strip garbage if any and check to see if matches keycode
            if(keyIsDown)
                tmp = KbName(keyCode);
                tmp = tmp(1);
                if(strmatch(tmp, acceptKeys))
                    % stop if timer exceeded, otherwise no state change
                    if GetSecs > stopSecs
                        state = HOLD_SUCCESS;
                    end                
                end
            else % user let go of key
                state = WAIT_FOR_ACCEPTKEY_PRESS;
            end
            
    end
end