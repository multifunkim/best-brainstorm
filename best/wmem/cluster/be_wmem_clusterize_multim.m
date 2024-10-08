function [CLS, SCR, OPTIONS] = be_wmem_clusterize_multim(obj, OPTIONS)
% This function returns clusterized (CLS) sources along with the MSP scores 
% (SCR) upon which the clustering is based. 
%
% NOTES:
%     - This function is not optimized for stand-alone command calls.
%     - Please use the generic BST_SOURCEIMAGING function, or the GUI.a
%
% ACTIVE_PROBABILITY (ALPHA)
% Different methods are proposed :
% Method 0: Manual initialization of the ALPHA
% Method 1: initialization with the average of the scores of each dipoles 
%           in a given cluster
% Method 2: initialization with the maximum of the scores of each dipoles 
%           in a given cluster
% Method 3: initialization with the median of the scores of each dipoles 
%           in a given cluster (Method used in cMEM)
% Method 4: initialization with 0.5
%
% INPUTS:
%     - obj       : MEM obj structure
%     - OPTIONS    : Structure of parameters (described in be_cmem_solver.m)
%          |- MSP_R2_threshold  : Variance threshold for Signal Space 
%          |                      separation
%          |- MSP_scores_threshold  : Threshold on MSP scores to discard least
%          |                      probable sources to explain data
%          |- neighborhood_order: Nb. of neighbors used to parcellize cortical surface
%          |- clustering.clusters_type  : string 
%          |           static = Makes the hypothesis that data is
%          |                    stationary (makes a unique clustering) 
%          |         stepwise = Makes the hypothesis that data is
%          |                    stationary only within windows of 
%          |                    length OPTION.MSP_window
%          |             wfdr = fdr threshold (or not in absence of baseline)
%          |                    in the wMEM case only
%          |- MSP_window        : Integer. Window size during which data is 
%                                 assumed to be stationary 
%
% OUTPUTS:
%     - Results : Structure
%          |- CLS           : Classification matrix. Contains labels
%          |                  ranging from 0 to number of parcels (1 column
%          |                  by time sample) for each sources.
%          |- SCR           : MSP scores matrix (same dimensions as CLS).
%          |- OPTIONS       : Keep track of parameters
%
%% ==============================================
% Copyright (C) 2011 - LATIS Team
%
% Authors: LATIS team, 2011
% revised: 01/2012
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

% ==== clustering technique
SCR = [];
CLS = [];

if strcmp(OPTIONS.clustering.clusters_type,'static')
    [CLS, SCR, OPTIONS]  = be_wstable_clustering_multim(obj, OPTIONS);
elseif strcmp(OPTIONS.clustering.clusters_type,'wfdr')
    [CLS, SCR, OPTIONS]  = be_wfdr_clustering_multim(obj, OPTIONS);
else
    error([OPTIONS.mandatory.pipeline ' : wrong specification of the clustering technique (should be stable or blockwise)']);
end

end