classdef FileInHandler < handle
    %FILEMAKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SleepStatus
        PTInfo
        UserInfo
        AppFigure
        DefaultDirectory = cd;
    end
    
    methods 
        function obj = FileInHandler(appFigure, sleepStatus, ptInfo, userInfo)
            obj.AppFigure = appFigure;
            obj.SleepStatus = sleepStatus;
            obj.PTInfo = ptInfo;
            obj.UserInfo = userInfo;
        end
       
        
        function obj = updateDirectory(obj, path)
            obj.DefaultDirectory = path;
        end
        
        
        function [goodToClose, CHrecording] = uploadRawDataFile(obj)
            filter = {'*.csv'};
            [file,path] = uigetfile(filter, 'Load RIP Data');
            
            %try
                progress = uiprogressdlg(obj.AppFigure,'Title', 'Data Upload In Progress', 'Message', 'Uploading .csv...',...
                    'Indeterminate','on');
                data = importBioRadioCSV([path file]);
                close(progress);

                metadata = obj.assembleMetadata(data.ElapsedTime);
                
                if ~isempty(metadata.SleepStatus)
                    [goodToCloseSS, updatedSleepStatus] = obj.checkSleepStatusDuration(height(data), metadata);
                    metadata.SleepStatus = updatedSleepStatus;
                else
                    goodToCloseSS = true;
                end
                
                if goodToCloseSS
                    CHrecording = BandRecording(-data.RC, -data.AB, metadata);
                    goodToClose = true;
                else
                    goodToClose = false;
                end
                
%             catch ME
%                 uialert(obj.AppFigure, 'File upload failed. Please try again.', 'File upload fail');
%                 CHrecording = [];
%                 goodToClose = false;
%             end
            

        end
        
        function metadata = assembleMetadata(obj, time)
            ts1 = second(time(2));
            ts2 = second(time(3));
            
            metadata.PTInfo = obj.PTInfo;
            metadata.UserInfo = obj.UserInfo;
            
            
            seconds = second(time);
            diffSeconds = diff(seconds);
            diffSeconds = diffSeconds(~isnan(diffSeconds));
            modeDiff = mode(diffSeconds);
            
            metadata.SamplingFrequency = round(1/modeDiff);
            metadata.SignalUnits = 'mV';
            metadata.SleepStatus = obj.SleepStatus;     
        end
        
        function [goodToClose, updatedSleepStatus] = checkSleepStatusDuration(obj, dataLength, metadata)
            sleepStatusCopy = metadata.SleepStatus;
            sleepStatusEnd = sleepStatusCopy{end};
            endTime = dataLength/metadata.SamplingFrequency;
            
            if endTime - sleepStatusEnd > 10
                selection = uiconfirm(obj.AppFigure,...
                    sprintf("The recording you uploaded is %d seconds long, but you only provided sleep status information for %d seconds. Are you sure you would like to proceed? Last known sleep status will be assumed through end of recording.", round(endTime), round(sleepStatusEnd)), ...
                    "Not Enough Sleep Status Information",...
                    'Options', {'Continue', 'Go Back'}, 'DefaultOption', 2, 'CancelOption', 2);
                if strcmp(selection, 'Continue')
                    sleepStatusCopy{end} = endTime; % just extend the last known sleep status
                    updatedSleepStatus = sleepStatusCopy;
                    goodToClose = true;
                else
                    goodToClose = false;
                end
                
            elseif endTime - sleepStatusEnd < -10
                selection = uiconfirm(obj.AppFigure,...
                    sprintf("The recording you uploaded is %d seconds long, but you provided sleep status information for %d seconds. Are you sure you would like to proceed? Sleep status information will be trimmed to fit data.", round(endTime), round(sleepStatusEnd)), ...
                    "Not Enough Sleep Status Information",...
                    'Options', {'Continue', 'Go Back'}, 'DefaultOption', 2, 'CancelOption', 2);
                if strcmp(selection, 'Continue')
                    sleepStatusCopy(sleepStatusCopy > endTime) = []; % get rid of everything that happened after recording ended
                    sleepStatusCopy{end+1} = endTime; % add a end time
                    updatedSleepStatus = sleepStatusCopy;
                    goodToClose = true;
                else
                    goodToClose = false;
                end
                
            elseif endTime > sleepStatusEnd
                % not enough sleep status data but we're not going to
                % prompt the user about it
                sleepStatusCopy{end} = endTime; % just extend the last known sleep status
                updatedSleepStatus = sleepStatusCopy;
                goodToClose = true;
                
            else % too much sleep status data, endTime < sleepStatusEnd
                sleepStatusCopy(sleepStatusCopy > endTime) = []; % get rid of everything that happened after recording ended
                sleepStatusCopy{end+1} = endTime; % add a end time
                updatedSleepStatus = sleepStatusCopy;
                goodToClose = true;
            end
                
                
        end
            
        
        function [goodToClose, CHrecording, ABrecording, metadata] = dummyUpload(obj, figHandle, sleepStatus)
            load('071411RIPSignals.mat');
            metadata.SamplingFrequency = 1000;
            metadata.SignalUnits = 'mV';
            metadata.SleepStatus = sleepStatus;

            start = 25*60*metadata.SamplingFrequency;
            len = 5*60*metadata.SamplingFrequency; % length must not exceed size of data
            end_i = start+len;

            ABRawData = ABData(start:end_i);
            CHRawData = RCData(start:end_i);

            ABrecording = ABDRecording(ABRawData, metadata); 
            CHrecording = CHRecording(CHRawData, metadata);

            goodToClose = true;
        end
        
        
        
        
        
    end
        
end



