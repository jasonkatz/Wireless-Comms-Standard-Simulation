% ECE-408 Project 1
% Jessica Marshall, Elie Lerea and Jason Katz - Team Shabbaton
% 802.11n Specification Implementation

%% Simulation Setup

clear all; clear global; clc; close all;
dbstop if error;

% Sampling freq for specgram
Fs = 120e4;
totalV = [];
msgM = 2; % Use BPSK
k = log2(msgM);
numTx = 2;
numRx = 2;
nSyms = 1e3; % Symbols per OFDM channel

% Change this value to toggle SISO or MIMO implementation
isSISO = 1;

numIter = 10;

SNR_Vec = 0:2:16;

% Create a vector to store the BER computed during each iteration
berVec = zeros(numIter, length(SNR_Vec));

for index = 1:length(SNR_Vec)
    berTotal = 0;
    
    for i = 1:numIter

        %% Transmitter Implementation

        numChannels = 56; % Number of OFDM subcarrier channels

        % Generate data (4096 - 16 channels ; 2048 - 8 channels ; 1024 - 4 channels
        bits = randi([0 1],numChannels * k * nSyms, 1); % Generate random bits, pass these out of function, unchanged

        % Rate 1/2 convolutional encode
        trellis = struct('numInputSymbols',2,'numOutputSymbols',4,...
        'numStates',4,'nextStates',[0 2;0 2;1 3;1 3],...
        'outputs',[0 3;1 2;3 0;2 1]);
        code = convenc(bits, trellis, 0); % Encode bits

        % Convert to symbols
        syms = bi2de(reshape(code,k,length(code)/k).','left-msb')';

        % Random msgM-QAM Signal
        msg = qammod(syms, msgM);

        % Break up message into two parts
        msgTx1 = msg(1, 1:(length(msg) / 2));
        msgTx2 = msg(1, (length(msg) / 2 + 1):length(msg));
        msgTx1 = reshape(msgTx1, numChannels, length(msgTx1) / numChannels).';
        msgTx2 = reshape(msgTx2, numChannels, length(msgTx2) / numChannels).';

        msg1Full = [zeros(nSyms, 4) msgTx1(:, [1:numChannels]) zeros(nSyms, 4)];
        msg2Full = [zeros(nSyms, 4) msgTx2(:, [1:numChannels]) zeros(nSyms, 4)];

        % Use ifft to get orthogonal frequency vectors for OFDM
        msg1OFDM = ifft(msg1Full.').';
        msg2OFDM = ifft(msg2Full.').';

        % Add cyclic prefix
        msg1OFDM = [msg1OFDM(:,[49:64]) msg1OFDM];
        msg2OFDM = [msg2OFDM(:,[49:64]) msg2OFDM];

        % Reshape
        tx1 = reshape(msg1OFDM, 1, nSyms * 80);
        tx2 = reshape(msg2OFDM, 1, nSyms * 80);
        tx = [tx1 ; tx2];

        gain = std(tx');
        tx = [tx(1, :) / gain(1) ; tx(2, :) / gain(2)];
        
        sig = tx;
        
        %% Create channel and send data
        
        % Create 2x2 matrix representing MIMO channels
        chan = 1/sqrt(2)*[randn(numRx, numTx) + j*randn(numRx, numTx)];
        
        % Change the channel based on whether we use SISO or MIMO
        if isSISO
            chan = eye(2);
        end
        
        % Filter data through channels and add noise
        sigChan = chan * sig * sqrt(80/64);
        sigNoisy = awgn(sigChan, SNR_Vec(index) + 10*log10(k), 'measured');
        
        %% Receiver Implementation
        
        rx = sigNoisy;

        % Invert the channel and filter
        chanInv = pinv(chan);
        rxFiltered = chanInv * rx;

        % Split up signal
        rxPart1 = rxFiltered(1, :);
        rxPart1 = reshape(rxPart1, nSyms, 80);
        rxPart2 = rxFiltered(2, :);
        rxPart2 = reshape(rxPart2, nSyms, 80);

        % Remove cyclic prefix
        rxPart1 = rxPart1(:,[17:80]);
        rxPart2 = rxPart2(:,[17:80]);

        % Inverse OFDM
        rxOFDM1 = fft(rxPart1.').';
        rxOFDM2 = fft(rxPart2.').';
        % Correct roundoff error in OFDM
        rxOFDM1 = round(rxOFDM1);
        rxOFDM2 = round(rxOFDM2);

        % Get rid of zero columns and reshape
        rx1 = rxOFDM1(:, [5:60]);
        rx2 = rxOFDM2(:, [5:60]);
        rx1 = reshape(rx1.', 1, numChannels * nSyms);
        rx2 = reshape(rx2.', 1, numChannels * nSyms);

        % Combine vectors
        rxMsg = [rx1 rx2];

        % QAM demod
        rxMsg = qamdemod(rxMsg, msgM);

        % Map Symbols to Bits
        rx1 = de2bi(rxMsg,'left-msb');
        rxBits = reshape(rx1.',numel(rx1),1);

        % Rate 1/2 convolution decode
        rxBits = vitdec(rxBits, trellis, 10, 'trunc', 'hard');

        % Check the BER. If zero BER, output the # of correctly received bits.
        [zzz ber] = biterr(rxBits, bits);
        
        berTotal = berTotal + ber;

        %% Results Generation
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



