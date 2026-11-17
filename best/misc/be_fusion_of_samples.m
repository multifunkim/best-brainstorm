function Fused = be_fusion_of_samples(Sel)
% BE_FUSION_OF_SAMPLES merges the boxes selected in each modality.
%
% A box is identified by its coefficient index, so fusing two modalities is
% the union of their indices. A box's geometry (scale, k, time, window) is
% fully determined by its index, so it is taken from whichever modality
% holds it.
%
%   INPUTS:
%       -   Sel   :   cell array, one label structure per modality (output
%                     of be_select_boxes_by_power)
%
%   OUTPUTS:
%       -   Fused :   structure of row vectors with fields
%                     index, scale, k, time, win_l, win_r, modality
%
% Ordering (unchanged from the original behavior):
%   - 1 modality  : decreasing power
%   - 2 modalities: increasing box index
% With more than 2 modalities only the first is used (as before).
%
%% ==============================================   
% Copyright (C) 2011 - LATIS Team
%
%  Authors: LATIS team, 2011
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

geom = {'index','scale','k','time','win_l','win_r'};

if numel(Sel) == 2
    A = Sel{1};
    B = Sel{2};
    idx = union(A.index, B.index);                 % sorted ascending

    [inA, locA] = ismember(idx, A.index);
    [~,   locB] = ismember(idx, B.index);

    for ii = 1:numel(geom)
        f = geom{ii};
        Fused.(f)       = zeros(1, numel(idx));
        Fused.(f)(inA)  = A.(f)(locA(inA));
        Fused.(f)(~inA) = B.(f)(locB(~inA));
    end
else
    % only one modality: we keep the ordering related to the power
    for ii = 1:numel(geom)
        Fused.(geom{ii}) = Sel{1}.(geom{ii});
    end
end

% modality code (always 1, as in the original)
Fused.modality = ones(1, numel(Fused.index));

end