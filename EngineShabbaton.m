clear all; clear global; clc; close all;
dbstop if error;

% Sampling freq for specgram
Fs = 120e4;
sumForSpec = [];
totalV = [];
msgM = 2; % Use BPSK
k = log2(msgM);

numIter = 10;

SNR_Vec = 0:2:16;

% Create a vector to store the BER computed during each iteration
berVec = zeros(numIter, length(SNR_Vec));

for index = 1:length(SNR_Vec)
    berTotal = 0;
    
    for i = 1:numIter

        % Transmitters

        [sig, bits, gain] = txShabbaton(msgM);

        sumNoisy = awgn(sig, SNR_Vec(index) + 10*log10(k), 'measured');

        % append;
        sumForSpec =  [sumForSpec, sumNoisy];


        % check the BER
        berTotal = berTotal + rxShabbaton(sumNoisy, bits, gain, msgM);
    end
    
    berAvg = berTotal / numIter;
    
    %spectrogram(sumForSpec,64,[],[],Fs,'yaxis')

    totalV = [totalV berAvg];
end

if msgM == 2
    berTheory = berawgn(SNR_Vec,'psk',2,'nondiff');
else
    berTheory = berawgn(SNR_Vec, 'qam', msgM);
end

semilogy(SNR_Vec, totalV)

hold on
semilogy(SNR_Vec,berTheory,'r')
legend('BER','Theoretical BER')
xlabel('SNR');



