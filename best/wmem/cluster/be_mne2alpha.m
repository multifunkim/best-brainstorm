function [alpha, CLS, OPTIONS] = be_mne2alpha(obj, CLS, OPTIONS, varargin)
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
                                                
    alpha = zeros(size(CLS));
    ALPHA_METHOD = OPTIONS.model.alpha_method;

    OBJ_FUS         = be_fusion_of_modalities(obj, OPTIONS, 0);

    % selection of the data:
    M = OBJ_FUS.data;
    if ~isempty(OPTIONS.automatic.selected_samples)   
        selected_samples = OPTIONS.automatic.selected_samples(1,:);
        M = M(:,selected_samples);
    end

    if ALPHA_METHOD == 6
        weight_alphas    = be_jmne_normalized(OBJ_FUS, OPTIONS);  
    end
    
    for jj=1:size(CLS,2)
        clusters    = CLS(:,jj);
        nb_clusters = max(clusters);
        curr_cls    = 1;

        if ALPHA_METHOD == 6
            weight_alpha    = weight_alphas(:, jj);  
        elseif ALPHA_METHOD == 7
            weight_alpha    = OPTIONS.automatic.Modality(1).MneKernel * M(:,jj);
        end

    
        for ii = 1:nb_clusters
            idCLS = clusters==ii;
    
            WSjj            = weight_alpha.^2;
            WSjj_ii         = WSjj(idCLS); 
            alpha(idCLS,jj) = sqrt((sum(WSjj_ii) / sum(WSjj)));
                    
            CLS(idCLS,jj)   = curr_cls;
            curr_cls        = curr_cls + 1;
            
        end
        
    end
    
    alpha(alpha > 0.8) = 1;
end
