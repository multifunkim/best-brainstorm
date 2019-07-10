function [OPTIONS, obj] = be_main_clustering_NIRS_fusion(obj, OPTIONS)
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
    
SCR = OPTIONS.SCR; 
% Needed Data
VertConn = obj.VertConn;
CLS     = zeros(size(SCR));
for i = 1:size(CLS,2)
    [OPTIONS, CLS(:,i),cellstruct_cls] = be_create_clusters(VertConn, mean(SCR,2), OPTIONS );
end
[ALPHA, CLS, OPTIONS]   = be_scores2alpha(SCR, CLS, OPTIONS);
% the final scores (SCR), clusters (CLS) and alpha's (ALPHA)
obj.SCR   = SCR;
obj.CLS   = CLS;
obj.ALPHA = ALPHA;