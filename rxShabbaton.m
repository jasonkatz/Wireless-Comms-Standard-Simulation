function [numCorrect] = rxShabbaton(sig, bits, gain)
% ECE-300 Project 1 - Receiver
% Jessica Marshall, Elie Lerea and Jason Katz - Team Shabbaton
% Uses turbocoding and OFDM to receive the data
% At lower SNR, fewer channels are used

% DO NOT TOUCH BELOW
fsep = 8e4;
nsamp = 16;
Fs = 120e4;
M = 16;
%M = 4; fsep = 8; nsamp = 8; Fs = 32;

% THE ABOVE CODE IS PURE EVIL

numCorrect = 0; % initialize the # of correct Rx bits

% Global variable for feedback
global feedbackShabbaton;
uint8(feedbackShabbaton);

%% I don't recommend touching the code below
% Generate a carrier

msgCode = [];

numChannels = feedbackShabbaton;

%spectrogram(sig);

% Downconvert the signal down to baseband
tonecoeff = 0;
carrier = fskmod(tonecoeff*ones(1,1024),M,fsep,nsamp,Fs);
rx = sig.*conj(carrier);

% Downsample for cases where numChannels isn't 16
rx = intdump(rx, 16 / numChannels);

%% Recover your signal here

% Convert to properly sized matrix
rx = reshape(rx, numChannels, length(rx)/numChannels);

% Use fft to get data back using OFDM
rx = fft(rx, numChannels);

% Convert to column vector
rx = rx(:);

% Demod 4-QAM
rxMsg = qamdemod(rx,4);

% Map Symbols to Bits
rx1 = de2bi(rxMsg,'left-msb');
rx2 = reshape(rx1.',numel(rx1),1);

%% TURBO DECODEEEE

% Remove padded zeros
if numChannels == 16
    rx2 = rx2(1:(length(rx2) - 12270));
elseif numChannels == 8
    rx2 = rx2(1:(length(rx2) - 6126));
elseif numChannels == 4
    rx2 = rx2(1:(length(rx2) - 3054));
end

load('interleaverIndices.mat'); % Load indices
% Only take what we need based on the channels we're using
if numChannels == 16
    intrlvrIndices = intrlvrIndices4096;
elseif numChannels == 8
    intrlvrIndices = intrlvrIndices2048;
elseif numChannels == 4
    intrlvrIndices = intrlvrIndices1024;
end

% Create decoder
hTDec = comm.TurboDecoder('TrellisStructure',poly2trellis(4, ...
    [13 15 17],13),'InterleaverIndices',intrlvrIndices, ...
    'NumIterations',4);

% Decode bits
rxBits = step(hTDec,rx2);

% Check the BER. If zero BER, output the # of correctly received bits.
ber = biterr(rxBits, bits);

%rxBits == bits

if ber == 0
    disp('Sucessful frame User 2')
    numCorrect = length(bits);
else 
   %scatterplot(rx); 
end


% set the new value for the feedback here
% Use feedback to give the transmitter the SNR
totalPower = norm(sig);
if totalPower < 207
    feedbackShabbaton = 16;
elseif totalPower > 194
    feedbackShabbaton = 4;
else
    feedbackShabbaton = 8;
end

end