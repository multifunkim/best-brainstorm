function inv_proj = be_wavelet_inverse_projection_fast(obj,OPTIONS)
%BE_WAVELET_INVERSE_PROJECTION Compute the inverse projection from box to
%time courses

    nbSmpTime   = size(obj.data, 2);
    nbSmp       = size(OPTIONS.automatic.selected_samples, 2);
    all_scales  = OPTIONS.automatic.selected_samples(2, :);
    all_transls = OPTIONS.automatic.selected_samples(3, :);

    % Pre-compute one wavelet per scale
    [iBoxesRef, mother_wavelet] = prepare_wavelet(nbSmpTime, OPTIONS);

    ref_scales = all_scales(iBoxesRef);
    ref_transl = all_transls(iBoxesRef);


    all_rows = [];
    all_cols = [];
    all_vals = [];


    for iScale = 1:length(ref_scales)
        
        iBoxes = find(all_scales == ref_scales(iScale));

        scales          = all_scales(iBoxes);
        transls         = all_transls(iBoxes);
        inv_wavelet     = mother_wavelet(iScale, :);
            
        shifting    = 2.^scales(1);
        
        % Extract non-zero elements from the sparse wavelet
        [nz_row, nz_cols, nz_vals] = find(inv_wavelet);  % Find non-zero positions and values
        
        % Calculate shift amounts for ALL boxes at once
        shift_amounts = shifting * (ref_transl(iScale) - transls(:));
        
        % Vectorized: compute new columns
        new_cols = mod(nz_cols - shift_amounts - 1, nbSmpTime) + 1;

        % Accumulate indices and values
        row_idx = repelem(iBoxes(:), 1, length(nz_vals));
        col_idx = new_cols(:);
        val_idx = repmat(nz_vals, length(iBoxes), 1);
        
        all_rows = [all_rows; row_idx(:)];
        all_cols = [all_cols; col_idx];
        all_vals = [all_vals; val_idx(:)];
    end

    inv_proj    = sparse(all_rows, all_cols, all_vals , nbSmp, nbSmpTime);
    inv_proj    = inv_proj(:,obj.info_extension.start:obj.info_extension.end);
end


function [iBoxesRef, mother_wavelet] = prepare_wavelet(nbSmpTime, OPTIONS)
    
    all_scales  = OPTIONS.automatic.selected_samples(2, :);
    all_transls = OPTIONS.automatic.selected_samples(3, :);

    unique_scales = unique(all_scales);    
    iBoxesRef = zeros(1, length(unique_scales));
    for iScale = 1:length(unique_scales)
        tmp = find(all_scales == unique_scales(iScale));
            
        % find all translations for the scale
        translations = sort(all_transls(tmp));
        % select a translation far from the edge
        selected_translation = translations(round(length(tmp) / 2));

        iBoxesRef(iScale) = find(all_scales == unique_scales(iScale) & all_transls == selected_translation, 1);
    end
    
    x = 1:length(unique_scales);
    y = nbSmpTime ./ (2.^all_scales(iBoxesRef)) + all_transls(iBoxesRef);
    wav = sparse(x, y, 1, length(unique_scales), nbSmpTime);
    mother_wavelet    =   be_wavelet_inverse(wav, OPTIONS );
end