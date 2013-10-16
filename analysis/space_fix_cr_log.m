function space_fix_cr_log
% fix for SPACE EEG subjects 1 and 2 because an integer %d was missing from
% the format string and the final entry of each RECOGTEST_RECALLRESP was
% written to the next line

dataroot = '~/data/SPACE/Behavioral/Sessions';
%subjects = {'SPACE001','SPACE002'};
subjects = {'SPACE001'};
sesNum = 1;
sesDir = sprintf('session_%d',sesNum);
sesName = 'oneDay';

phaseName = 'cued_recall';
phaseCounts = 1:7;

% phaseName = 'prac_cued_recall';
% phaseCounts = 1;

% also do this for:
% oldLogFile = fullfile(dataroot,subject,sesDir,'session.txt');

renameFiles = true;

for sub = 1:length(subjects)
  subject = subjects{sub};
  for phaseCount = phaseCounts
    
    % twenty-one %s
    oldFormatStr = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s';
    
    % set the log file name
    oldLogFile = fullfile(dataroot,subject,sesDir,sprintf('phaseLog_%s_%s_cr_%d.txt',sesName,phaseName,phaseCount));
    
%     % also process the session.txt log file:
%     if length(phaseCounts) == 1 && phaseCounts == 1
%       oldLogFile = fullfile(dataroot,subject,sesDir,'session.txt');
%     else
%       error('Cannot process session.txt when there is more than one phaseCount.');
%     end
    
    if exist(oldLogFile,'file')
      fid = fopen(oldLogFile,'r');
      logData = textscan(fid,oldFormatStr,'Delimiter','\t','emptyvalue',NaN);
      fclose(fid);
    else
      error('log file not found: %s',oldLogFile);
    end
    
    newLogFile = strrep(oldLogFile,'.txt','_fixed.txt');
    
    if exist(newLogFile,'file')
      %error('new log file already exists: %s',newLogFile);
      fprintf('new log file already exists: %s\nOverwriting...\n',newLogFile);
      %continue
    else
      fprintf('writing new log file: %s\n',newLogFile);
    end
    newLogData = logData;
    
    for i = 1:length(logData{1})
      switch logData{7}{i}
        
        case {'RECOGTEST_RECOGRESP', 'RECOGTEST_NEWRESP'}
          
          if strcmp(logData{17}{i},'none')
            newLogData{17}{i} = 'NO_RESPONSE';
          end
          
          if strcmp(logData{18}{i},'none')
            newLogData{18}{i} = 'NO_RESPONSE_KEY';
          end
          
          if strcmp(logData{20}{i},'NaN')
            newLogData{20}{i} = '-1';
          end
          
        case {'RECOGTEST_RECALLRESP'}
          % use the new lack-of-response format
          if isempty(logData{17}{i})
            newLogData{17}{i} = 'NO_RESPONSE';
          end
          
          if strcmp(logData{17}{i},'none')
            newLogData{17}{i} = 'NO_RESPONSE';
          end
          
          if strcmp(logData{18}{i},'none')
            newLogData{18}{i} = 'NO_RESPONSE_KEY';
          end
          
          if strcmp(logData{20}{i},'NaN')
            newLogData{20}{i} = '-1';
          end
          
          if strcmp(logData{11}{i},'0')
            newLogData{18}{i} = 'LURE_STIM';
          end
          
        case {'1', '0', ''}
          if i > 1
            if strcmp(logData{7}{i-1},'RECOGTEST_RECALLRESP')
              % move the RT to the end of the RECOGTEST_RECALLRESP
              newLogData{end}{i-1} = num2str(str2double(logData{1}{i}));
              
              if strcmp(logData{2}{i},'Crash')
                logData{2}{i} = sprintf('!!! ERROR: %s %s %s',logData{2}{i},logData{3}{i},logData{4}{i});
                logData{3}{i} = '';
                logData{4}{i} = '';
              end
              
              % set the current column j to equal the next column j+1
              for j = 1:length(logData) - 1
                newLogData{j}{i} = logData{j+1}{i};
              end
              
            end
          end
      end
    end
    
    % write out the new file
    newFormatStr = '%s';
    newFormatStr = sprintf('%s%s\\n',newFormatStr,repmat('\t%s',1,numel(newLogData)-1));
    newLogDataStr = sprintf(',newLogData{%d}{i}',2:numel(newLogData));
    newLogDataStr = sprintf('{newLogData{1}{i}%s}',newLogDataStr);
    
    fid = fopen(newLogFile,'w+');
    for i = 1:length(newLogData{1})
      this_newLogData = eval(newLogDataStr);
      fprintf(fid,newFormatStr,this_newLogData{:});
    end
    fclose(fid);
    
    % back up the original file and rename the new one
    if renameFiles
      fprintf('Renaming log files, backing up original files as *_orig.txt and renaming new *_fixed.txt files to original name.\n');
      oldLogFile_mv = strrep(oldLogFile,'.txt','_orig.txt');
      unix(sprintf('mv %s %s',oldLogFile,oldLogFile_mv));
      
      newLogFile_mv = strrep(newLogFile,'_fixed.txt','.txt');
      unix(sprintf('mv %s %s',newLogFile,newLogFile_mv));
    end
    
  end % phaseCount
end % subject
