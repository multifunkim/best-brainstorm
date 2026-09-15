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
   
    %% ===== User-provided alpha   ===== %%
    if isfield(OPTIONS.optional.clustering, 'initial_alpha') && ~isempty(OPTIONS.optional.clustering.initial_alpha)
        if strcmp( OPTIONS.mandatory.pipeline, 'wMEM' )
            ALPHA = OPTIONS.optional.clustering.initial_alpha * ones(1, size(OPTIONS.automatic.Modality(1).selected_jk, 2));
        else
            ALPHA = OPTIONS.optional.clustering.initial_alpha * ones(1, size(OPTIONS.automatic.Modality(1).data, 2));
        end
    
        obj.ALPHA = ALPHA;
        return
    end
    
    %% ===== Computing alpha   ===== %%

    if OPTIONS.optional.verbose
        fprintf('%s, initialize alpha...', OPTIONS.mandatory.pipeline);
    end

    [OPTIONS] = be_switch_precision(OPTIONS, 'single');
    if OPTIONS.model.alpha_method < 6   % Initlialize alpha based on MSP
        [ALPHA, CLS, OPTIONS] = be_scores2alpha(obj.SCR, obj.CLS, OPTIONS);
        obj.CLS               = CLS;
    else                                % Initlialize alpha based on MNE
        if strcmp(OPTIONS.clustering.clusters_type,'static')
            [ALPHA, OPTIONS] = be_mne2alpha_stable(obj , obj.CLS, OPTIONS);
        else
            [ALPHA, OPTIONS] = be_mne2alpha(obj , obj.CLS, OPTIONS);
        end
    end
    [OPTIONS] = be_switch_precision(OPTIONS, 'double');
    
    if OPTIONS.optional.verbose
        fprintf(' done.\n');
    end

    %% ===== Store the final alpha and clusters ===== %%
    obj.ALPHA = ALPHA;
end
