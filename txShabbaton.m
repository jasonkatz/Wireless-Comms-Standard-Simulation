function [tx, bits, gain] = txShabbaton()
% ECE-300 Project 1 - Transmitter
% Jessica Marshall, Elie Lerea and Jason Katz - Team Shabbaton
% Uses turbocoding and OFDM to transmit the data
% At lower SNR, fewer channels are used

% Your team will be assigned a number, rename your function txNUM.m
% Also rename the global variable tofeedbackNUM

% Global variable for feedback
% you may use the following uint8 for whatever feedback purposes you want
global feedbackShabbaton;
uint8(feedbackShabbaton);

% DO NOT TOUCH BELOW
fsep = 8e4;
nsamp = 16;
Fs = 120e4;
M = 16;   % THIS IS THE M-ARY # for the FSK MOD.  You have 16 channels available
% THE ABOVE CODE IS PURE EVIL

% initialize, will be set by rx after 1st transmission
if isempty(feedbackShabbaton) || feedbackShabbaton == 0
    feedbackShabbaton = 16;
    stateVal = 0;
end

%% You should edit the code starting here

numChannels = feedbackShabbaton;

msgM = 4; % Select 4 QAM for my message signal
k = log2(msgM);

% Generate data (4096 - 16 channels ; 2048 - 8 channels ; 1024 - 4 channels
bits = randi([0 1],128 * numChannels * k,1); % Generate random bits, pass these out of function, unchanged

%% TURBO CODEEEEE

load('interleaverIndices.mat'); % Load indices
% Only use what we need based on the number of channels we're using
if numChannels == 16
    intrlvrIndices = intrlvrIndices4096;
elseif numChannels == 8
    intrlvrIndices = intrlvrIndices2048;
elseif numChannels == 4
    intrlvrIndices = intrlvrIndices1024;
end

% Create encoder
hTEnc = comm.TurboEncoder('TrellisStructure',poly2trellis(4, ...
    [13 15 17],13),'InterleaverIndices',intrlvrIndices);

% Encode bits and pad zeroes so we have the correct amount
code = step(hTEnc,bits);
zeroPad = zeros(2^nextpow2(length(code)) - length(code), 1);
padLength = length(zeroPad);
code = [code' zeroPad']';

% Convert to symbols
syms = bi2de(reshape(code,k,length(code)/k).','left-msb')';

% Random 4-QAM Signal
msg = qammod(syms,4);

% Check length
msglength = length(msg);
if(msglength ~= numChannels * 1024)
    error('You smurfed up')
end

tonecoeff = 0;

% Interleave 1024 symbols per channel
msg = reshape(msg, numChannels, msglength/numChannels);

%% You should stop editing code starting here

%% Serioulsy, Stop.

% Generate a carrier
% don't mess with this code either, just pick a tonecoeff above from 0-15.
carrier = fskmod(tonecoeff*ones(1,msglength / numChannels),M,fsep,nsamp,Fs);
%size(carrier); % Should always equal 1024

% Use ifft to get orthogonal frequency vectors for OFDM
msgOFDM = ifft(msg, numChannels);

% Convert to column vector
msgOFDM = msgOFDM(:);

% Upsample for cases where we don't use all channels
msgOFDM = rectpulse(msgOFDM, 16 / numChannels);

% multiply upsample message by carrier  to get transmitted signal
tx = msgOFDM.'.*carrier;

% scale the output
gain = std(tx);
tx = tx./gain;

end