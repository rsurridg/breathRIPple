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
            
            try
                progress = uiprogressdlg(obj.AppFigure,'Title', 'Data Upload In Progress', 'Message', 'Uploading .csv...',...
                    'Indeterminate','on');
                data = importBioRadioCSV([path file]);
                close(progress);

                metadata = obj.assembleMetadata(data.ElapsedTime);
                
                CHrecording = BandRecording(-data.RC, -data.AB, metadata);
                
                goodToClose = true;
                
            catch ME
                uialert(obj.AppFigure, 'File upload failed. Please try again.', 'File upload fail');
                CHrecording = [];
                goodToClose = false;
            end
            

        end
        
        function metadata = assembleMetadata(obj, time)
            ts1 = second(time(2));
            ts2 = second(time(3));
            
            metadata.PTInfo = obj.PTInfo;
            metadata.UserInfo = obj.UserInfo;
            
            metadata.SamplingFrequency = 1/(round((ts2-ts1), 3)); % convert from msec to sec
            metadata.SignalUnits = 'mV';
            metadata.SleepStatus = obj.SleepStatus;     
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



