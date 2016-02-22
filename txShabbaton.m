function [tx, bits, gain] = txShabbaton(msgM)
% ECE-408 Project 1 - Transmitter
% Jessica Marshall, Elie Lerea and Jason Katz - Team Shabbaton
% 802.11n Specification Implementation

k = log2(msgM);

numChannels = 64;

% Generate data (4096 - 16 channels ; 2048 - 8 channels ; 1024 - 4 channels
bits = randi([0 1],numChannels * 128 * k,1); % Generate random bits, pass these out of function, unchanged

code = bits;

% Convert to symbols
syms = bi2de(reshape(code,k,length(code)/k).','left-msb')';

% Random msgM-QAM Signal
msg = qammod(syms, msgM);

% % Check length
% msglength = length(msg);
% if(msglength ~= numChannels * 1024)
%     error('You smurfed up')
% end

% Interleave symbols between channels
msg = reshape(msg, numChannels, length(msg)/numChannels);

% Use ifft to get orthogonal frequency vectors for OFDM
msgOFDM = ifft(msg, numChannels);

% Convert to column vector
msgOFDM = msgOFDM(:);

% multiply upsample message by carrier  to get transmitted signal
tx = msgOFDM.';

gain = std(tx);

end