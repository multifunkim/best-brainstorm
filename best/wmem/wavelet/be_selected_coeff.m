function [OPTIONS] = be_selected_coeff(WM, obj, OPTIONS)
% BE_SELECTED_COEFF selects the wavelet coefficients to run the localization. 
% Only the boxes in the temporal interval of interest (TimeSegment) are kept
% (a box is kept if more than the half is included in the TimeSegment). 
% Only the boxes in the selected scale are kept.
% A maximum of 99% of the energy is kept. (except for nirs - keeping all the
% power)
%
% Pipeline (all steps work on label structures, see be_wavelet_box_labels):
%   1. label the boxes of each modality     be_wavelet_box_labels
%   2. drop edge boxes (OPTIONS.wavelet.edge_boxes, default 2), then
%      keep the strongest boxes (power)     be_select_boxes_by_power
%   3. fuse the modalities                  be_fusion_of_samples
%   4. keep boxes in time window and scales (here)
%   5. export to the legacy OPTIONS fields  (here, to_matrix)

% NOTES:
%     - This function is not optimized for stand-alone command calls.
%     - Please use the generic BST_SOURCEIMAGING function, or the GUI.a
%
% INPUTS:
%     - WM      : Data matrix (wavelet rep.) to be reconstructed using MEM
%     - obj     : Wavelet coefficients
%     - OPTIONS : Structure of parameters (described in be_main.m)
%
% OUTPUTS:
%     - Results : Structure
%          |- OPTIONS       : Keep track of parameters
%                           with the seleted wavelet coefficients
%                           OPTIONS.automatic.selected_samples (7 x nboxes):
%                               [index; scale; k; win_l; win_r; time; modality]
%                           OPTIONS.automatic.Modality(i).selected_jk (6 x nboxes):
%                               [index; scale; k; win_l; win_r; time]
%                           OPTIONS.automatic.selected_values{i} (3 x nboxes):
%                               [power; energy (%); in time window]
%
%
%% ==============================================
% Copyright (C) 2012 - LATIS Team
%
%  Authors: LATIS, 2012
%
%% ==============================================
% License 
%
% BEst is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    BEst is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with BEst. If not, see <http://www.gnu.org/licenses/>.
% -------------------------------------------------------------------------   

nbb = size(WM{1},2);                       % number of time samples (extended)
fs  = OPTIONS.automatic.sampling_rate;

% By default, we keep 99pc of power for EEG/MEG, 100% of power for fNIRS
pc_power = OPTIONS.wavelet.energy_threshold;

% Number of boxes treated as edge effect at each end of the TRUE data
% (see edge_dist in be_wavelet_box_labels). Boxes in the zero padding or
% straddling the data edge have edge_dist < 0 and are removed too.
% Edge boxes are removed BEFORE the power selection, so they do not count
% in the total power.
n_edge = OPTIONS.wavelet.edge_boxes;

% === 1-2. Label, remove edge boxes, select by power, per modality
nmod = length(OPTIONS.mandatory.DataTypes);
Sel  = cell(1, nmod);

for iMod = 1:nmod
    Labels  =  obj.box_labels(iMod);
    Labels  = be_labels_subset(Labels, Labels.edge_dist >= n_edge);
    Sel{iMod} = be_select_boxes_by_power(Labels, pc_power);
end

% === 3. Fusion of modalities
Fused = be_fusion_of_samples(Sel);

% === 4. Time window of interest (also removes edge effect)
t1 = max(OPTIONS.mandatory.DataTime(5), OPTIONS.optional.TimeSegment(1));
t2 = min(OPTIONS.mandatory.DataTime(end-5), OPTIONS.optional.TimeSegment(end));

% per-modality bookkeeping kept for downstream code
for iMod = 1:nmod
    in_win = box_in_window(Sel{iMod}, fs, t1, t2, true);
    OPTIONS.automatic.Modality(iMod).selected_jk = to_matrix(Sel{iMod}, false);
    OPTIONS.automatic.selected_values{iMod} = [Sel{iMod}.power ; Sel{iMod}.energy ; in_win];
end

in_time = box_in_window(Fused, fs, t1, t2, false);

% scales of interest
if ~isempty(OPTIONS.wavelet.selected_scales) && logical(prod(OPTIONS.wavelet.selected_scales))
    in_scale = ismember(Fused.scale, OPTIONS.wavelet.selected_scales);
else
    if OPTIONS.optional.verbose
        fprintf('%s, No specific scales selected\n', OPTIONS.mandatory.pipeline);
    end
    OPTIONS.wavelet.selected_scales = sort(unique(Fused.scale));
    in_scale = true(1, numel(Fused.index));
end

% what do we keep finally ? coeff in the selected time window and selected scales
Fused = be_labels_subset(Fused, in_time & in_scale);

% Keep only strongest t-f box
if OPTIONS.wavelet.single_box
    Fused = be_labels_subset(Fused, 1:min(1, numel(Fused.index)));
end

% === 5. Export
OPTIONS.automatic.selected_samples = to_matrix(Fused, true);

if OPTIONS.optional.verbose
    fprintf('%s, wavelet selected boxes: you kept %d t-f boxes over a total of %d. (%.1f %% of the total energy) \n', OPTIONS.mandatory.pipeline, numel(Fused.index), nbb, 100*pc_power);
end

end


% -------------------------------------------------------------------------
function in_win = box_in_window(L, fs, t1, t2, touch_is_inside)
% True for boxes that overlap [t1, t2]. A box is represented by its centre
% +/- 2^(scale-1)/fs/2.  touch_is_inside decides whether a box that only
% touches t1 or t2 counts as inside.
    half = 2.^(L.scale-1)/fs/2;
    tmi  = L.time - half;
    tma  = L.time + half;
    if touch_is_inside
        in_win = ~((tma <  t1) | (tmi >  t2));
    else
        in_win = ~((tma <= t1) | (tmi >= t2));
    end
end

% -------------------------------------------------------------------------
function M = to_matrix(L, with_modality)
% Legacy matrix layout expected by downstream code.
    M = [L.index ; L.scale ; L.k ; L.win_l ; L.win_r ; L.time];
    if with_modality
        M = [M ; L.modality];
    end
end