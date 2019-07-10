function [OPTIONS] = be_normalize_and_units(OPTIONS)
%BE_NORMALIZE_UNITS normalizes leadfield and data units to enhance numerical computations
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


        
switch OPTIONS.optional.normalization
    
    case 'fixed'
        units_dipoles = 1e-9; % nAm
        for ii = 1 : numel(OPTIONS.mandatory.DataTypes)
        ratioG  =   1/max( max(OPTIONS.automatic.Modality(ii).gain) );
        OPTIONS.automatic.Modality(ii).units.Gain_units     =   ratioG;
        OPTIONS.automatic.Modality(ii).units.Data_units     =   ratioG/(units_dipoles);
        OPTIONS.automatic.Modality(ii).units.Cov_units      =   (ratioG/(units_dipoles))^2;
        end
        
    case 'adaptive'
        for ii  =   1 : numel(OPTIONS.mandatory.DataTypes)
            M   =   OPTIONS.automatic.Modality(ii).data;
            G   =   OPTIONS.automatic.Modality(ii).gain;
            J   =   be_solve_l_curve_mne(G,M,OPTIONS);
            ratioAmp = 1 / max(max(abs(J)));
            ratioG  = 1 / max(max(OPTIONS.automatic.Modality(ii).gain));
            OPTIONS.automatic.Modality(ii).units.Data_units = ratioAmp*ratioG;
            OPTIONS.automatic.Modality(ii).units.Cov_units = (ratioAmp*ratioG)^2; 
            OPTIONS.automatic.Modality(ii).units.Gain_units = ratioG;
            OPTIONS.automatic.Modality(ii).Jmne = J * ratioAmp;
        end
        
end


% Now, we normalize:
% - the leadfields and data
for ii = 1 : numel(OPTIONS.mandatory.DataTypes)
    OPTIONS.automatic.Modality(ii).gain = OPTIONS.automatic.Modality(ii).gain*OPTIONS.automatic.Modality(ii).units.Gain_units;
    OPTIONS.automatic.Modality(ii).data = OPTIONS.automatic.Modality(ii).data*OPTIONS.automatic.Modality(ii).units.Data_units;
    OPTIONS.automatic.Modality(ii).baseline = OPTIONS.automatic.Modality(ii).baseline*OPTIONS.automatic.Modality(ii).units.Data_units;  
    
    % we check for the presence of empty room data
    if isfield(OPTIONS.automatic, 'Emptyroom_data')
        OPTIONS.automatic.Modality(ii).emptyroom = OPTIONS.automatic.Modality(ii).emptyroom*OPTIONS.automatic.Modality(ii).units.Data_units;
    end
    
    % we check the existence of a covariance matrix:
    if ~isempty(OPTIONS.solver.NoiseCov) & (OPTIONS.solver.NoiseCov_recompute==0)
        NbjNoiseCov = size(OPTIONS.solver.NoiseCov,3);
        for i_sc = 1: NbjNoiseCov
            OPTIONS.solver.NoiseCov(OPTIONS.automatic.Modality(ii).channels,...
                OPTIONS.automatic.Modality(ii).channels,i_sc) = ...
                OPTIONS.solver.NoiseCov(OPTIONS.automatic.Modality(ii).channels,...
                OPTIONS.automatic.Modality(ii).channels,i_sc) * ...
                OPTIONS.automatic.Modality(ii).units.Cov_units; 
        end
    end

    % we check the existence of imaginary signal part:
    if isfield(OPTIONS.automatic.Modality(ii), 'idata') & ~isempty(OPTIONS.automatic.Modality(ii).idata)
        OPTIONS.automatic.Modality(ii).idata = OPTIONS.automatic.Modality(ii).idata*OPTIONS.automatic.Modality(ii).units.Data_units;    
    end
end


return