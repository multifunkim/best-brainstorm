function [ out_W, info ] = BEst_Wave850analysis( in_C, Nb_scales, Nb_level, Vmoments )
% Real Daubechies wavelet transform from Wavelab850
addpath(genpath('./Wavelab850'));
info.Wfiltre = MakeONFilter('Daubechies',2*(Vmoments+1));
info.Noff    = Nb_scales - Nb_level;
out_W = zeros(size(in_C));
for i = 1:size(in_C,1)
    out_W(i,:) = fwt_po(in_C(i,:),info.Noff,info.Wfiltre);
end
end


