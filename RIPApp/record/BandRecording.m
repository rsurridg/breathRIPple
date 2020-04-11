classdef BandRecording < handle
    properties (Access = protected)
       RawData          % unfiltered data straight from BioRadio
       FilteredData     
       Breaths          % array of breaths parsed from raw data
       AssociatedData
       MetaData         % contains information like sampling frequency, timestamp, etc
    end
    
    
    methods
        function obj = BandRecording(CHdata, ABdata, metadata)
           obj.RawData = CHdata;
           obj.MetaData = metadata;
           obj.FilteredData = obj.filterNoise(CHdata);
           obj.AssociatedData = obj.filterNoise(ABdata);
           
           obj.Breaths = obj.parseData(CHdata);
           obj.Breaths = obj.setSleepStatus();
        end
        
        function metadata = getMetadata(obj)
            metadata = obj.MetaData;
        end
        
        function associatedData = getAssociatedData(obj)
            associatedData = obj.AssociatedData;
        end
        
        function len = getLength(obj)
            len = length(obj.RawData);
        end
        
        function rawData = getRawData(obj)
           rawData = obj.RawData;
        end
      
        function filtData = getFiltData(obj)
            filtData = obj.FilteredData;
        end
        
        function breath = getBreath(obj, num)
            breath = obj.Breaths(num);
        end
        
        function numBreaths = getNumBreaths(obj)
            numBreaths = length(obj.Breaths);
        end
        
        
        function startIndices = getStartIndices(obj)
            startIndices = zeros(length(obj.Breaths),1);
            for i = 1:length(obj.Breaths)
                breath = obj.Breaths(i);
                startIndices(i) = breath.getStartIndex();
            end 
        end
        
        % SETTERS 
        
        function setBreathParameters(obj, i, PA, TPEFTE, RCI)
            obj.Breaths(i).setPhaseAngle(PA);
            obj.Breaths(i).setTPEFTE(TPEFTE);
            obj.Breaths(i).setRCI(RCI);
        end
        
        function setKMDistPass(obj, i, pass)
            obj.Breaths(i).setKMDistancePass(pass);
        end
        
        function setKMCrossoverPass(obj, i, pass)
            obj.Breaths(i).setKMCrossoverPass(pass);
        end
        
        function setAssociatedData(obj, i, data)
            obj.Breaths(i).setAssociatedData(data);
        end 
      
        function evaluateAnalyzable(obj)
            for i = 1:length(obj.Breaths)
                obj.Breaths(i).evaluateAnalyzable();
            end
        end
        
        function overrideAnalyzable(obj, i, pass)
            obj.Breaths(i).overrideAnalyzable(pass);
        end
        
        function filtData = filterNoise(obj, data)
            % Low pass filter the data with a cutoff of 5 Hz. 
           fs = obj.MetaData.SamplingFrequency;
           fz = fs/2;
           cutoff = 5; 
           Wn = cutoff/fz;
           [B, A] = butter(5, Wn, 'low');
           
           filtData = filter(B, A, data); 
        end
        
        function breathList = parseData(obj, data)
            % Parse continuous dataset into an array of individual breath
            % objects. 
          data = obj.filterNoise(data);
          MPP = obj.calculateMinPeakProminence();
          [pks, loc] = findpeaks(-data, 'MinPeakProminence',MPP, 'MinPeakDistance',0.5*obj.MetaData.SamplingFrequency);
          numBreaths = length(pks) - 1;
          breaths = Breath.empty(numBreaths,0);
          
          for i = 1:length(pks)-1
              index = loc(i):loc(i+1);
              breaths(i) = Breath(data(index), i, loc(i), obj.MetaData);
          end
          
          breathList = breaths;

        end
        
        function breaths = setSleepStatus(obj)

            breaths = obj.Breaths;
            
            for i = 1:length(obj.Breaths)
                breaths(i).setQuietSleepPass(true);
            end
            
            % app.SleepStatusChange = [0 a 29 q 70 a 85 q 92 a 108];
            sleepStatus = obj.MetaData.SleepStatus;
            if length(sleepStatus) > 2
                startIndices = obj.getStartIndices();
                startTimes = startIndices./obj.MetaData.SamplingFrequency;

                for i = 1:2:length(sleepStatus)-1
                    % first loop, i = 1 (0), second loop, i = 3 (70), third oop
                    % i = 5 (92)
                    subset = find(startTimes > sleepStatus(i) & startTimes < sleepStatus(i+1));
                    for j = 1:length(subset)
                        breaths(subset(j)).setQuietSleepPass(false);
                    end
                end
            end
            
            c = 0;
            for i = 1:length(breaths)
                if breaths(i).getQuietSleepPass()
                    c = c+1;
                end
            end
            
            obj.MetaData.SleepStatusReport = ['Number of Breaths Eliminated by Sleep Status: ' num2str(length(breaths) - c) ' (out of ' num2str(length(breaths)) ')\n'];
            
                   
        end
        
        function setQDCReport(obj, report)
            obj.MetaData.QDCReport = report;
              
        end
        
        function MPP = calculateMinPeakProminence(obj)
            % finds the range of amplitudes in which the majority of data
            % resides (this is more robust than standard deviation or mean)
            [n, edges] = histcounts(obj.RawData);
            [~, goodBin] = max(n);
            frontEdge = edges(goodBin(1));
            backEdge = edges(goodBin(1) + 1);

            % get subset of data that falls within the majority range
            targetDataInds = obj.RawData > frontEdge & obj.RawData < backEdge;
            MPP = var(obj.RawData(targetDataInds))/10;
        end
      
        function varDuration = calculateDurationVariance(obj)
            durationVector = [];
            for i = 1:length(obj.Breaths)
                durationVector = [durationVector; obj.Breaths(i).getDuration()];
            end
            varDuration = var(durationVector);
        end
        
        function breaths = getBreathsPassDerivative(obj)
            breaths = [];
            for i = 1:length(obj.Breaths)
                if obj.Breaths(i).getDerivativePass()
                    breaths = [breaths; i];
                end
            end
        end
        
        function [meanPA, sdPA] = calculateMeanPA(obj, varargin)
            PA = [];
            if nargin == 1
                for i = 1:length(obj.Breaths)
                    if obj.Breaths(i).getAnalyzable()
                        PA = [PA; obj.Breaths(i).getPhaseAngle()];
                    end
                end
                
            else
                inds = varargin{1};
                for i = 1:length(inds)
                    if obj.Breaths(inds(i)).getAnalyzable()
                        PA = [PA; obj.Breaths(inds(i)).getPhaseAngle()];
                    end
                end
            end
            meanPA = mean(PA);
            sdPA = std(PA);
                
        end
        
        function [meanRCI, sdRCI] = calculateMeanRCI(obj, varargin)
            RCI = [];
            if nargin == 1
                for i = 1:length(obj.Breaths)
                    if obj.Breaths(i).getAnalyzable()
                        RCI = [RCI; obj.Breaths(i).getRCI()];
                    end
                end
                
            else
                inds = varargin{1};
                for i = 1:length(inds)
                    if obj.Breaths(inds(i)).getAnalyzable()
                        RCI = [RCI; obj.Breaths(inds(i)).getRCI()];
                    end
                end
            end

            meanRCI = mean(RCI);
            sdRCI = std(RCI);
        end
        
        function [meanTTE, sdTTE] = calculateMeanTPEFTE(obj, varargin)
            TTE = [];
            if nargin == 1
                for i = 1:length(obj.Breaths)
                    if obj.Breaths(i).getAnalyzable()
                        TTE = [TTE; obj.Breaths(i).getTPEFTE()];
                    end
                end
                
            else
                inds = varargin{1};
                for i = 1:length(inds)
                    if obj.Breaths(inds(i)).getAnalyzable()
                        TTE = [TTE; obj.Breaths(inds(i)).getTPEFTE()];
                    end
                end
                
            end
            meanTTE = mean(TTE);
            sdTTE = std(TTE);
        end
        
        function [meanT, sdT] = calculateMeanDuration(obj, varargin)
            T = [];
            if nargin == 1
                for i = 1:length(obj.Breaths)
                    if obj.Breaths(i).getAnalyzable()
                        T = [T; obj.Breaths(i).getDuration()];
                    end
                end
                
            else
                inds = varargin{1};
                for i = 1:length(inds)
                    if obj.Breaths(inds(i)).getAnalyzable()
                        T = [T; obj.Breaths(inds(i)).getDuration()];
                    end
                end
            end
            
            meanT = mean(T);
            sdT = std(T);
                
        end
        
        function [meanRR, sdRR] =  calculateMeanRespiratoryRate(obj, varargin)
            RR = [];
            if nargin == 1
                for i = 1:length(obj.Breaths)
                    if obj.Breaths(i).getAnalyzable()
                        RR = [RR; 60/obj.Breaths(i).getDuration()];
                    end
                end
                
            else
                inds = varargin{1};
                for i = 1:length(inds)
                    if obj.Breaths(inds(i)).getAnalyzable()
                        RR = [RR; 60/obj.Breaths(inds(i)).getDuration()];
                    end
                end
            end
            
            meanRR = mean(RR);
            sdRR = std(RR);
                
        end
        
        function numAnalyzable = getNumberAnalyzable(obj)
            count = 0;
            for i = 1:length(obj.Breaths)
                if obj.Breaths(i).getAnalyzable()
                    count = count + 1;
                end
            end
           	numAnalyzable = count;
        end
        
        function indsAnalyzable = getIndicesAnalyzable(obj)
            indsAnalyzable = [];
            for i = 1:length(obj.Breaths)
                if obj.Breaths(i).getAnalyzable()
                    indsAnalyzable = [indsAnalyzable; i];
                end
            end
        end
        
        
        
            
    end
end
        
    
    