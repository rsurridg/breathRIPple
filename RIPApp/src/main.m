% clear all;
clc;
close all;
file = "C:\Users\rache\OneDrive\Desktop\SeniorDesignData\510022.csv";
data = importBioRadioCSV(file);

seconds = second(data.ElapsedTime);
diffSeconds = diff(seconds);
diffSeconds = diffSeconds(~isnan(diffSeconds));
modeDiff = mode(diffSeconds);

metadata.SamplingFrequency = round(1/modeDiff);
metadata.SignalUnits = 'mV';
metadata.SleepStatus = [];

start = 1; %39*60*metadata.SamplingFrequency; 
%len = length(data.AB); %2*60*metadata.SamplingFrequency; % length must not exceed size of data

end_i = 21.5*60*metadata.SamplingFrequency;

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


