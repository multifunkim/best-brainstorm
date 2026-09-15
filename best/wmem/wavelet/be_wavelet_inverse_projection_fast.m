function inv_proj = be_wavelet_inverse_projection_fast(obj,OPTIONS)
%BE_WAVELET_INVERSE_PROJECTION Compute the inverse projection from box to
%time courses

    nbSmp       = size(obj.ImageGridAmp,2);
    nbSmpTime   = size(obj.data,2) ;

    all_scales  = OPTIONS.automatic.selected_samples(2, :);
    all_transls = OPTIONS.automatic.selected_samples(3, :);

    % Pre-compute one wavelet per scale
    [unique_scales, mother_wavelet] = prepare_wavelet(nbSmpTime, OPTIONS);


    all_rows = [];
    all_cols = [];
    all_vals = [];


    for iScale = 1:length(unique_scales)
        
        iBoxes = find(all_scales == unique_scales(iScale));

        scales          = all_scales(iBoxes);
        transls         = all_transls(iBoxes);
        inv_wavelet     = mother_wavelet(iScale, :);
            
        shifting    = 2.^scales(1);
        
        % Extract non-zero elements from the sparse wavelet
        [nz_row, nz_cols, nz_vals] = find(inv_wavelet);  % Find non-zero positions and values
        
        % Calculate shift amounts for ALL boxes at once
        shift_amounts = shifting * (transls(1) - transls(:));  % [num_boxes, 1]
        
        % Vectorized: compute new columns (broadcasts to [num_boxes, num_nz])
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


function [unique_scales, mother_wavelet] = prepare_wavelet(nbSmpTime, OPTIONS)
    
    all_scales  = OPTIONS.automatic.selected_samples(2, :);
    all_transls = OPTIONS.automatic.selected_samples(3, :);

    unique_scales = unique(all_scales);    
    iBoxesRef = zeros(1, length(unique_scales));
    for iScale = 1:length(unique_scales)
        iBoxesRef(iScale) = find(all_scales == unique_scales(iScale), 1);
    end
    
    x = 1:length(unique_scales);
    y = nbSmpTime ./ (2.^all_scales(iBoxesRef)) + all_transls(iBoxesRef);
    wav = sparse(x, y, 1, length(unique_scales), nbSmpTime);
    mother_wavelet    =   be_wavelet_inverse(wav, OPTIONS );
end