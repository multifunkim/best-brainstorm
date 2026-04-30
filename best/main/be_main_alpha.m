function [OPTIONS, obj] = be_main_alpha(obj, OPTIONS)
% BE_MAIN_ALPHA initialize the alpha value for each cluster
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
   
if ~isfield(OPTIONS.optional.clustering, 'initial_alpha')

    %% ===== Double to single precision  ===== %%
    [OPTIONS] = be_switch_precision(OPTIONS, 'single');

    if OPTIONS.model.alpha_method < 6
        [ALPHA, CLS, OPTIONS] = be_scores2alpha(obj.SCR, obj.CLS, OPTIONS);
    else % We compute the score using MNE
        OBJ_FUS               = be_fusion_of_modalities(obj, OPTIONS, 0);
        [ALPHA, CLS, OPTIONS] = be_mne2alpha(OBJ_FUS , obj.CLS, OPTIONS);
    end

    %% ===== Single to double precision  ===== %%
    [OPTIONS] = be_switch_precision(OPTIONS, 'double');

    
else
    CLS = obj.CLS;
    if strcmp( OPTIONS.mandatory.pipeline, 'wMEM' )
        ALPHA = OPTIONS.optional.clustering.initial_alpha * ones(1,size(OPTIONS.automatic.Modality(1).selected_jk, 2));
    else
        ALPHA = OPTIONS.optional.clustering.initial_alpha * ones(1,size(OPTIONS.automatic.Modality(1).data, 2));
    end
end

% the final clusters (CLS) and alpha's (ALPHA)
obj.CLS   = CLS;
obj.ALPHA = ALPHA;

end





 
