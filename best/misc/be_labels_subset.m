function L = be_labels_subset(L, idx)
% BE_LABELS_SUBSET keeps boxes idx (numeric or logical) in every field of a
% label structure. All fields must be row vectors with one entry per box.
%
% Part of BEst (GPLv3), see be_wavelet_box_labels.m for the license.

    fn = fieldnames(L);
    for ii = 1:numel(fn)
        L.(fn{ii}) = L.(fn{ii})(idx);
    end

end