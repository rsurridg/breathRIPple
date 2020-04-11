% clear all;
clc;
close all;
file = "C:\Users\rache\OneDrive\Desktop\SeniorDesignData\071411.csv";
data = importBioRadioCSV(file);
% 
ts1 = second(data.ElapsedTime(2));
ts2 = second(data.ElapsedTime(3));

metadata.SamplingFrequency = 1/(round((ts2-ts1), 3)); % convert from msec to sec
metadata.SignalUnits = 'mV';
metadata.SleepStatus = [0 length(data.RC)/metadata.SamplingFrequency];

start = 1;%27.5*60*metadata.SamplingFrequency; 
len = length(data.AB); %2*60*metadata.SamplingFrequency; % length must not exceed size of data

end_i = start+len-1;

ABRawData = -data.AB(start:end_i);
CHRawData = -data.RC(start:end_i);


%ABData = ABDRecording(ABRawData, metadata); 
CHBandRecording = BandRecording(CHRawData, ABRawData, metadata);

%% NEWKM
matcher = Matcher(CHBandRecording);
CHBandRecording = matcher.alignBreaths();

sorter = Sorter(CHBandRecording);
CHBandRecording = sorter.sortBreaths();

analyzer = Analyzer(CHBandRecording);
CHBandRecording = analyzer.calculateParameters();

analysisApp = analysisScreen2(CHBandRecording);


