function [ber] = rxShabbaton(sig, bits, gain, msgM)
% ECE-408 Project 1 - Receiver
% Jessica Marshall, Elie Lerea and Jason Katz - Team Shabbaton
% 802.11n Specification Implementation

msgCode = [];

rx = sig;

%% Recover your signal here

numChannels = 64;

% Convert to properly sized matrix
rx = reshape(rx, numChannels, length(rx)/numChannels);

% Use fft to get data back using OFDM
rx = fft(rx, numChannels);

% Convert to column vector
rx = rx(:);

% Demod msgM-QAM
rxMsg = qamdemod(rx,msgM);

% Map Symbols to Bits
rx1 = de2bi(rxMsg,'left-msb');
rxBits = reshape(rx1.',numel(rx1),1);

% Check the BER. If zero BER, output the # of correctly received bits.
[zzz ber] = biterr(rxBits, bits);

end