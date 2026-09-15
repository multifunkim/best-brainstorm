function [OPTIONS] = be_avg_reference(OPTIONS)
% be_avg_reference Re-reference the data to the average reference montage.
% Only for EEG data. This is applied for each modality separatly
%% ==============================================
% Copyright (C) 2011 - LATIS Team
%
%  Authors: 
%           LATIS team, 2015
%           Edouard Delaire, 2026
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

    for iMod = 1:numel(OPTIONS.mandatory.DataTypes)

        if ~ismember(OPTIONS.mandatory.DataTypes{iMod}, {'EEG','SEEG','ECOG','ECOG+SEEG'})
            % Nothing to do
            continue;
        end
    
        % Compute the average montage projection
        nChan = size(OPTIONS.automatic.Modality(iMod).data,1);
        projector = eye(nChan) - ones(nChan) ./ nChan;

        % Apply to the data, and baseline
        OPTIONS.automatic.Modality(iMod).data = projector * OPTIONS.automatic.Modality(iMod).data;
        OPTIONS.automatic.Modality(iMod).baseline = projector * OPTIONS.automatic.Modality(iMod).baseline;
        
        % Apply to the noise covariance
        if ~isempty(OPTIONS.automatic.Modality(iMod).covariance)
            for i_sc = 1: size(OPTIONS.solver.NoiseCov, 3)
                OPTIONS.automatic.Modality(iMod).covariance(:, :, i_sc) =  projector *  OPTIONS.automatic.Modality(iMod).covariance(:, :, i_sc) * projector';
            end
        end

        % Apply to the gain matrix
        OPTIONS.automatic.Modality(iMod).gain     =   projector * OPTIONS.automatic.Modality(iMod).gain;

    end
end