classdef Sorter
    %SORTER class is responsible for sorting analyzable from unanalyzable
    %breaths. This includes analysis of first derivative, Konno-Mead plot
    %crossover and gap distance.
    
    properties
       CHRecording
    end
    
    methods
        function obj = Sorter(CHdata)
           obj.CHRecording = CHdata;
        end
        
        
        %% NEW KM
        function updatedCHData = sortBreaths(obj)
            % this algorithm checks KM distance and KM crossover for each
            % pair and returns the paired indices of breaths which pass both
            % tests
            
            for breathNum = 1:obj.CHRecording.getNumBreaths()
                breath = obj.CHRecording.getBreath(breathNum);
                
                if breath.getDerivativePass() && breath.getQuietSleepPass()
                    breathData = breath.getData();
                    associatedData = breath.getAssociatedData();
                
                    passDist = obj.distKonnoMeade(breathData, associatedData); % see if konno-meade separation is good
                
                    if passDist % if konno-meade separation is acceptable
                        obj.CHRecording.setKMDistPass(breathNum, true);
                    
                        passCrossover = obj.konnoMeadeCrossover(breathData, associatedData); % check if KM crossover occurs
                    
                        if passCrossover % if KM crossover does not occur
                            obj.CHRecording.setKMCrossoverPass(breathNum, true);
                        else
                            obj.CHRecording.setKMCrossoverPass(breathNum, false);
                        end
                    
                    else
                        obj.CHRecording.setKMDistPass(breathNum, false);
                    end
                end
            end
            
            obj.CHRecording.evaluateAnalyzable();
            
            updatedCHData = obj.CHRecording;
            
        end
        
        function pass = distKonnoMeade(obj, breathData, associatedData)
            % This function checks the distance between the beginning and
            % end point of the KM plot and passes or fails the pair based
            % on the threshold.
            
            % Thresholds are a percentage of maximum excursion
            threshold = 0.30;
            
            dist1 = abs(breathData(end) - breathData(1)); % calculate length of gap in x-direction
            dist2 = abs(associatedData(end) - associatedData(1)); % calculate length of gap in y-direction
            
            maxDist1 = abs(max(breathData) - min(breathData)); % calculate total excursion in x-direction
            maxDist2 = abs(max(associatedData) - min(associatedData)); % calculate total excursion in y-direction
            
            if (dist1 < threshold*maxDist1)... % if x-gap is less than threshold
                    && (dist2 < threshold*maxDist2) % AND if y-gap is less than threshold
                pass = true;
            else
                pass = false;
            end
            
         end
        
         function pass = konnoMeadeCrossover(obj, CHdata, ABdata)
            midpoint = floor(length(CHdata)/2);
            
            x1 = ABdata(1:midpoint);
            x2 = ABdata(midpoint+1:end);
            y1 = CHdata(1:midpoint);
            y2 = CHdata(midpoint+1:end);
            
            [X0,~] = intersections(x1,y1,x2,y2);
            
            if isempty(X0)
                pass = true;
            else
                pass = false;
            end
            
        end
            
           
    end
end

