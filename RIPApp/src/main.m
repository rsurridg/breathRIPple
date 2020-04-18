% clear all;
clc;
close all;
file = "C:\Users\rache\OneDrive\Desktop\SeniorDesignData\0510014.csv";
%data = importBioRadioCSV(file);



seconds = second(data.ElapsedTime);
diffSeconds = diff(seconds);
diffSeconds = diffSeconds(~isnan(diffSeconds));
modeDiff = mode(diffSeconds);

metadata.SamplingFrequency = round(1/modeDiff);
metadata.SignalUnits = 'mV';
metadata.SleepStatus = [];

start = 33.5*60*metadata.SamplingFrequency; 
len = length(data.AB); %2*60*metadata.SamplingFrequency; % length must not exceed size of data

end_i = start+len-1;

ABRawData = -data.AB(start:end);
CHRawData = -data.RC(start:end);


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


