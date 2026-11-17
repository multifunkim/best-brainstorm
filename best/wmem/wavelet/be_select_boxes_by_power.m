function S = be_select_boxes_by_power(Labels, pc_power)
% BE_SELECT_BOXES_BY_POWER keeps the strongest boxes of one modality until
% pc_power (0-1) of the total power is reached.
%
%   INPUTS:
%       -   Labels   :   structure from be_wavelet_box_labels
%       -   pc_power :   fraction of the power to keep (e.g. 0.99)
%
%   OUTPUTS:
%       -   S        :   Labels restricted to the kept boxes, ordered by
%                        decreasing power, with an extra field
%           .energy  :   100*power/sum(kept power), in %
%
% Part of BEst (GPLv3), see be_wavelet_box_labels.m for the license.

[power_sorted, I] = sort(Labels.power, 'descend');
Ic   = find(cumsum(power_sorted)/sum(power_sorted) <= pc_power, 1, 'last');
keep = I(1:Ic);

S        = be_labels_subset(Labels, keep);
S.energy = 100*S.power/sum(S.power);

end

