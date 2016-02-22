function [ber] = rxShabbaton(sig, bits, nSyms, msgM, chan)
% ECE-408 Project 1 - Receiver
% Jessica Marshall, Elie Lerea and Jason Katz - Team Shabbaton
% 802.11n Specification Implementation

msgCode = [];

numChannels = 64;

rx = sig;

% Split up signal
rxPart1 = rx(1, :);
rxPart1 = reshape(rxPart1, numChannels + numChannels/4, nSyms / 2).';
rxPart2 = rx(2, :);
rxPart2 = reshape(rxPart2, numChannels + numChannels/4, nSyms / 2).';



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