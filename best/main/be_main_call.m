function [Results, OPTIONS] = be_main_call(HeadModel, OPTIONS)
% BE_MAIN launches the MEM inverse solution pipeline that fits the
% OPTIONS.
% 
% Inputs:
% -------
%
%	HeadModel	:	structure of HeadModel used in brainstorm
%   OPTIONS     :   structure (see bst_sourceimaging.m)
%
%
% Outputs:
% --------
%
%   OPTIONS     :   Updated options fields
%
%   Results     :   structure containing the inverse solution data stored in
%                   brainstorm format.
%
% -------------------------------------------------------------------------
%
% LATIS team, 2012
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
%%

% ===== common I/O arguments ===== %%
Def_OPTIONS     = BEst_defaults; 
verbose         = ~(nargout==1);

switch(nargin)
    case 0
        Results     =   Def_OPTIONS;
        return
    case 1
        if ischar(HeadModel) && any(strcmpi({'cMEM', 'wMEM', 'rMEM'}, HeadModel))   
            Results = be_pipelineoptions(Def_OPTIONS, HeadModel);   
            return
        else
            error('MEM error : wrong pipeline input\n')
        end
    case 2
        if isempty(HeadModel)
            Results = be_pipelineoptions(OPTIONS); 
            return
        end
end


% ==== Copy default options to OPTIONS structure (do not replace defined values)
[stand_alone, process] = be_check_caller;
if ~stand_alone && isfield( OPTIONS, 'MEMpaneloptions' )
    MEMoptions = be_struct_copy_fields( Def_OPTIONS, OPTIONS.MEMpaneloptions, [],1 );
    % mandatory
    MEMoptions.mandatory.DataTime                       =   OPTIONS.DataTime;
    MEMoptions.mandatory.DataTypes                      =   OPTIONS.DataTypes;
    MEMoptions.mandatory.ChannelTypes                   =   {OPTIONS.Channel.Type};
    MEMoptions.mandatory.Data                           =   OPTIONS.Data;
    % optional
    MEMoptions.optional.Channel                         =   OPTIONS.Channel;
    MEMoptions.optional.ChannelFlag                     =   OPTIONS.ChannelFlag;
    MEMoptions.optional.DataFile                        =   OPTIONS.DataFile;
    MEMoptions.optional.ResultFile                      =   OPTIONS.ResultFile;
    MEMoptions.optional.HeadModelFile                   =   OPTIONS.HeadModelFile;
    MEMoptions.optional.Comment                         =   OPTIONS.Comment;
    % automatic
    MEMoptions.automatic.stand_alone                    =   0;
    MEMoptions.automatic.GoodChannel                    =   OPTIONS.GoodChannel;
    MEMoptions.automatic.iProtocol                      =   bst_get('ProtocolInfo');
    MEMoptions.automatic.Comment                        =   OPTIONS.Comment;
    MEMoptions.automatic.iStudy                         =   be_get_id( MEMoptions );
    [dummy, MEMoptions.automatic.iItem]                 =   be_get_id( MEMoptions );
    MEMoptions.automatic.DataInfo                       =   load( be_fullfile(MEMoptions.automatic.iProtocol.STUDIES, OPTIONS.DataFile) );
    % solver
    if isfield(OPTIONS, 'NoiseCov')
        MEMoptions.solver.NoiseCov                    	=   OPTIONS.NoiseCov;
    elseif isfield(OPTIONS, 'NoiseCovMat')
        MEMoptions.solver.NoiseCov                      =   OPTIONS.NoiseCovMat.NoiseCov;
    else
        error('MEM: cannot find noise covariance matrix in the OPTIONS');
    end
    if OPTIONS.MEMpaneloptions.solver.NoiseCov_recompute
        MEMoptions.solver.NoiseCov = []; 
    end

    MEMoptions = be_struct_copy_fields( MEMoptions, Def_OPTIONS, [] );

else
    MEMoptions = be_struct_copy_fields( OPTIONS, Def_OPTIONS, [] );
    MEMoptions.automatic.stand_alone    =   1;
    MEMoptions.automatic.process        =   process;
end


% ==== Check I/O
[HeadModel, MEMoptions, FLAG] = be_checkio( HeadModel, MEMoptions, verbose );

% Patch work [to be revisited]... Baseline no longer preloaded...
if ~isempty(MEMoptions.optional.Baseline) && ischar(MEMoptions.optional.Baseline)
    MEMoptions.optional.BaselineTime    = getfield(load(MEMoptions.optional.Baseline, 'Time'), 'Time');
    MEMoptions.optional.Baseline        = getfield(load(MEMoptions.optional.Baseline, 'F'), 'F');
end
if ~isempty(MEMoptions.optional.BaselineChannels) && ischar(MEMoptions.optional.BaselineChannels)
    MEMoptions.optional.BaselineChannels = load(MEMoptions.optional.BaselineChannels);
end

% ==== Check if DATA is compatible with MEM pipeline
isRF = strcmp( MEMoptions.mandatory.pipeline, 'rMEM' );
if ~MEMoptions.automatic.stand_alone || process
    [MEMoptions, isRF] = be_check_data_pipeline( MEMoptions );   
end

% Check time and baseline defintions
[MEMoptions, FLAG]  = be_check_timedef( MEMoptions, isRF );

% Check the options for rMEM
if strcmp(MEMoptions.mandatory.pipeline, 'rMEM') & ...
        any([isempty(MEMoptions.ridges.frequency_range) ...
        isempty(MEMoptions.ridges.min_duration)])
    FLAG = 1;
	fprintf('\n\nIn be_main :\trMEMoptions are incomplete.\n\t\tFill OPTIONS.ridges.frequency_range and OPTIONS.ridges.min_duration\n\n');
end

if FLAG
    error('MEM: unable to compute MEM.');
end

%% ==== LAUNCH PIPELINE ==== %%
% Initialize parallel computing
close_pool = false;
if MEMoptions.solver.parallel_matlab && isempty(gcp('nocreate'))
    gcp;
    close_pool = true;
end

[Results, OPTIONS]   = feval(['be_' lower(MEMoptions.mandatory.pipeline) '_solver'], HeadModel, MEMoptions);


% Close parallel computing
if close_pool
    delete(gcp('nocreate'))
end
    
end


% ----------------------------------------------------------------------- %

function Def_OPTIONS=   BEst_defaults

% ===== common I/O arguments ===== %%

% Mandatory 
Def_OPTIONS.mandatory.pipeline                  = '';
Def_OPTIONS.mandatory.DataTypes                 = {'MEG'};
Def_OPTIONS.mandatory.ChannelTypes              = {};
Def_OPTIONS.mandatory.DataTime                  = [];
Def_OPTIONS.mandatory.Data                      = [];

% Optional
Def_OPTIONS.optional.verbose                    = 1;
Def_OPTIONS.optional.display                    = 0;  
Def_OPTIONS.optional.iData                      = [];
Def_OPTIONS.optional.Baseline                   = [];
Def_OPTIONS.optional.BaselineType               = '';
Def_OPTIONS.optional.BaselineTime               = [];
Def_OPTIONS.optional.BaselineChannels           = [];
Def_OPTIONS.optional.BaselineHistory            = [];
Def_OPTIONS.optional.EmptyRoom_data             = [];
Def_OPTIONS.optional.EmptyRoom_channels         = {};
%Def_OPTIONS.optional.normalization              = 'adaptive'; % either 'fixed' or 'adaptive'
Def_OPTIONS.optional.TimeSegment                = [-9999999 9999999];
Def_OPTIONS.optional.BaselineSegment            = [-9999999 9999999];
Def_OPTIONS.optional.Channel                    = [];
Def_OPTIONS.optional.ChannelFlag                = [];
Def_OPTIONS.optional.FileType                   = '';
Def_OPTIONS.optional.ChannelNames               = '';
Def_OPTIONS.optional.ChannelFlags               = '';
Def_OPTIONS.optional.waitbar                    = 0;
Def_OPTIONS.optional.DataFile                   = '';
Def_OPTIONS.optional.ResultFile                 = '';
Def_OPTIONS.optional.HeadModelFile              = '';
Def_OPTIONS.optional.MSP_min_window             = 11;
Def_OPTIONS.optional.clustering.clusters        = []; % WILL BECOME OBSOLETE and replaced with
Def_OPTIONS.optional.Comment                    = 'MEM';
%Def_OPTIONS.optional.clustering                = struct; 
% this is the new struture with .clusters (labelling); .initial_alpha ; .sigma; .mu
% (empty at the begining but updated along the code, 
% sigma will be the true smoothing matrix on the patches)

% Automatic (contains the outputs)
Def_OPTIONS.automatic.InverseMethod             = ['MEM (' version ')'];
Def_OPTIONS.automatic.stand_alone               = 0;
Def_OPTIONS.automatic.process                   = 0;
Def_OPTIONS.automatic.Units                     = struct;
Def_OPTIONS.automatic.MEMexpert                 = 0;
Def_OPTIONS.automatic.GoodChannel               = [];
Def_OPTIONS.automatic.sampling_rate             = 0;
Def_OPTIONS.automatic.Modality                  = struct;
Def_OPTIONS.automatic.iData                     = [];
Def_OPTIONS.automatic.final_alpha               = [];
Def_OPTIONS.automatic.entropy_drops             = [];
Def_OPTIONS.automatic.BaselineType              = 'data';
Def_OPTIONS.automatic.iProtocol                 = [];
Def_OPTIONS.automatic.iStudy                    = [];
Def_OPTIONS.automatic.iItem                     = [];
Def_OPTIONS.automatic.DataInfo                  = struct;
Def_OPTIONS.automatic.Comment                   = '';
Def_OPTIONS.automatic.TFcomment                 = 'Wavelet T-F plane - type ''be_vizr'' to display';
Def_OPTIONS.automatic.version                   = 'unknown';        
Def_OPTIONS.automatic.last_update               = 'unknown';

% clustering (parcellization parameters)
Def_OPTIONS.clustering.MSP_R2_threshold         = .95;
Def_OPTIONS.clustering.neighborhood_order       = 4;                       
Def_OPTIONS.clustering.MSP_window               = 10;
Def_OPTIONS.clustering.clusters_type            = 'static';
Def_OPTIONS.clustering.MSP_scores_threshold     = 0;

% MEM model (reference law)
Def_OPTIONS.model.active_mean_method            = 2;
Def_OPTIONS.model.alpha_method                  = 3; 
Def_OPTIONS.model.alpha_threshold               = 0;
Def_OPTIONS.model.initial_lambda                = 1;

Def_OPTIONS.model.depth_weigth_MNE              = 0.5;
Def_OPTIONS.model.depth_weigth_MEM              = 0.5;

% MEM solver
Def_OPTIONS.solver.NoiseCov                     = [];
Def_OPTIONS.solver.NoiseCov_method              = 2;
Def_OPTIONS.solver.mne_use_noiseCov             = 0;
Def_OPTIONS.solver.NoiseCov_recompute           = 1;
Def_OPTIONS.solver.spatial_smoothing            = 0.6;
Def_OPTIONS.solver.active_var_mult              = 0.05;
Def_OPTIONS.solver.inactive_var_mult            = 0;
Def_OPTIONS.solver.Optim_method                 = 'fminunc';
Def_OPTIONS.solver.covariance_scale             = 1;
Def_OPTIONS.solver.parallel_matlab              = be_canUseParallelPool();

% output options
Def_OPTIONS.output.save_factor                  =  1;
Def_OPTIONS.output.save_extra_information       =  0;

end
