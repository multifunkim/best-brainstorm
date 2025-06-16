function inv_proj = be_wavelet_inverse_projection(obj,OPTIONS)
%BE_WAVELET_INVERSE_PROJECTION Compute the inverse projection from box to
%time courses

    nbSmp       = size(obj.ImageGridAmp,2);
    nbSmpTime   =  size(obj.data,2) ;

    x = 1 : nbSmp;

    scales  = OPTIONS.automatic.selected_samples(2, :);
    transls = OPTIONS.automatic.selected_samples(3, :);
    y = nbSmpTime ./ (2.^scales) + transls;

    wav = sparse(x,y,1,nbSmp,nbSmpTime);

    inv_proj    =   be_wavelet_inverse( wav, OPTIONS );
    inv_proj    =   inv_proj(:,obj.info_extension.start:obj.info_extension.end);
    
end

