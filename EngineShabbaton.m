clear all; clear global; clc; close all;
dbstop if error;

% Sampling freq for specgram
Fs = 120e4;
totalV = [];
msgM = 8; % Use BPSK
k = log2(msgM);
numTx = 2;
numRx = 2;
nSyms = 1e3; % Symbols per OFDM channel

numIter = 10;

SNR_Vec = 0:2:16;

% Create a vector to store the BER computed during each iteration
berVec = zeros(numIter, length(SNR_Vec));

for index = 1:length(SNR_Vec)
    berTotal = 0;
    
    for i = 1:numIter

        % Get transmitted signal
        [sig, bits, gain] = txShabbaton(msgM, nSyms);
        
        % Create 2x2 matrix representing MIMO channels
        chan = 1/sqrt(2)*[randn(numRx, numTx) + j*randn(numRx, numTx)];
        
        % Filter data through channels and add noise
        sigChan = chan * sig * sqrt(80/64);
        sigNoisy = awgn(sigChan, SNR_Vec(index) + 10*log10(k), 'measured');

        % check the BER
        berTotal = berTotal + rxShabbaton(sig, bits, nSyms, msgM, chan);
    end
    
    berAvg = berTotal / numIter;
    
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



