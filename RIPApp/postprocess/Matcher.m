classdef Matcher 
   %MATCHER class is responsible for associating corresponding AB data with
   %specific, individual breaths identified in the dominant CH recording.
    
   properties (Access = private)
       CHRecording
   end
   
   methods
       function obj = Matcher(CHdata)
           obj.CHRecording = CHdata;
       end
       
       function updatedCHRecording = alignBreaths(obj)
           
            ABdata = obj.CHRecording.getAssociatedData();
            
            for i = 1:obj.CHRecording.getNumBreaths() % for each breath in dominant recording
               breath = obj.CHRecording.getBreath(i); % get breath 
               sInd = breath.getStartIndex(); % find start index and end index of breath
               eInd = breath.getEndIndex();
               ABdata_sub = ABdata(sInd:eInd);
               obj.CHRecording.setAssociatedData(i, ABdata_sub); % get associated data from filtered AB trace
           end   

           updatedCHRecording = obj.CHRecording;
       end
       

   end
end
       
       
