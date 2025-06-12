function [OPTIONS, obj] = be_normalize_and_units(obj, OPTIONS)
%BE_NORMALIZE_UNITS normalizes leadfield, baseline and data units to enhance numerical computations
%
%   INPUTS:
%       -OPTIONS     : Structure of parameters (described in be_main.m)
%          -mandatory          : Structure containing data and channel information
%               |- DataTypes              : 'MEG' or 'EEG' or 'MEEG'
%          -automatic.Modality : Structure containing the data and gain matrix for each modality
%   OUTPUTS:
%       -OPTIONS     : Keep track of parameters
%          -automatic.Modality
%               |-units: structure with new units for data and leadfield
%
% -------------------------------------------------------------------------
%   Author: LATIS 2012
%
% ==============================================
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

%% Normalization by using the mean standard deviation of baseline for each modalities
for ii = 1 : numel(OPTIONS.mandatory.DataTypes) %For every Modality (Data Type)
    
    % Std deviation for every channels on a modality
    if isfield(OPTIONS.optional, 'baseline_shuffle') && OPTIONS.optional.baseline_shuffle
        SD = std(OPTIONS.automatic.Modality(ii).baseline(:,:,1)');
    else
        SD = std(OPTIONS.automatic.Modality(ii).baseline');
    end
    
    % Define the mean standard deviation (MSD) of the present modality
    MSD = mean(SD);
    
    %Normalize datas, baseline, gain matrix and EmptyRoom_data with the mean std dev
    OPTIONS.automatic.Modality(ii).data         =   OPTIONS.automatic.Modality(ii).data./MSD;
    OPTIONS.automatic.Modality(ii).baseline     =   OPTIONS.automatic.Modality(ii).baseline./MSD;
    OPTIONS.automatic.Modality(ii).gain         =   OPTIONS.automatic.Modality(ii).gain./MSD;
    OPTIONS.automatic.Modality(ii).emptyroom    =   OPTIONS.automatic.Modality(ii).emptyroom/MSD;
    OPTIONS.automatic.Modality(ii).covariance   =   OPTIONS.automatic.Modality(ii).covariance/(MSD^2);
end

if strcmp(OPTIONS.optional.normalization,'adaptive') ||  strcmp(OPTIONS.mandatory.pipeline, 'cMEM')
    %% ===== Compute Minimum Norm Solution ==== %% 
    % we compute MNE (using l-curve for nirs or depth-weighted version)

    [obj, OPTIONS] = be_main_mne(obj, OPTIONS);

end

%% Normalization on units
    
switch OPTIONS.optional.normalization
    
    case 'fixed'
        if any(ismember( 'NIRS', OPTIONS.mandatory.DataTypes))
            units_dipoles = 5/100; % dOD is % changes
        else
            units_dipoles = 1e-9; % nAm
        end

    case 'adaptive'

        MNEAmp =   be_estimate_max_mne(obj,  OPTIONS);
        units_dipoles    =  MNEAmp; 

end

for ii = 1 : numel(OPTIONS.mandatory.DataTypes)
    ratioG  =   1 / max( max(OPTIONS.automatic.Modality(ii).gain) );

    OPTIONS.automatic.Modality(ii).units.Gain_units     =   ratioG;
    OPTIONS.automatic.Modality(ii).units.Data_units     =   ratioG  / units_dipoles;
    OPTIONS.automatic.Modality(ii).units.Cov_units      =   (ratioG / units_dipoles)^2;
    OPTIONS.automatic.Modality(ii).units_dipoles        =   units_dipoles;
end


%% Now, we normalize:
% - the leadfields and data
for ii = 1 : numel(OPTIONS.mandatory.DataTypes)
    OPTIONS.automatic.Modality(ii).gain =       OPTIONS.automatic.Modality(ii).gain * OPTIONS.automatic.Modality(ii).units.Gain_units;
    OPTIONS.automatic.Modality(ii).data =       OPTIONS.automatic.Modality(ii).data * OPTIONS.automatic.Modality(ii).units.Data_units;
    OPTIONS.automatic.Modality(ii).baseline =   OPTIONS.automatic.Modality(ii).baseline * OPTIONS.automatic.Modality(ii).units.Data_units;
    
    % we check for the presence of empty room data
    if isfield(OPTIONS.automatic, 'Emptyroom_data')
        OPTIONS.automatic.Modality(ii).emptyroom =  OPTIONS.automatic.Modality(ii).emptyroom * OPTIONS.automatic.Modality(ii).units.Data_units;
    end
   % we check the existence of imaginary signal part:
    if isfield(OPTIONS.automatic.Modality(ii), 'idata') && ~isempty(OPTIONS.automatic.Modality(ii).idata)
        OPTIONS.automatic.Modality(ii).idata =  OPTIONS.automatic.Modality(ii).idata * OPTIONS.automatic.Modality(ii).units.Data_units;
    end


    % we check the existence of a covariance matrix:
    if ~isempty(OPTIONS.automatic.Modality(ii).covariance) && ~OPTIONS.solver.NoiseCov_recompute
        OPTIONS.automatic.Modality(ii).covariance   =   OPTIONS.automatic.Modality(ii).covariance *  OPTIONS.automatic.Modality(ii).units.Cov_units;
    end
   
end

end




function max_value = be_estimate_max_mne(obj, OPTIONS)
% Estimate the maximum value of the MNE solution: max(max(abs(kernel*M))).
% Using a window approach to not save the entire solution Kernel*M in
% memory


    %Same for every modalities
    obj = be_fusion_of_modalities(obj, OPTIONS, 0);
    % selection of the data:
    M = obj.data;
    if ~isempty(OPTIONS.automatic.selected_samples)   
        selected_samples = OPTIONS.automatic.selected_samples(1,:);
        M = M(:,selected_samples);
    end

    
    kernel = OPTIONS.automatic.Modality(1).MneKernel;

    max_value =  max(max(abs(kernel * M))); 

end