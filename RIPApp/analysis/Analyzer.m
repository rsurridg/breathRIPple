classdef Analyzer
    %ANALYZER class is responsible for performing quantitative diagnostic
    %calibration and calculating phase angle, Tpef/TE and %RCi for each
    %breath
    
    properties (Access = private)
       CHRecording
       KValue
    end
    
    methods
        function obj = Analyzer(CHdata)
           obj.CHRecording = CHdata;
           obj.KValue = obj.calculateKValue();
        end
        
        %% NEW KM
        function K = calculateKValue(obj)
            
            [startIndex, endIndex, breathNums] = obj.findBestRange(); % find subset of data with greatest concentration of analyzable breaths
            
            uAB = obj.CHRecording.getAssociatedData();
            uAB = uAB(startIndex:endIndex);
            
            uCH = obj.CHRecording.getRawData();
            uCH = uCH(startIndex:endIndex);
            TV = uAB + uCH;
            
            meanSum = mean(TV);
            stdSum = std(TV);
            
            stdScale = 1.5;
            
%             figure()
%             hold on;
%             plot(TV);
%             yline(meanSum + stdScale*stdSum);
%             yline(meanSum - stdScale*stdSum);
            
            subsetAB = [];
            subsetCH = [];
            countGood = 0;
            for i = breathNums(1):breathNums(end)
                breath = obj.CHRecording.getBreath(i);
                CHdata = breath.getData();
                ABdata = breath.getAssociatedData();
                TVdata = CHdata+ABdata;
                if any(TVdata > (meanSum + stdScale*stdSum)) ...
                        || any(TVdata < (meanSum - stdScale*stdSum))
                    % exclude breath from QDC
                else
                    countGood = countGood + 1;
                    subsetAB = [subsetAB; ABdata(:)];
                    subsetCH = [subsetCH; CHdata(:)];
                end
            end   
            
            
            K = std(subsetAB)/std(subsetCH);  
            
            metadata = obj.CHRecording.getMetadata();
            
            obj.CHRecording.setQDCReport(['\nQDC Report \nK = ' num2str(K,4)...
                '\nPeriod: ' num2str(startIndex/metadata.SamplingFrequency) ' - ' num2str(endIndex/metadata.SamplingFrequency) ' sec' ...
                '\nSD Used for Elimination of Abnormal Breaths: ' num2str(stdScale)...
                '\nNumber of Breaths Used: ' num2str(countGood) ' (out of ' num2str(length(breathNums)) ')\n']);
            
        end
        
        function [sInd, eInd, breaths] = findBestRange(obj)
            
            goodBreaths = obj.CHRecording.getIndicesAnalyzable();
            [meanDuration, ~] = obj.CHRecording.calculateMeanDuration();
            breathsPer5Min = floor(60/meanDuration*5);
            
            numSubsets = floor(obj.CHRecording.getNumBreaths()/breathsPer5Min);
            if numSubsets > 0 % if more than five minutes in the data
            
                startBreath = (1:numSubsets+1).* breathsPer5Min;
                for i = 1:numSubsets
                    breathsConsidered{i} = startBreath(i):startBreath(i+1);
                    common(i) = length(intersect(goodBreaths, breathsConsidered{i}));
                end

                [~, maxInd] = max(common);

                breaths = breathsConsidered{maxInd};
                startBreath = obj.CHRecording.getBreath(breaths(1));
                endBreath = obj.CHRecording.getBreath(breaths(end));
                sInd = startBreath.getStartIndex();
                eInd = endBreath.getEndIndex();
            else
                % Use entire dataset for QDC
                sInd = 1;
                eInd = obj.CHRecording.getLength();
                breaths = 1:obj.CHRecording.getNumBreaths();
            end
            
        end
        
        function updatedCHData = calculateParameters(obj)
            
            for breathNum = 1:obj.CHRecording.getNumBreaths()
                breath = obj.CHRecording.getBreath(breathNum);
                if breath.getAnalyzable()
                    PA = obj.calculatePA(breath);
                    TTE = obj.calculateTPEFTE(breath);
                    RCI = obj.calculateRCI(breath);
                    
                    obj.CHRecording.setBreathParameters(breathNum, PA, TTE, RCI);
                end
                
                updatedCHData = obj.CHRecording;
            end
        end
        
        function PA = calculatePA(obj, breath)
            CHdata = breath.getData();
            ABdata = breath.getAssociatedData();
                
            meanRC = mean(CHdata);
%             figure();
%             hold on;
%             plot(ABdata, CHdata);
%             yline(meanRC);
%             plot(ABdata(1), CHdata(1), '*');
%             
            
            try
                i = 1;
                while CHdata(i) < meanRC
                    i = i + 1;
                end
                chordStart = ABdata(i);
                while CHdata(i) > meanRC
                    i = i + 1;
                end
                chordEnd = ABdata(i);
                m = abs(chordStart - chordEnd);
                s = abs(max(ABdata) - min(ABdata));
                
                if ABdata(floor(length(ABdata)/2)) > ABdata(1)
                    % positive slope
                    PA = asind(m/s); 
                else
                    PA = 180 - asind(m/s);
                end
                    
            catch
                % loop didn't close enough to get below mean, breath not analyzable
                breathNum = breath.getNumber();
                obj.CHRecording.overrideAnalyzable(breathNum, false);
                PA = 0;
            end
        end
        
        function TPEFTE = calculateTPEFTE(obj, breath)
            CHdata = breath.getData();
            ABdata = breath.getAssociatedData();
            TV = obj.KValue*CHdata + ABdata;
            flow = gradient(TV);
            
%             figure();
%             hold on;
%             plot(flow);
%             yline(0);
            
            % find peak of inspiration
            midpoint = floor(length(flow)/2);
            [maxFlow, maxFlowInd] = max(flow(1:midpoint));

            % find crossover from inspiration to expiration
            if maxFlow <= min(flow(midpoint:end))
                % this is an abnormal waveform that does not represent
                % inspiration followed by expiration and should be
                % discarded
                breathNum = breath.getNumber();
                obj.CHRecording.overrideAnalyzable(breathNum, false);
                TPEFTE = 0;
            else
                i = maxFlowInd;
                while flow(i) > 0
                    i = i+1;
                end

                expStart = i;

                try % if flow rises up back past zero, find the point where it crosses zero again
                    while flow(i) < 0
                        i = i + 1;
                    end
                catch % otherwise, take the last index of the flow
                    i = length(flow);
                end

                expEnd = i;

                %plot(expStart, flow(expStart), '*');
                %plot(expEnd, flow(expEnd), '*');

                expiration_subset = flow(expStart:expEnd);
                [~, numerator] = min(expiration_subset);

                denominator = length(expiration_subset);
                TPEFTE = numerator/denominator;
            end
        end
        
        function RCI = calculateRCI(obj, breath)
            ABdata = breath.getAssociatedData();
            CHdata = obj.KValue.*breath.getData();
            TV = CHdata + ABdata;
            
            ABdata = ABdata - ABdata(1);
            CHdata = CHdata - CHdata(1);
            TV = TV - TV(1);
            
%             figure();
%             hold on;
%             plot(TV);
%             plot(CHdata);
%             plot(ABdata);
            
            [maxTV, maxTVind] = max(TV);
%             plot(maxTVind, maxTV, '*');
%             
%             yline(maxTV);
%             yline(min(TV));
%             yline(max(CHdata));
%             yline(min(CHdata));
%             
%             legend('Tidal', 'Rib Cage', 'Abdomen');
            
            numerator = abs(CHdata(maxTVind)-min(CHdata));
            denominator = abs(maxTV - min(TV));
%             numerator = trapz(CHdata(1:maxTVind));
%             denominator = trapz(TV(1:maxTVind));
            
            RCI = numerator/denominator;
            
            if isnan(RCI)
                % max TV was the first point of the waveform
                % the breath is abnormal and unfit for analysis
                breathNum = breath.getNumber();
                obj.CHRecording.overrideAnalyzable(breathNum, false);
                RCI = 0;
            end

        end
        
                
    end
end

