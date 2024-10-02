function [obj] = be_fusion_of_modalities(obj, OPTIONS)
%BE_FUSION_OF_MODALITIES fuses data and leadfields from different modalities 
% for multimodal sources estimation using MEM
%
%   INPUTS:
%       -   obj
%       -   OPTIONS
%
%   OUTPUTS:
%       -   obj
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


% Display information
if OPTIONS.optional.verbose && length(OPTIONS.mandatory.DataTypes) > 1 
    fprintf('%s, MULTIMODAL data ... %s found \n',OPTIONS.mandatory.pipeline, strjoin(OPTIONS.mandatory.DataTypes,', '));
elseif OPTIONS.optional.verbose && length(OPTIONS.mandatory.DataTypes) == 1
    fprintf('%s, No multimodalities ... \n',OPTIONS.mandatory.pipeline);
end

% Concatenate data
if isfield(obj, 'data') % wavelet
    data = vertcat(obj.data{:});
else % Time-series
    data = vertcat(OPTIONS.automatic.Modality.data);
end
obj.data    = data;

% Concatenate idata(complex data) if present
if isfield(OPTIONS.automatic.Modality(1),'idata')
    obj.idata   = vertcat(OPTIONS.automatic.Modality.idata);
end

% Concatenate Gain
obj.gain = vertcat(OPTIONS.automatic.Modality.gain);

% Concatenate noise covariance
if size(OPTIONS.automatic.Modality(1).covariance,3) > 1  % we concatanate for each covariance matrix

    obj.noise_var = OPTIONS.automatic.Modality(1).covariance;
    for ii=2:length(OPTIONS.mandatory.DataTypes)
        tmp = [];
        for ibaseline = 1:size(obj.noise_var,3)
            tmp(:,:,ibaseline) = blkdiag(obj.noise_var(:,:,ibaseline),OPTIONS.automatic.Modality(ii).covariance(:,:,ibaseline));
        end
        obj.noise_var = tmp;
    end
else
    obj.noise_var   = blkdiag(OPTIONS.automatic.Modality.covariance);
end

% Concatenate baseline and channels
obj.baseline    = vertcat(OPTIONS.automatic.Modality.baseline);
obj.channels    = vertcat(OPTIONS.automatic.Modality.channels);

if OPTIONS.optional.verbose, fprintf(' done.\n'); end

end
