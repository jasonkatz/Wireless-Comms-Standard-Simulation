function [ber] = rxShabbaton(sig, bits, nSyms, msgM, chan)
% ECE-408 Project 1 - Receiver
% Jessica Marshall, Elie Lerea and Jason Katz - Team Shabbaton
% 802.11n Specification Implementation

rx = sig;

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
trellis = struct('numInputSymbols',2,'numOutputSymbols',4,...
'numStates',4,'nextStates',[0 2;0 2;1 3;1 3],...
'outputs',[0 3;1 2;3 0;2 1]);
rxBits = vitdec(rxBits, trellis, 10, 'trunc', 'hard');

% Check the BER. If zero BER, output the # of correctly received bits.
[zzz ber] = biterr(rxBits, bits);

end