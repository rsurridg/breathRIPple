classdef FileIOHandler < handle
    %FILEMAKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CHData
        DefaultDirectory = cd;
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
            
            chest = obj.CHData.getFiltData();
            abdomen = obj.CHData.getAssociatedData();
            time = (1:1:length(chest))./metadata.SamplingFrequency;
            
            chest = chest(:);
            abdomen = abdomen(:);
            time = time(:);
            
            units = metadata.SignalUnits;
            
            colNames = {'Time (sec)', sprintf('Chest (%s)', units),...
                sprintf('Abdomen (%s)', units)};
            
            
            data = horzcat(time, chest, abdomen);
            data = num2cell(data);
            
            finalData = vertcat(colNames, data);
            
            filter = {'*.csv';'*.xls';'*.xlsm'; '*.xlsx*';'*.xlsb*';'*.dat*'; '*.txt*'};
            [file,path] = uiputfile(filter, 'Save Raw Data', 'RawDataExport.csv');
            obj.updateDirectory(path);
            
            if ~isempty(file)
                try
                    writecell(finalData, [path file]);
                    uialert(figHandle, 'Export successful!', 'Export Successful', 'Icon', 'success');
                catch excep
                    uialert(figHandle, 'Unable to write file.', 'Failure on Write');
                end
            end

        end
        
        function exportAnalysis(obj, figHandle, removedBreaths)
            
            metadata = obj.CHData.getMetadata();
            
            ptInfoCell = struct2cell(metadata.PTInfo);
            ptInfoFieldNames = fieldnames(metadata.PTInfo);
            
            userInfoCell = struct2cell(metadata.UserInfo);
            userInfoFieldNames = fieldnames(metadata.UserInfo);
            
            rowNames = vertcat(ptInfoFieldNames, userInfoFieldNames);
            rowValues = vertcat(ptInfoCell, userInfoCell);
            
            header = horzcat(rowNames, rowValues);
            
            analyzableBreaths = obj.CHData.getIndicesAnalyzable();
            if ~isempty(removedBreaths)
                for i = 1:length(removedBreaths)
                    analyzableBreaths(analyzableBreaths == removedBreaths(i)) = [];
                end
            end
                
            
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
            
            finalData = vertcat(colNames, data);
            
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

        end
        
    end
        
end

