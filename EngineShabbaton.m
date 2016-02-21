clear all; clear global; clc; close all;
dbstop if error;
noiseLevel  =  randi([0 20]);

% Sampling freq for specgram
Fs = 120e4;
sumForSpec = [];
totalV = [];

numIter = 10;

% Create a vector to store the BER computed during each iteration
berVec = zeros(numIter, length(noiseLevel));

for index = 0:20
    noiseLevel = index;
    total = 0;
    
for i = 1:numIter
    
    % Transmitters
    
    [sig, bits, gain] = txShabbaton();
    
    sumNoisy = awgn(sig, noiseLevel, 1);
 
    
    % append;
    sumForSpec =  [sumForSpec, sumNoisy];
    
    
    % check the BER
    total = total + rxShabbaton(sumNoisy,bits, gain);
end

noiseLevel
[total1, total2]
%spectrogram(sumForSpec,64,[],[],Fs,'yaxis')

totalV = [totalV total2];
end

plot([0:20], totalV);




