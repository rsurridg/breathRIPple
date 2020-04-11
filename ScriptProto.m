%% Software Prototype
% hey i'm changing a thing
% changing another thing
% changing a third thing from alt
% Data Collection Module
% 1. Find device
    % should occur automatically on app launch
% 2. Connect device
    % Drop down menu in GUI should display available BioRadios. Select desired device 
    % and hit connect button. GUI should give a connection successful or connection failure
    % indicator.
% 3. Stream data 
    % "Start Collection" button below connection section.
    % When pressed, GUI should begin plotting data on live axes. Needs to update no more
    % than every 0.08 seconds (buffer refresh rate). 
  % 3. a
    % A toggle/radio button array below live plot will allow physician to
    % dynamically toggle sleep state ("Restful, Restless, Transitional"?).
    % Time stamp of toggle will be recorded. Perhaps background color of
    % axes can reflect current sleep state. A toggle would be better for us
    % as algorithm developers because meaning is known. Meaning of text box
    % annotations are unknown and must be interpreted.
    
% 4. Stop streaming
    % "Stop Collection" button below "Start Collection" button.
    % When pressed, live plot should pause. If data has been collected, 
    % modal dialogue should pop-up with three options:
    %   a. Export Raw Data Without Analysis
    %   b. Analyze Data
    %   c. Clear Without Saving
    
%% Analysis Module
%hi 
% 1. Filter data
    % Run chest and abdomen through butterworth filter with cutoff < 5Hz
    
% 2. Segmentation algorithm
    % Segment each breath waveform
    % Yields: beginning and end index for each breath waveform
    
    % 2.a Create Breaths structure
        % Breaths.startIndex
        % Breaths.stopIndex
        % Breaths.Valid
        % Breaths.TpefTe
        % Breaths.PA
        % Breaths.RCi
        % Breaths.Duration
        
% 3. Exclude invalid breaths
    % Use Sleep State information to exclude breaths
    % that do not begin AND end when sleep state == restful
    
    % For remaining breaths, do a Konno-Meade plot (CH vs ABD)
    % If 
        % a. Distance between beginning and end points > x% of total
        % excursion
        % OR
        % b. Waveform crosses itself at any point
        % Exclude breath
        
        % If Konno-Meade plot indicates validity,
        % calculate phase angle. 
            % theta = asin(m/s) where m = horzontal chord at mean RC excursion
            % and s = horizontal chord at max AB excursion
        
    % Exclude breath by setting Valid = 0
    
% For valid breaths:
% 4. Calculate Tpef/Te ((peak-startIndex)/duration)
% 5. RCi (ask Dr. Ren for clarification - requires quantitative diagnostic
% calibration?)

% 6. Calculate respiratory rate
    % Using durations

% Generate Report
    % Mean RR, RCi, PA, and Tpef/Te
    