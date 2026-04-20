function [Results, OPTIONS] = be_wmem_solver(obj, OPTIONS)
% be_wmem_solver: compute wavelet Maximum Entropy on the Mean solution.
%
%
% INPUTS:
%     - HeadModel  : Brainstorm head model structure
%     - OPTIONS    : Structure of parameters (described in be_sourceimaging.m)
%          |- spatial_smoothing : optional spatial constraint on the
%                                 variance of the active state function, 
%                                 for each cluster. Set to 1 to activate.
%          |- MSP_R2_threshold  : threshold (between 0 and 1) to filter 
%                                 data and forward operator in the msp 
%                                 calculation
%          |- Modality          : Cell array of strings that identifies which
%                                 modalities are selected
%          |- MSP_window        : number of samples to use for calculating
%                                 the MSP. The window should be small 
%                                 enough to satisfy assumption of 
%                                 stationarity within that window.
%          |- stable_clusters   : Set to 1 to used C. Grova's clustering
%                                 method
%          |- NoiseCov          : Noise variance-covariance matrix. Should
%                                 be available from Brainstorm or can be 
%                                 estimated and provided separately
%          |- MSP_scores_threshold :Threshold of the MSP scores (between 0 
%                                   and 1). Set to 0 to keep all the scores.
%          |- active_var_mult   : multuplier for the variance-covariance of
%                                 the active state function
%          |- inactive_var_mult : multuplier for the variance-covariance of
%                                 the inactive state function (default: 0
%                                 i.e. a dirac)
%          |-alpha_threshold    : Threshold on the cluster probabilities of
%                                 being active. Clusters whose probas are
%                                 lower than this threshold will be turned
%                                 off
%          |- Optim_method      : Choice of optimization routine. By 
%                                 default uses minFunc (Mark Schmidt's
%                                 implementation). Specify 'fminunc' to use
%                                 Matlab optimization toolbox routine.
%          |- alpha             : Option to specify the alpha probabilies 
%                                 manually
%          |- Data              : Data to process (channels x time samples)
%          |- Units             : Structure for rescaling units
%          |- neighborhood_order: Nb. of neighbors used to cluterize 
%                                 cortical surface
%          |- alpha_method   :  Selection of the method to initialize the
%                               probability (alpha) of activation of the 
%                               clusters  (alpha).
%          |                   1 = average of the scores of sources in a cluster 
%          |                   2 = maximum of the scores of sources in a cluster 
%          |                   3 = median of the scores of sources in a cluster 
%          |                   4 = equiprobable activity (0.5)
%          |- active_mean_method:  Selection of the method to initialize 
%                                  the mean of the "active state" law (mu).
%          |                   1 = null hypothesis
%          |                   2 = Null activity (0)
%
% OUTPUTS:
%     - Results : Structure
%          |- ImageGridAmp  : Source activity (sources x times)
%          |- ImagingKernel : Not computed ([])
%
% ==============================================
% Copyright (C) 2011 - LATIS Team
%
%  Authors: LATIS team, 2011
%  ref [1]. Lina and al., wavelet-based localization of oscillatory sources
%  from MEG data, IEEE TBME (2012)
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
%%

%% ===== AVG reference ===== %% 
% Convert to average reference (only for EEG / iEEG)
[OPTIONS]       = be_avg_reference(OPTIONS);

%% ===== Pre-process the leadfield(s) ==== %% 
% we keep leadfields of interest; we compute svd of normalized leadfields
[OPTIONS, obj] = be_main_leadfields(obj, OPTIONS);

%% ===== Baseline shuffle ==== %% 
% If resting-state, generate artificial baseline based on phase reshufling 
if OPTIONS.optional.baseline_shuffle
    OPTIONS = be_shufle_baseline(OPTIONS);
end

%% ===== Normalization ==== %% 
% we absorb units (pT, nA) in the data, leadfields; 
% we normalize the data and the leadfields
[OPTIONS, obj] = be_normalize_and_units(obj, OPTIONS);

%% ===== Null hypothesis (for the threshold for the msp scores)
% from the baseline, compute the distribution of the msp scores. 
OPTIONS = be_model_of_null_hypothesis(OPTIONS);

%% ===== Data Processing (and noise) ===== %%
% for the data: normalization/wavelet/denoise
[OPTIONS, obj] = be_wdata_preprocessing(obj, OPTIONS);
if OPTIONS.optional.display
    obj = be_display_time_scale_boxes(obj, OPTIONS);
end

%% ===== Compute Minimum Norm Solution ==== %% 
% we compute MNE (using l-curve for nirs or depth-weighted version)
[obj, OPTIONS] = be_main_mne(obj, OPTIONS);

%% ===== Clusterize cortical surface ===== %%
% from the msp scores, clustering of the cortical mesh:
[OPTIONS, obj] = be_main_clustering(obj, OPTIONS);

%% ===== pre-processing for spatial smoothing (Green mat. square) ===== %%
% matrix W'W from the Henson paper
[OPTIONS, obj.GreenM2] = be_spatial_priorw(OPTIONS, obj.VertConn);

%% ===== Fuse modalities ===== %%   
obj = be_fusion_of_modalities(obj, OPTIONS);

%% ===== Solve the MEM ===== %%
[obj.ImageGridAmp, OPTIONS] = be_launch_mem(obj, OPTIONS);
if OPTIONS.optional.display
    be_display_entropy_drops(obj,OPTIONS);
end

%% ===== Un-Normalization  ===== %%
[obj, OPTIONS] = be_unormalize_and_units(obj, OPTIONS);

%% Conversion to time-series
if ~OPTIONS.wavelet.single_box
    inv_proj = be_wavelet_inverse_projection(obj,OPTIONS);
    
    if OPTIONS.output.save_factor
        obj.ImageGridAmp = {obj.ImageGridAmp, inv_proj};
    else
        obj.ImageGridAmp = obj.ImageGridAmp * inv_proj;
    end
end


%% ===== Solve the MEM on the scaling coeficient ===== %%
[obj_scaling, OPTIONS_scaling] = be_main_wmem_scaling(obj, OPTIONS);
if OPTIONS_scaling.optional.display
    be_display_entropy_drops(obj_scaling,OPTIONS_scaling);
end

if OPTIONS.output.save_factor
    obj.ImageGridAmp{1} = [obj.ImageGridAmp{1}, obj_scaling.ImageGridAmp];
    obj.ImageGridAmp{2} = [obj.ImageGridAmp{2}; obj_scaling.inv_proj];

else
    obj.ImageGridAmp = obj.ImageGridAmp + (obj_scaling.ImageGridAmp * obj_scaling.inv_proj);
end


%% ===== Update Comment ===== %%
OPTIONS.automatic.Comment = [OPTIONS.automatic.Comment ' DWT(j' num2str(OPTIONS.wavelet.selected_scales) ' + scaling)'];

% Results
Results = be_template('resultsmat');
Results.ImagingKernel   = [];
Results.ImageGridAmp    = obj.ImageGridAmp;
Results.Time            = OPTIONS.mandatory.DataTime;
Results.nComponents     = round( length(obj.iModS) / obj.nb_sources );

OPTIONS                 = be_cleanup_options(obj, OPTIONS);

end


