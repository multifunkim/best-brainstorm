function [OPTIONS, obj] = be_main_clustering(obj, OPTIONS)
% BE_MAIN_CLUSTERING launches the appropriate cortex clustering functions 
% according to the chosen MEM pipeline
%
% Inputs:
% -------
%
%	obj			:	MEM obj structure
%   OPTIONS     :   structure (see bst_sourceimaging.m)
%
%
% Outputs:
% --------
%
%   OPTIONS     :   Updated options fields
%	obj			:	Updated structure
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

   %% ===== User-provided clusters   ===== %%
    if isfield(OPTIONS.optional.clustering, 'clusters') && ~isempty(OPTIONS.optional.clustering.clusters)
        if strcmp( OPTIONS.mandatory.pipeline, 'wMEM' )
            CLS   = OPTIONS.optional.clustering.clusters * ones(1,size(OPTIONS.automatic.Modality(1).selected_jk, 2));
            SCR   = [];
        else
            CLS   = OPTIONS.optional.clustering.clusters * ones(1,size(OPTIONS.automatic.Modality(1).data, 2));
            SCR   = [];
        end

        % the final scores (SCR), clusters (CLS)
        obj.SCR   = SCR;
        obj.CLS   = CLS;
        
        return;
    end

    %% ===== Sources prescoring - MSP (ref. Mattout et al. 2006) and clustering  ===== %%

    [OPTIONS] = be_switch_precision(OPTIONS, 'single');
    switch OPTIONS.mandatory.pipeline
        case 'cMEM'
            [CLS, SCR, OPTIONS] = be_cmem_clusterize_multim(obj, OPTIONS); 
        case 'wMEM'
            [CLS, SCR, OPTIONS] = be_wmem_clusterize_multim(obj, OPTIONS);
        case 'rMEM'
            [CLS, SCR, OPTIONS] = be_rmem_clusterize_multim(obj, OPTIONS);
    end   
    [OPTIONS] = be_switch_precision(OPTIONS, 'double');
    
    % the final scores (SCR), clusters (CLS) and alpha's (ALPHA)
    obj.SCR   = SCR;
    obj.CLS   = CLS;

end





 
