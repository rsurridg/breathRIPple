classdef Breath < handle
   properties (Access = private)
      % Properties are things an object (in this case a Breath) "has".
      % Private properties can only be accessed from within the class
      % (they're invisible from outside this file), meaning we need
      % "getter" functions to read them from the outside.
      
      % class properties should always be capitalized
      Data
      Number
      SamplingFreq
      StartIndex
      EndIndex
      Indices
      Length
      Duration
      Max
      MaxLocation
      
      DerivativePass = false;
      KMDistPass = false;
      KMCrossoverPass = false;
      QuietSleepPass = false;
      Analyzable = false;
      
      PhaseAngle = 0;
      TPEFTE = 0;
      RCI = 0;
      
      AssociatedData
      
      
   end
   
   methods
       % Methods are things an object "does"
       
       % This is a constructor method used to create the Breath
       % A constructor is the only method that should ever start with
       % "obj =" and every class needs one.
       % A good rule of a constructor is that it defines/"fills" every 
       % property of the class. Constructor methods must have the same 
       % name as the file (exactly) and should be capitalized. 
       % Methods other than the constructor should not be capitalized. 
       function obj = Breath(data, num, startIndex, metadata)
           obj.Number = num;
           obj.Data = data;
           obj.SamplingFreq = metadata.SamplingFrequency;
           obj.StartIndex = startIndex;
           obj.EndIndex = startIndex+length(data) - 1;
           obj.Indices = obj.StartIndex:obj.EndIndex;
           obj.Length = length(data);
           obj.Duration = obj.Length/obj.SamplingFreq;
           [M,I] = max(obj.Data);
           obj.Max = M;
           obj.MaxLocation = I; % this is relative to this breath
           
           obj.DerivativePass = obj.doDerivativeTest(obj.Data);
       end
       
       function num = getNumber(obj)
           num = obj.Number;
       end
       
      function startIndex = getStartIndex(obj)
          % This is a classic "getter" method. They're usually grouped
          % together and come right after the constructor.
          % Getter method names should always include "get" as the first
          % word.
           startIndex = obj.StartIndex;
      end
    
      function endIndex = getEndIndex(obj)
          endIndex = obj.EndIndex;
      end
      
      function indices = getIndices(obj)
          indices = obj.Indices;
      end
      
      function data = getData(obj)
          data = obj.Data;
      end
      
      function length = getLength(obj)
           length = obj.Length;
      end
      
      function duration = getDuration(obj)
           duration = obj.Duration;
      end
      
      function max = getMax(obj)
           max = obj.Max;
      end
      
      function maxLoc = getMaxLoc(obj)
           maxLoc = obj.MaxLocation;
      end 
      
      function tpefte = getTPEFTE(obj)
          tpefte = obj.TPEFTE; 
      end
      
      function pa = getPhaseAngle(obj)
          pa = obj.PhaseAngle;
      end
      
      function rci = getRCI(obj)
          rci = obj.RCI;
      end
      
      function pass = getDerivativePass(obj)
          pass = obj.DerivativePass;
      end
      
      function pass = getKMDistPass(obj)
          pass = obj.KMDistPass;
      end
      
      function pass = getKMCrossoverPass(obj)
          pass = obj.KMCrossoverPass;
      end
      
      function pass = getQuietSleepPass(obj)
          pass = obj.QuietSleepPass;
      end
      
      function analyzable = getAnalyzable(obj)
          analyzable = obj.Analyzable;
      end
      
      function associatedData = getAssociatedData(obj)
          associatedData = obj.AssociatedData;
      end
      
      %% SETTERS
      
      function obj = setAssociatedData(obj, data)
          obj.AssociatedData = data;
      end
          
      function obj = setPair(obj, pair)
          obj.Pair = pair;
      end
      
      function obj = setQuietSleepPass(obj, quiet)
          obj.QuietSleepPass = quiet;
      end
      
      function obj = setDerivativePass(obj, pass)
          obj.DerivativePass = pass;
      end
      
      function setKMDistancePass(obj, pass)
          obj.KMDistPass = pass;
      end
      
      function setKMCrossoverPass(obj, pass)
          obj.KMCrossoverPass = pass;
      end

      %% SETTERS
      
      function obj = setTPEFTE(obj, tpefte)
          obj.TPEFTE = tpefte;
      end
      
      function obj = setPhaseAngle(obj, pa)
          obj.PhaseAngle = pa;
      end
      
      function obj = setRCI(obj, rci)
          obj.RCI = rci;
      end
      
      function obj = evaluateAnalyzable(obj)
          if obj.DerivativePass && obj.KMDistPass && obj.KMCrossoverPass && obj.QuietSleepPass
              obj.Analyzable = true;
          else
              obj.Analyzable = false;
          end
          
      end
      
      function obj = overrideAnalyzable(obj, pass)
          obj.Analyzable = pass;
      end
          
      

      
      % After constructor and getters, we can get to special methods that are specific to our project.
      
      % Methods should only need what's available in this class (in
      % properties) to do their job. Generally, if we need more information for this method than is
      % available within this class, we need to take another look at code
      % structure, or the method belongs in a different class. 
      
      % Methods that are not a constructor or a getter should have a
      % comment right under the definition that explains what it does, and
      % non-obvious lines of code should also be commented.
      
      function pass = doDerivativeTest(obj, data)
          % The "visual" algorithm that examines the number of changes of
          % sign of the first derivative in a single breath
          
          transitions = 0;              % set initial value of zero first derivative transitions
          d1 = gradient(data);          % take first derivative of data
          for i = 50:1:obj.Length-50    % for middle section of data
              last_sign = d1(i-1)>0;    % get sign of previous point
              curr_sign = d1(i)>0;      % get sign of current point
              
              if last_sign ~= curr_sign % if these do not match
                  transitions = transitions + 1; % track a change in sign
              end
          end
          
          if transitions > 2            % if the sign changes more than twice
              pass = false;             % the breath fails the derivative test
          else
              pass = true;
          end
      end
      
      
      
   end
end