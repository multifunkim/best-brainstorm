function [alpha, CLS, OPTIONS] = be_mne2alpha_stable(obj, CLS, OPTIONS)
% BE_GAIN2ALPHA computes the initial probability of a parcel being active in 
%   the MEM using the % of MNE energy within each parcels
%
%   INPUTS:
%       -   SCR     : vector of MSP scores with dimension Nsources
%       -   CLS     : vector of parcel labels for each source (1xNsources)
%       -   OPTIONS : 
%               model.alpha_method  : initial parcel active probabilities. 
%                       | 6 : use MNE on normalized data
%                       | 7:  use MNE solved using l-curve
%
%
%   OUTPUTS:
%       - OPTIONS   : Keep track of parameters
%       -   ALPHA   : vector of probabilities (1xNparcels)
%       -   CLS     : cell array (1xNparcels). Each cell contains the indices of        
%                     the sources within that parcel
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
                                                
    ALPHA_METHOD = OPTIONS.model.alpha_method;

    % selection of the Kernel and data:
    if ALPHA_METHOD == 6
        kernel    = be_jmne_normalized(obj, OPTIONS);  
        M         = obj.data_normalized;
    elseif ALPHA_METHOD == 7
        kernel  = OPTIONS.automatic.Modality(1).MneKernel;
        M       = obj.data;
    else
        error('Uknown alpha method: %d', ALPHA_METHOD)
    end

    if ~isempty(OPTIONS.automatic.selected_samples)   
        selected_samples = OPTIONS.automatic.selected_samples(1,:);
        M = M(:,selected_samples);
    end

    clusters        = CLS(:, 1);
    nb_clusters     = max(clusters);
    alpha           = zeros(size(CLS));
    sum_weight_squared = zeros(nb_clusters, size(CLS, 2));
    
    % Pre-compute cluster memberships and sizes to avoid redundant logical indexing
    cluster_masks = false(length(clusters), nb_clusters);
    for iCluster = 1:nb_clusters
        cluster_masks(:, iCluster) = (clusters == iCluster);
    end
    cluster_sizes = sum(cluster_masks, 1);

    % Compute weighted squared sums for each cluster
    for iCluster = 1:nb_clusters
        weight_alpha = kernel(cluster_masks(:, iCluster), :) * M;
        weight_squared = weight_alpha.^2;
        sum_weight_squared(iCluster, :) = sum(weight_squared, 1);
    end
    
    % Normalize by total across all clusters
    sum_norm = sum(sum_weight_squared, 1);
    
    % Assign normalized values to cluster members
    for iCluster = 1:nb_clusters
        alpha(cluster_masks(:, iCluster), :) = repmat(sqrt(sum_weight_squared(iCluster, :) ./ sum_norm), cluster_sizes(iCluster), 1);
    end
    
    alpha(alpha > 0.8) = 1;
end
