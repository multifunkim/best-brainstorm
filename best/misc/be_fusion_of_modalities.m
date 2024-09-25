function [obj] = be_fusion_of_modalities(data, obj, OPTIONS)
%BE_FUSION_OF_MODALITIES fuses data and leadfields from EEG and MEG for
% multimodal sources estimation using MEM
%
%   INPUTS:
%       -   data
%       -   obj
%       -   OPTIONS
%
%   OUTPUTS:
%       -   OPTIONS
%       - obj
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


% Concatenate data
if isfield(obj, 'data') % wavelet
    data = vertcat(obj.data{:});
else % Time-series
    data = vertcat(OPTIONS.automatic.Modality.data);
end
obj.data    = data;

% Concatenate Gain
obj.gain = vertcat(OPTIONS.automatic.Modality.gain);

% Concatenate idata if present
if isfield(OPTIONS.automatic.Modality(1),'idata')
    obj.idata   = OPTIONS.automatic.Modality(1).idata;
end

% If the covariance matrix is scale dependent, no multimodality possible
if size(OPTIONS.automatic.Modality(1).covariance,3) > 1
    obj.noise_var = OPTIONS.automatic.Modality(1).covariance;
else
    obj.noise_var   = diag( OPTIONS.automatic.Modality(1).covariance );
end

obj.baseline    = OPTIONS.automatic.Modality(1).baseline;
obj.channels    = OPTIONS.automatic.Modality(1).channels;

if length(OPTIONS.mandatory.DataTypes) > 1 % fusion of modalities if requested
    if OPTIONS.optional.verbose
        fprintf('%s, MULTIMODAL data ... %s ',OPTIONS.mandatory.pipeline,  OPTIONS.mandatory.DataTypes{1});
    end

    for ii=2:length(OPTIONS.mandatory.DataTypes)

        if  isfield(OPTIONS.automatic.Modality(ii),'idata') 
            obj.idata = [obj.idata; OPTIONS.automatic.Modality(ii).idata ]; 
        end

        if size(OPTIONS.automatic.Modality(1).covariance,3) > 1 && OPTIONS.optional.baseline_shuffle
            % we concatanate for each covariance matrix
            tmp = [];
            for ibaseline = 1:size(obj.noise_var,3)
                tmp(:,:,ibaseline) = blkdiag(obj.noise_var(:,:,ibaseline),OPTIONS.automatic.Modality(ii).covariance(:,:,ibaseline));
            end
            obj.noise_var = tmp;
        else
            obj.noise_var   = [obj.noise_var; diag(OPTIONS.automatic.Modality(ii).covariance)];
        end

        obj.baseline    = [obj.baseline; OPTIONS.automatic.Modality(ii).baseline];
        obj.channels    = [obj.channels; OPTIONS.automatic.Modality(ii).channels];

        if OPTIONS.optional.verbose
            fprintf('... %s found ', OPTIONS.mandatory.DataTypes{ii})
        end
    end
else
    if OPTIONS.optional.verbose
        fprintf('%s, No multimodalities ...',OPTIONS.mandatory.pipeline);
    end
end

% If the covariance matrix is scale dependent, noise_var is already a matrix
if size(OPTIONS.automatic.Modality(1).covariance,3) == 1
    obj.noise_var = diag( obj.noise_var );
end

if OPTIONS.optional.verbose, fprintf('\n'); end

end
