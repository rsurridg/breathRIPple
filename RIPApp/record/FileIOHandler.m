classdef FileIOHandler < handle
    %FILEMAKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CHData
        DefaultDirectory = cd;
        AnalyzableBreathsOriginal
    end
    
    methods 
        function obj = FileIOHandler(chdata)
            %FILEMAKER Construct an instance of this class
            %   Detailed explanation goes here
            obj.CHData = chdata;
        end
       
        
        function obj = updateDirectory(obj, path)
            obj.DefaultDirectory = path;
        end
        
        
        function saveRawDataFile(obj, figHandle)
            
            metadata = obj.CHData.getMetadata();
            
            chest = obj.CHData.getRawData();
            abdomen = obj.CHData.getRawAssociatedData();
            time = (1:1:length(chest))./metadata.SamplingFrequency;
            
            sleepStatusLogical = true(size(time));
            
            sleepStatus = metadata.SleepStatus;
            if ~isempty(sleepStatus)
                for i = 1:2:length(sleepStatus)-1
                    subset = time > sleepStatus{i} & time < sleepStatus{i+1};
                    sleepStatusLogical(subset) = false;
                end
            end
            
            chest = chest(:);
            abdomen = abdomen(:);
            time = time(:);
            sleepStatusLogical = sleepStatusLogical(:);
            
            units = metadata.SignalUnits;
            
            colNames = {'Time (sec)', sprintf('Chest (%s)', units),...
                sprintf('Abdomen (%s)', units), 'Quiet Sleep'};
            
            
            data = horzcat(time, chest, abdomen, sleepStatusLogical);
            data = rmmissing(data);
            
            finalData = array2table(data, 'VariableNames', colNames);
           
            
            filter = {'*.csv';'*.xls';'*.xlsm'; '*.xlsx*';'*.xlsb*';'*.dat*'; '*.txt*'};
            [file,path] = uiputfile(filter, 'Save Raw Data', 'RawDataExport.csv');
            obj.updateDirectory(path);
            
            if ~isempty(file)
                try
                    progress = uiprogressdlg(figHandle,'Title', 'Data Export In Progress', 'Message', 'Exporting raw data...',...
                    'Indeterminate','on');
                    writetable(finalData, [path file]);
                    close(progress);
                    uialert(figHandle, 'Export successful!', 'Export Successful', 'Icon', 'success');
                catch excep
                    uialert(figHandle, 'Unable to write file.', 'Failure on Write');
                end
            end

        end
        
        function exportAnalysis(obj, figHandle, removedBreaths)
            
            obj.removeAnalyzableBreaths(removedBreaths);
            
            header = obj.assembleHeader();
            finalData = obj.assembleData();
            
            
            filter = {'*.csv';'*.xls';'*.xlsm'; '*.xlsx*';'*.xlsb*';'*.dat*'; '*.txt*'};
            [file,path] = uiputfile(filter, 'Save Analysis', 'RIPAnalysis.csv');
            obj.updateDirectory(path);
            
            if ~isempty(file)
                try
                    writecell(header, [path file]);
                    writecell(finalData, [path file], 'WriteMode', 'append');
                    uialert(figHandle, 'Export successful!', 'Export Successful', 'Icon', 'success');
                catch excep
                    uialert(figHandle, 'Unable to write file. File may be open in another program.', 'Failure on Write');
                end
            end
            
            obj.replaceAnalyzableBreaths(removedBreaths);
            
            

        end
        
        function removeAnalyzableBreaths(obj, removedBreaths)
            obj.AnalyzableBreathsOriginal = obj.CHData.getIndicesAnalyzable();
            if ~isempty(removedBreaths)
                for i = 1:length(removedBreaths)
                    obj.CHData.overrideAnalyzable(obj.AnalyzableBreathsOriginal(removedBreaths(i)), false);
                end
            end
        end
        
        function replaceAnalyzableBreaths(obj, removedBreaths)
            for i = 1:length(removedBreaths)
                obj.CHData.overrideAnalyzable(obj.AnalyzableBreathsOriginal(removedBreaths(i)), true);
            end
        end
        
        function header = assembleHeader(obj)
            metadata = obj.CHData.getMetadata();
            
            ptInfoCell = struct2cell(metadata.PTInfo);
            ptInfoFieldNames = fieldnames(metadata.PTInfo);
            
            userInfoCell = struct2cell(metadata.UserInfo);
            userInfoFieldNames = fieldnames(metadata.UserInfo);
            
            rowNames = vertcat(ptInfoFieldNames, userInfoFieldNames);
            rowValues = vertcat(ptInfoCell, userInfoCell);
            
            header = horzcat(rowNames, rowValues);
            
        end
        
        function data = assembleData(obj)
            analyzableBreaths = obj.CHData.getIndicesAnalyzable();
            metadata = obj.CHData.getMetadata();

            nRows = length(analyzableBreaths);
            
            startIndices = zeros(nRows, 1);
            duration = zeros(nRows, 1);
            PA = zeros(nRows, 1);
            TPEFTE = zeros(nRows, 1);
            RCi = zeros(nRows, 1);
            
            for i = 1:nRows
                breath = obj.CHData.getBreath(analyzableBreaths(i));
                chckAnalyzable = breath.getAnalyzable();
                if ~chckAnalyzable
                    warning('Nonanalyzable breath in output!')
                end
                startIndices(i) = breath.getStartIndex()/metadata.SamplingFrequency;
                duration(i) = breath.getDuration();
                PA(i) = breath.getPhaseAngle();
                TPEFTE(i) = breath.getTPEFTE();
                RCi(i) = breath.getRCI();
            end
            
            breathNum = 1:nRows;
            
            colNames = {'Breath Number',...
                'Start Time (sec)',...
                'Duration (sec)',...
                'PhaseAngle (deg)',...
                'TpefTE',...
                'pRC'};

            data = horzcat(breathNum(:), startIndices(:), duration(:), PA(:), TPEFTE(:), RCi(:));
            data = num2cell(data);
            
            data = vertcat(colNames, data);
        
        
        end
        
        
    end
        
end

