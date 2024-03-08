function [out_C] = BEst_Wave850synthesis( in_W, Winfo)
% Real Daubechies wavelet reconstruction from Wavelab850
% Winfo.Noff : scaling level
% Winfo.Wfiltre: filter used for the previous decomposition
addpath(genpath('./Wavelab850'));
out_C = zeros(size(in_W));
for i = 1:size(in_W,1)
    out_C(i,:) = iwt_po(in_W(i,:),Winfo.Noff,Winfo.Wfiltre);
end
end


