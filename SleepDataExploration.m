close all; clc;
% load('C:\Users\rache\OneDrive\Desktop\Senior Design\EDFSleepLab.mat')

CH = 33;
AB = 34;
start = 100000;
len = 300000;
end_i = start+len;
fs = 256;
t = (start:1:end_i)/fs;

% figure(1);
% subplot(2,1,1);
% plot(t, record1(CH, start:end_i));
% ylabel('CHEST');
% 
% subplot(2,1,2);
% plot(t, record1(AB, start:end_i));
% ylabel('ABD');

% Respiration rate < 25 bpm
fz = fs/2;
cutoff = 5; % Hz
Wn = cutoff/fz;
[B, A] = butter(3, Wn);

filtAB = filter(B, A, record1(AB, start:end_i));
filtCH = filter(B, A, record1(CH, start:end_i));

figure(2);
subplot(2,1,1)
hold on
plot(t, filtCH);
xlabel('Time (sec)');
ylabel('CHEST DATA');
axis([1614 1635 -400 300]);

subplot(2,1,2)
hold on
plot(t, filtAB);
xlabel('Time (sec)');
ylabel('ABD DATA');
axis([1614 1635 -600 600]);

[CHpks, locCH] = findpeaks(-filtCH,'MinPeakProminence',30,'MinPeakDistance',0.5*fs);
[ABpks, locAB] = findpeaks(-filtAB, 'MinPeakProminence',150,'MinPeakDistance',0.5*fs);
CHpks = -CHpks;
ABpks = -ABpks;

locCH_corr = (locCH+start)/fs;
locAB_corr = (locAB+start)/fs;

subplot(2,1,1)
plot(locCH_corr, CHpks, 'o');

subplot(2,1,2)
plot(locAB_corr, ABpks, 'o');

%% PAIR PEAKS
% for each abdominal minima
% find the next one. Find the duration. Find the maximum between those two points.
% Look for a chest maximum less than 180* away.
% If there are more than one, take the closest. 
% If they're approximately equidistant, take the most prominent?

n = length(ABpks)-1;
ABDBreaths = struct('StartIndex', zeros(n,1),...
    'EndIndex', zeros(n,1), ...
    'Duration', zeros(n,1), ...
    'Max', zeros(n,1), ...
    'MaxLocationRel', zeros(n,1));

for i = 1:1:length(ABpks)-1
    ABDBreaths.StartIndex(i) = locAB(i);
    ABDBreaths.EndIndex(i) = locAB(i+1);
    ABDBreaths.Length(i) = ABDBreaths.EndIndex(i) - ABDBreaths.StartIndex(i);
    ABDBreaths.Duration(i) = ABDBreaths.Length(i)/fs;
    [M, I] = max(filtAB(ABDBreaths.StartIndex(i):ABDBreaths.EndIndex(i)));
    ABDBreaths.Max(i) = M;
    ABDBreaths.MaxLocationRel(i) = I;
end

subplot(2,1,2)
xdata = (ABDBreaths.StartIndex + ABDBreaths.MaxLocationRel + start)/fs;
plot(xdata, ABDBreaths.Max,'o')

d1ABD = gradient(filtAB);
d2ABD = gradient(d1ABD);

%% SECOND DERIVATIVE PLOT
figure();
hold on;
title('Second Derivative of Filtered ABD Data');
xdata = 1:1:length(filtAB);
plot(xdata, filtAB);
positive = (d2ABD > 0);
negative = (d2ABD < 0);
plot(xdata(positive), 1000*d2ABD(positive), '.g');
plot(xdata(negative), 1000*d2ABD(negative), '.r');
legend('Raw','2nd Derivative');

%% SORT BASED ON NUMBER OF SECOND DERIVATIVE TRANSITIONS
transitions_d1 = zeros(size(ABDBreaths.StartIndex));
transitions_d2 = zeros(size(ABDBreaths.StartIndex));

for i = 1:1:length(ABDBreaths.StartIndex)
    d1 = d1ABD(ABDBreaths.StartIndex(i):ABDBreaths.EndIndex(i));
    d2 = d2ABD(ABDBreaths.StartIndex(i):ABDBreaths.EndIndex(i));
    
    fz = fs/2;
    cutoff = 10; % Hz
    Wn = cutoff/fz;
    [B, A] = butter(3, Wn);

    d2 = filter(B, A, d2);

    for j = 10:1:length(d2)-10
        
        last_sign_d2 = d2(j-1)>0;
        curr_sign_d2 = d2(j)>0;
        
        if last_sign_d2 ~= curr_sign_d2
            transitions_d2(i) = transitions_d2(i) + 1;
        end
            
    end
    
    for j = 10:1:length(d1)-10
        last_sign_d1 = d1(j-1)>0;
        curr_sign_d1 = d1(j)>0;
        
        if last_sign_d1 ~= curr_sign_d1
            transitions_d1(i) = transitions_d1(i) + 1;
        end
        
    end
    
    if transitions_d2(i) > 10 || transitions_d1(i) > 2
        ABDBreaths.Analyzable(i) = false;
    else
        ABDBreaths.Analyzable(i) = true;
    end
    
end

fprintf('%d \t %d \n', transitions_d1, transitions_d2);
              
%% SORT BASED ON PERCENTAGE POSITIVE OF SECOND DERIVATIVE
% for i = 1:1:length(ABDBreaths.StartIndex)
%     d2 = d2ABD(ABDBreaths.StartIndex(i):ABDBreaths.EndIndex(i));
%     d2Neg = d2<0; % logical index
%     if sum(d2Neg)/ABDBreaths.Length(i) > 0.50
%         ABDBreaths.Analyzable(i) = true;
%     else
%         ABDBreaths.Analyzable(i) = false;
%     end
% end

%'Color', '#D95319' 
%'Color', 	'#0072BD',
figure()
hold on
for i = 1:1:length(ABDBreaths.StartIndex)
     xdata = ABDBreaths.StartIndex(i):ABDBreaths.EndIndex(i);
     if ABDBreaths.Analyzable(i)
         plot(xdata, filtAB(xdata), 'Color','#0072BD');
     else
         plot(xdata, filtAB(xdata), 'Color', '#D95319');
     end
%     %label = int2str(i);
%     label = int2str(transitions_d1(i)) + ", " + int2str(transitions_d2(i));
%     xline(ABDBreaths.StartIndex(i),':', label);
end
 title('Analyzable vs Non-Analyzable Breaths');
 ylabel('ABD Data');
 %axis([ABDBreaths.StartIndex(1) ABDBreaths.StartIndex(1) + 5000 min(filtAB) max(filtAB)])
%         






