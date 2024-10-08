function [Results, OPTIONS] = be_cmne_solver(HeadModel, OPTIONS, Results)
% cMNESOLVER: Minimum Norm Estimate solution.
%
% NOTES:
%     - This function is not optimized for stand-alone command calls.
%     - Please use the generic BST_SOURCEIMAGING function, or the GUI.a
%
% INPUTS:
%     - HeadModel  : Brainstorm head model structure
%     - OPTIONS    : Structure of parameters (described in be_main.m)
%          -solver          : Parameters for MEM solver
%               |- NoiseCov          : Noise variance-covariance matrix. 
%                                      Should be available from Brainstorm or can be 
%                                      estimated and provided separately
%          -model          : Parameters for MNE model
%               |- depth_weigth_MNE: Depth-weitghting factor for MNE 
%          -mandatory          : structure containing data and channel information
%               |- Data              : Data to process (channels x time samples)
%          -automatic         : structure containing outputs
%               |- Units             : Structure for rescaling units
%
% OUTPUTS:
%     - OPTIONS : Keep track of parameters
%     - Results : Structure
%          |- ImageGridAmp  : Source activity (sources x times)
%          |- ImagingKernel : Not computed ([])
%
% ==============================================
% Copyright (C) 2011 - MultiFunkIm & LATIS Team
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


if OPTIONS.optional.verbose
    fprintf('\n\n===== pipeline cMNE\n');
end 
 obj = struct('hfig', [] , 'hfigtab', [] );

%% ===== Comment ===== %%
OPTIONS.automatic.Comment       =   'cMNE';

%% ===== DC offset ===== %% 
% we remove the DC offset the data
if ~any(ismember( 'NIRS', OPTIONS.mandatory.DataTypes))
    [OPTIONS]       = be_remove_dc(OPTIONS);
end
%% ===== Channels ===== %% 
% we retrieve the channels name and the data
[OPTIONS, obj]  = be_main_channel(HeadModel, obj, OPTIONS);

%% ===== AVG reference ===== %% 
% we average reference the data
if ~any(ismember( 'NIRS', OPTIONS.mandatory.DataTypes))
    [OPTIONS]       = be_avg_reference(OPTIONS);
end

%% ===== Sources ===== %% 
% we verify that all sources in the model have good leadfields
[OPTIONS, obj]  = be_main_sources(obj, OPTIONS);

%% ===== Pre-process the leadfield(s) ==== %% 
% we keep leadfields of interest; we compute svd of normalized leadfields
[OPTIONS, obj] = be_main_leadfields(obj, OPTIONS);

%% ===== Apply temporal data window  ===== %%
% check for a time segment to be localized
[OPTIONS] = be_apply_window( OPTIONS, [] );

%% ===== Compute Minimum Norm Solution ==== %% 
% we compute MNE (using l-curve for nirs or depth-weighted version)
[obj, OPTIONS] = be_main_mne(obj, OPTIONS);

obj.ImageGridAmp =  OPTIONS.automatic.Modality(1).Jmne * OPTIONS.automatic.Modality(1).MNEAmp;

[OPTIONS, obj] = be_apply_window( OPTIONS, obj );

             
% Results (full temporal sequence)                  
Results = struct(...
    'ImageGridAmp',     obj.ImageGridAmp, ...
    'ImagingKernel',    [], ...
    'MEMoptions',       OPTIONS);

disp('Bye.')
end


