function [tx, bits, gain] = txShabbaton(msgM, nSyms)
% ECE-408 Project 1 - Transmitter
% Jessica Marshall, Elie Lerea and Jason Katz - Team Shabbaton
% 802.11n Specification Implementation

k = log2(msgM);

numChannels = 56; % Number of OFDM subcarrier channels

% Generate data (4096 - 16 channels ; 2048 - 8 channels ; 1024 - 4 channels
bits = randi([0 1],numChannels * k * nSyms, 1); % Generate random bits, pass these out of function, unchanged

code = bits;

% Convert to symbols
syms = bi2de(reshape(code,k,length(code)/k).','left-msb')';

% Random msgM-QAM Signal
msg = qammod(syms, msgM);

% Break up message into two parts
msgTx1 = msg(1, 1:(length(msg) / 2));
msgTx2 = msg(1, (length(msg) / 2 + 1):length(msg));
msgTx1 = reshape(msgTx1, numChannels, length(msgTx1) / numChannels).';
msgTx2 = reshape(msgTx2, numChannels, length(msgTx2) / numChannels).';

msg1Full = [zeros(nSyms / 2, 4) msgTx1(:, [1:numChannels]) zeros(nSyms / 2, 4)];
msg2Full = [zeros(nSyms / 2, 4) msgTx2(:, [1:numChannels]) zeros(nSyms / 2, 4)];

% Use ifft to get orthogonal frequency vectors for OFDM
msg1OFDM = ifft(msg1Full.').';
msg2OFDM = ifft(msg2Full.').';

% Add cyclic prefix
msg1OFDM = [msg1OFDM(:,[49:64]) msg1OFDM];
msg2OFDM = [msg2OFDM(:,[49:64]) msg2OFDM];

% Reshape
tx = [reshape(msg1OFDM, 1, (nSyms / 2) * 80) ; reshape(msg2OFDM, 1, (nSyms / 2) * 80)];

gain = std(tx);

end