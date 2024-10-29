function inv_proj = be_wavelet_inverse_projection(obj,OPTIONS)
%BE_WAVELET_INVERSE_PROJECTION Compute the inverse projection from box to
%time courses

    nbSmp       = size(obj.ImageGridAmp,2);
    nbSmpTime   =  size(obj.data,2) ;
    wav =   zeros( nbSmp,  nbSmpTime );

    for ii = 1 : nbSmp
        scale   =   OPTIONS.automatic.selected_samples(2,ii);
        transl  =   OPTIONS.automatic.selected_samples(3,ii);
        wav(ii,  nbSmpTime/2^scale + transl ) = 1;
    end

    inv_proj    =   be_wavelet_inverse( wav, OPTIONS );
    inv_proj    =   inv_proj(:,obj.info_extension.start:obj.info_extension.end);
    inv_proj    =   sparse(inv_proj);
end

