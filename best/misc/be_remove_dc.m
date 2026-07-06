function [OPTIONS] = be_remove_dc(OPTIONS)
% This function removes the DC offset from the data using the baseline
% segment defined in the panel
%
%% ==============================================
% Copyright (C) 2011 - LATIS Team
%
%  Authors: LATIS team, 2014
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
    
    % Remove temporal DC offset
    for iMod  = 1:length(OPTIONS.automatic.Modality)
    
        % Compute mean during baseline
        mu      =   mean(OPTIONS.automatic.Modality(iMod).baseline, 2);
        
        % subtract from baseline
        nSb     =   size(OPTIONS.automatic.Modality(iMod).baseline, 2);
        muM     =   mu * ones(1, nSb);
        OPTIONS.automatic.Modality(iMod).baseline = OPTIONS.automatic.Modality(iMod).baseline - muM;
        
        % subtract from data
        nSd     =   size(OPTIONS.automatic.Modality(iMod).data , 2);
        muM     =   mu * ones(1, nSd);
        OPTIONS.automatic.Modality(iMod).data  = OPTIONS.automatic.Modality(iMod).data - muM;
    
    end

    % Remove spatial DC offset from the data and baseline -- only for EEG/MEG
    for iMod  = 1:length(OPTIONS.automatic.Modality)
        if ~ismember(OPTIONS.mandatory.DataTypes{iMod}, {'MEG', 'EEG', 'SEEG', 'ECOG', 'ECOG+SEEG'})
            % Nothing to do
            continue;
        end

        nChan = size(OPTIONS.automatic.Modality(iMod).data, 1);
        projector = eye(nChan) - ones(nChan) ./ nChan;

        % Apply to the data, and baseline
        OPTIONS.automatic.Modality(iMod).data = projector * OPTIONS.automatic.Modality(iMod).data;
        OPTIONS.automatic.Modality(iMod).baseline = projector * OPTIONS.automatic.Modality(iMod).baseline;
    end
end