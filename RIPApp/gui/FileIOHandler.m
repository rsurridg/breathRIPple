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
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            chest = obj.CHData.getFiltData();
            abdomen = obj.CHData.getAssociatedData();
            time = (1:1:length(chest))./obj.Metadata.SamplingFrequency;
            
            chest = chest(:);
            abdomen = abdomen(:);
            time = time(:);
            
            units = obj.Metadata.SignalUnits;
            
            colNames = {'Time_sec',...
                sprintf('Chest_%s', units),...
                sprintf('Abdomen_%s', units)};
            
            
            data = table(time, chest, abdomen, 'VariableNames', colNames);
            filter = {'*.csv';'*.xls';'*.xlsm'; '*.xlsx*';'*.xlsb*';'*.dat*'; '*.txt*'};
            [file,path] = uiputfile(filter, 'Save Raw Data', 'RawDataExport.csv');
            
            if ~isempty(file)
                try
                    obj.updateDirectory(path);
                    writetable(data,file);
                catch excep
                    uialert(figHandle, 'Unable to write file. File may be open in another program.', 'Failure on Write');
                end
            end

        end
        
        function exportAnalysis(obj, figHandle)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            metadata = obj.CHData.getMetadata();
            
            ptInfoCell = struct2cell(metadata.PTInfo);
            ptInfoFieldNames = fieldnames(metadata.PTInfo);
            
            userInfoCell = struct2cell(metadata.UserInfo);
            userInfoFieldNames = fieldnames(metadata.UserInfo);
            
            rowNames = vertcat(ptInfoFieldNames, userInfoFieldNames);
            rowValues = vertcat(ptInfoCell, userInfoCell);
            
            header = horzcat(rowNames, rowValues);
            
            analyzableBreaths = obj.CHData.getIndicesAnalyzable();
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
            
            colNames = {'StartTime_sec',...
                'Duration_sec',...
                'PhaseAngle_deg',...
                'TpefTE',...
                'pRC'};
            
            
            data = {startIndices(:), duration(:), PA(:), TPEFTE(:), RCi(:)};
            
            data = vertcat(colNames, data);
            
            filter = {'*.csv';'*.xls';'*.xlsm'; '*.xlsx*';'*.xlsb*';'*.dat*'; '*.txt*'};
            [file,path] = uiputfile(filter, 'Save Analysis', 'RIPAnalysis.csv');
            
            if ~isempty(file)
                %try
                    writecell(header, [path file]);
                    writecell(data, [path file], 'WriteMode', 'append');
                    obj.updateDirectory(path);
%                 catch excep
%                     uialert(figHandle, 'Unable to write file. File may be open in another program.', 'Failure on Write');
%                 end
            end

        end
        
    end
        
end

