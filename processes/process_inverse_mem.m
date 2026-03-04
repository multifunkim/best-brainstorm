function varargout = process_inverse_mem( varargin )
% PROCESS_INVERSE: Compute an inverse model.

% @=============================================================================
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2014 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Edouard Delaire, 2026

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription()
    % ===== PROCESS =====
    % Description the process
    sProcess.Comment     = 'Compute sources: BEst';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Sources';
    sProcess.Index       = 327;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'raw'};
    sProcess.OutputTypes = {'results', 'results'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.isSeparator = 1;
    % Options: Comment
    sProcess.options.comment.Comment = 'Comment: ';
    sProcess.options.comment.Type    = 'text';
    sProcess.options.comment.Value   = '';
    % Options: MEM options
    sProcess.options.mem.Comment = {'panel_brainentropy', 'Source estimation options: '};
    sProcess.options.mem.Type    = 'editpref';
    sProcess.options.mem.Value   = be_main;
    % Option: Sensors selection
    sProcess.options.sensortypes.Comment = 'Sensor types:&nbsp;&nbsp;&nbsp;&nbsp;';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, MEG MAG, MEG GRAD, EEG';
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs)
    OutputFiles = {};
    
    % Default inverse options
    OPTIONS = Compute();
    
    % Get options edited by the user
    if ~isfield(sProcess.options.mem.Value, 'MEMpaneloptions')
        fprintf('\n\n***\tError in BEst process\t***\n\tyou MUST edit options before lauching the MEM.\n\n')
        return
    end

    OPTIONS.InverseMethod   = 'mem';
    OPTIONS.MEMpaneloptions = sProcess.options.mem.Value.MEMpaneloptions;
    OPTIONS.DataTypes       = strsplit(strrep(sProcess.options.sensortypes.Value,' ',''), ',');
    OPTIONS.ComputeKernel   = 0;
    OPTIONS.DisplayMessages = 0;

    % Prepare input
    iStudies = [sInputs.iStudy];
    iDatas   = [sInputs.iItem];

    % ===== START COMPUTATION =====
    [OutputFiles, errMessage] = Compute(iStudies, iDatas, OPTIONS);

    % Report errors
    if ~isempty(errMessage)
        if isempty(AllFiles)
            bst_report('Error', sProcess, sInputs, errMessage);
        else
            bst_report('Warning', sProcess, sInputs, errMessage);
        end
    end
end

%% ===== COMPUTE INVERSE SOLUTION =====
% USAGE:      OPTIONS = Compute()
%         OutputFiles = Compute(iStudies, iDatas, OPTIONS)
%
function [OutputFiles, errMessage] = Compute(iStudies, iDatas, OPTIONS)
    % Initialize returned variables
    OutputFiles = {};
    errMessage  = [];

    % Default options settings
    Def_OPTIONS = struct(...
        'InverseMethod',       'mem', ... % A string that specifies the imaging method
        'InverseMeasure',      '', ...
        'SourceOrient',        'fixed', ...
        'DataTypes',           [], ...     % Cell array of strings: list of modality to use for the reconstruction (MEG, MEG GRAD, MEG MAG, EEG)
        'Comment',             '', ...     % Inverse solution description (optional)
        'DisplayMessages',     1, ...
        'ComputeKernel',       0);  

    % Return default options
    if (nargin < 2)
        OutputFiles = Def_OPTIONS;
        return;
    end
    % Use default options
    if (nargin < 3) || isempty(OPTIONS)
        OPTIONS = Def_OPTIONS;
    else
        % Check field names of passed OPTIONS and fill missing ones with default values
        OPTIONS = struct_copy_fields(OPTIONS, Def_OPTIONS, 0);
    end
    
    %% ===== GET INPUT INFORMATION =====
    isShared = isempty(iDatas);
    if isShared
        errMessage = 'Cannot compute shared kernels with this method.';
        return
    end
    
    % Get channel studies
    [~, iChanStudies] = bst_get('ChannelForStudy', unique(iStudies));
    sChanStudies = bst_get('Study', iChanStudies);
    
    % Check that there are channel files available
    if any(cellfun(@isempty, {sChanStudies.Channel}))
        errMessage = 'No channel file available.';
        return;
    end
    % Check head model
    if any(cellfun(@isempty, {sChanStudies.HeadModel}))
        errMessage = 'No head model available.';
        return;
    end
    % Check noise covariance
    for i = 1:length(sChanStudies)
        if isempty(sChanStudies(i).NoiseCov) || ~isfield(sChanStudies(i).NoiseCov(1), 'FileName') || isempty(sChanStudies(i).NoiseCov(1).FileName)
            errMessage = 'No noise covariance matrix available.';
            return;
        end
    end

    % Check that at least one modality is available
    [AllMod, isOnlyNirs] = GetStudyModality(sChanStudies);
    if isempty(AllMod)
        % If only NIRS sensors
        if isOnlyNirs
            errMessage = ['To estimate sources for NIRS, use process:' 10 'NIRS > Sources > Compute sources' 10 'NIRSTORM plugin is required'];
        else
            errMessage = 'No valid sensor types to estimate sources: please calculate an appropriate headmodel.';
        end
        return;
    end

    %% ===== SELECT INVERSE METHOD =====
    % Select method
    if OPTIONS.DisplayMessages
        % Interface to edit options
        MethodOptions = gui_show_dialog('MEM options', @panel_brainentropy, [], [],  be_main());
        % Canceled by user
        if isempty(MethodOptions)
            return
        end

        MethodOptions.SourceOrient{1} = 'fixed';
        OPTIONS = struct_copy_fields(OPTIONS, MethodOptions, 1);
    end

    % If no MEG and no EEG selected
    if isempty(OPTIONS.DataTypes)
        errMessage = 'Please select at least one modality.';
        return;
    end

    % COMMENT 
    [OPTIONS.Comment, strMethod] = GetModalityComment(OPTIONS.DataTypes);

    %% ===== LOOP ON INPUT FILES =====
    % Initializations
    initOPTIONS = OPTIONS;
    % Display progress bar
    bst_progress('start', 'Compute sources', 'Initialize...', 0, 3*length(iStudies) + 1);
    % Process each input
    for iEntry = 1:length(iStudies)
        OPTIONS = initOPTIONS;
        
        % ===== LOAD CHANNEL FILE =====
        bst_progress('text', 'Reading channel information...');
        
        % Get study structure
        iStudy = iStudies(iEntry);
        sStudy = bst_get('Study', iStudy);

        % Is it a Raw file?
        isRaw = strcmpi(sStudy.Data(iDatas(iEntry)).DataType, 'raw');
        if isRaw
            errMessage = [ 'Cannot compute full results for raw files: import the files first or compute an inversion kernel only.' 10];
            break;
        end

        % Get channel file for study
        [sChannel, iStudyChannel]   = bst_get('ChannelForStudy', iStudy);
        ChannelMat                  = in_bst_channel(sChannel.FileName, 'Channel', 'Projector');

        % ===== LOAD DATA FILES =====
        bst_progress('text', 'Getting bad channels...');

        % Load data file
        DataFile    = sStudy.Data(iDatas(iEntry)).FileName;
        DataMat     = in_bst_data(DataFile, 'ChannelFlag', 'Time', 'nAvg', 'Leff', 'F');
        Time        = DataMat.Time;

        % ===== CHANNEL FLAG =====
        % Get the list of good channels
        GoodChannel = good_channel(ChannelMat.Channel, DataMat.ChannelFlag, OPTIONS.DataTypes);
        if isempty(GoodChannel)
            errMessage = [ 'No good channels available.' 10];
            break;
        end
        
        % ===== LOAD NOISE COVARIANCE =====
        % Get channel study
        sStudyChannel = bst_get('Study', iStudyChannel);
        
        % ===== LOAD HEAD MODEL =====
        bst_progress('text', 'Loading head model...');
        bst_progress('inc', 1);
        % Get headmodel file
        HeadModelFile = sStudyChannel.HeadModel(sStudyChannel.iHeadModel).FileName;
        % Load head model
        HeadModel = in_bst_headmodel(HeadModelFile, 0, 'Gain', 'GridLoc', 'GridOrient', 'GridAtlas', 'SurfaceFile', 'MEGMethod', 'EEGMethod', 'ECOGMethod', 'SEEGMethod', 'HeadModelType');
        % ===== MIXED HEADMODEL =====
        if strcmpi(HeadModel.HeadModelType, 'mixed') && ~isempty(HeadModel.GridAtlas) && ~isempty(HeadModel.GridAtlas(1).Scouts)
            errMessage = [ 'The mixed headmodel is currently only supported for the following inverse solutions: Minimum norm, dipole fitting, beamformer.' 10];
            break;
        end

        % ===== Load NoiseCov file =====
        [NoiseCovMat, errMessage] = LoadNoiseCov(sStudyChannel.NoiseCov(1).FileName, GoodChannel);
        if ~isempty(errMessage)
            break;
        end

        % ===== Apply current SSP projectors =====
        [HeadModel, NoiseCovMat] = ApplySSP(ChannelMat, HeadModel, NoiseCovMat);

        % ===== Select only good channels =====
        [ChannelMat, HeadModel, NoiseCovMat, DataMat] = SelectGoodChannel(GoodChannel, ChannelMat, HeadModel, NoiseCovMat, DataMat);

        % ===== Apply average reference: separately SEEG, ECOG, EEG =====
        [HeadModel, NoiseCovMat] = AppplyAvgRef(ChannelMat, HeadModel, NoiseCovMat);

        %% ===== COMPUTE INVERSE SOLUTION =====
        bst_progress('text', 'Estimating sources...');
        bst_progress('inc', 1);
        % NoiseCov: keep only the good channels
        OPTIONS.NoiseCovMat = NoiseCovMat;
        OPTIONS.ChannelTypes  = {ChannelMat.Channel.Type};
        OPTIONS.DataFile      = DataFile;
        OPTIONS.DataTime      = Time;
        OPTIONS.Channel       = ChannelMat.Channel;
        OPTIONS.Data          = DataMat.F;
        OPTIONS.ChannelFlag   = DataMat.ChannelFlag;
        OPTIONS.ResultFile    = [];
        OPTIONS.HeadModelFile = HeadModelFile;
        OPTIONS.GoodChannel   = GoodChannel;
        OPTIONS.FunctionName  = 'mem';

        % ===== Call the mem solver =====
        [Results, OPTIONS] = be_main(HeadModel, OPTIONS);
        if isempty(Results)
            errMessage = [ 'The inverse function returned an empty structure.' 10];
            break;
        end

        % ===== SAVE RESULTS FILE =====
        bst_progress('text', 'Saving results...');
        bst_progress('inc', 1);

        % Output folder
        OutputDir = bst_fileparts(file_fullpath(OPTIONS.DataFile));

        % Output filename
        ResultFile = bst_process('GetNewFilename', OutputDir, ['results_', strMethod]);

        % ===== CREATE FILE STRUCTURE =====
        ResultsMat = db_template('resultsmat');
        ResultsMat = struct_copy_fields(ResultsMat, Results, 1);
        ResultsMat.Comment       = [OPTIONS.Comment ' 2018'];
        ResultsMat.Function      = OPTIONS.FunctionName;
        ResultsMat.Time          = OPTIONS.DataTime;
        ResultsMat.DataFile      = OPTIONS.DataFile;
        ResultsMat.HeadModelFile = HeadModelFile;
        ResultsMat.HeadModelType = HeadModel.HeadModelType;
        ResultsMat.ChannelFlag   = DataMat.ChannelFlag;
        ResultsMat.GoodChannel   = GoodChannel;
        ResultsMat.SurfaceFile   = file_short(HeadModel.SurfaceFile);        
        ResultsMat.GridLoc       = [];
        ResultsMat.GridAtlas     = HeadModel.GridAtlas;
        ResultsMat.nAvg          = DataMat.nAvg;
        ResultsMat.Leff          = DataMat.Leff;
        ResultsMat.Options       = OPTIONS;
        % History
        ResultsMat = bst_history('add', ResultsMat, 'compute', ['Source estimation: ' OPTIONS.InverseMethod]);
        % Make file comment unique
        if ~isempty(sStudy.Result)
            ResultsMat.Comment = file_unique(ResultsMat.Comment, {sStudy.Result.Comment});
        end
        % Save new file structure
        bst_save(ResultFile, ResultsMat, 'v6');

        % ===== REGISTER NEW FILE =====
        % Create new results structure
        newResult = db_template('results');
        newResult.Comment       = ResultsMat.Comment;
        newResult.FileName      = file_short(ResultFile);
        newResult.DataFile      = ResultsMat.DataFile;
        newResult.isLink        = 0;
        newResult.HeadModelType = ResultsMat.HeadModelType;
        % Add new entry to the database
        iResult = length(sStudy.Result) + 1;
        sStudy.Result(iResult) = newResult;
        % Update Brainstorm database
        bst_set('Study', iStudy, sStudy);
        
        % ===== UPDATE DISPLAY =====
        % Update tree
        panel_protocols('UpdateNode', 'Study', iStudy);

        % Store output filename
        OutputFiles{end+1} = newResult.FileName;

        % Expand data node
        panel_protocols('SelectNode', [], newResult.FileName);
    end

    % Save database
    db_save();
    % Hide progress bar
    bst_progress('stop');
end

%% ===== GET MODALITY COMMENT =====
function [Comment, strMethod] = GetModalityComment(Modalities)

    % Replace "MEG GRAD+MEG MAG" with "MEG ALL"
    if all(ismember({'MEG GRAD', 'MEG MAG'}, Modalities))
        Modalities = setdiff(Modalities, {'MEG GRAD', 'MEG MAG'});
        Modalities{end+1} = 'MEG ALL';
    end 

    % Loop to build comment
    Comment     = 'MEM :';
    strMethod   = 'MEM';

    for im = 1:length(Modalities)
        if (im >= 2)
            Comment = [Comment, '+'];
        end
        Comment = [Comment, Modalities{im}];
        strMethod = [strMethod, '_', file_standardize(Modalities{im})];
    end    
    Comment = [Comment, ' (Full)'];
end

function [AllMod, isOnlyNirs] = GetStudyModality(sChanStudies)
    % Loop through all the channel files to find the available modalities and head model types
    AllMod = {};
    for i = 1:length(sChanStudies)
        AllMod = union(AllMod, sChanStudies(i).Channel.DisplayableSensorTypes);
        if isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).MEGMethod)
            AllMod = setdiff(AllMod, {'MEG GRAD','MEG MAG','MEG'});
        end
        if isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).EEGMethod)
            AllMod = setdiff(AllMod, {'EEG'});
        end
        if isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).ECOGMethod)
            AllMod = setdiff(AllMod, {'ECOG'});
        end
        if isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).SEEGMethod)
            AllMod = setdiff(AllMod, {'SEEG'});
        end
        if isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).NIRSMethod)
            AllMod = setdiff(AllMod, {'NIRS'});
        end
    end
    
    % Check for the presence of NIRS
    isOnlyNirs = all(ismember(AllMod, {'NIRS'}));
    % Keep only MEG and EEG
    if any(ismember(AllMod, {'MEG GRAD','MEG MAG'}))
        AllMod = intersect(AllMod, {'MEG GRAD', 'MEG MAG', 'EEG', 'ECOG', 'SEEG'});
    else
        AllMod = intersect(AllMod, {'MEG', 'EEG', 'ECOG', 'SEEG'});
    end
end

function [NoiseCovMat, errMessage] = LoadNoiseCov(FileName, GoodChannel)
    errMessage = '';

    NoiseCovMat = load(file_fullpath(FileName));
    % Check for NaN values in the noise covariance
    if ~isempty(NoiseCovMat.NoiseCov) && (nnz(isnan(NoiseCovMat.NoiseCov(GoodChannel, GoodChannel))) > 0)
        errMessage = [ 'The noise covariance contains NaN values. Please re-calculate it after tagging correctly the bad channels in the recordings.' 10];
        return
    end

    % Check that bad channels in noise covariance are the same as bad channels in recordings
    badChNoiseCov_goodChRecs = intersect(find(and(~any(NoiseCovMat.NoiseCov,1), ~any(NoiseCovMat.NoiseCov,2)')), GoodChannel);
    if ~isempty(badChNoiseCov_goodChRecs)
        errMessage = [ 'Bad channels in noise covariance are different from bad channels in recordings.' 10 'Please re-calculate it after tagging correctly the bad channels in the recordings.' 10];
        return;
    end
end

function [HeadModel, NoiseCovMat] = ApplySSP(ChannelMat, HeadModel, NoiseCovMat)
% Apply SSP from ChannelMat to HeadModel and NoiseCovMat

    if isempty(ChannelMat.Projector)
        return
    end

    % Rebuild projector in the expanded form (I-UUt)
    Proj = process_ssp2('BuildProjector', ChannelMat.Projector, [1 2]);
    % Apply projectors
    if ~isempty(Proj)
        % Get all sensors for which the gain matrix was successfully computed
        iGainSensors = find(sum(isnan(HeadModel.Gain), 2) == 0);
        % Apply projectors to gain matrix
        HeadModel.Gain(iGainSensors,:) = Proj(iGainSensors,iGainSensors) * HeadModel.Gain(iGainSensors,:);
        % Apply SSPs on both sides of the noise covariance matrix
        NoiseCovMat.NoiseCov = Proj * NoiseCovMat.NoiseCov * Proj';
    end
end

function [ChannelMat, HeadModel, NoiseCovMat, DataMat] = SelectGoodChannel(GoodChannel, ChannelMat, HeadModel, NoiseCovMat, DataMat)
    
    ChannelMat.Channel = ChannelMat.Channel(GoodChannel);
    HeadModel.Gain = HeadModel.Gain(GoodChannel, :);


    NoiseCovMat.NoiseCov = NoiseCovMat.NoiseCov(GoodChannel, GoodChannel);
    if isfield(NoiseCovMat, 'FourthMoment') && ~isempty(NoiseCovMat.FourthMoment)
        NoiseCovMat.FourthMoment = NoiseCovMat.FourthMoment(GoodChannel, GoodChannel);
    end
    if isfield(NoiseCovMat, 'nSamples') && ~isempty(NoiseCovMat.nSamples)
        NoiseCovMat.nSamples = NoiseCovMat.nSamples(GoodChannel, GoodChannel);
    end

    DataMat.F  = DataMat.F(GoodChannel,:);
    DataMat.ChannelFlag = DataMat.ChannelFlag(GoodChannel);
end

function [HeadModel, NoiseCovMat] = AppplyAvgRef(ChannelMat, HeadModel, NoiseCovMat)
% Apply average reference: separately SEEG, ECOG, EEG
    if ~any(ismember(unique({ChannelMat.Channel.Type}), {'EEG','ECOG','SEEG'}))
        % Nothing to do
        return;
    end

    % Create average reference montage
    ChannelFlag     = ones(length(ChannelMat.Channel),1);
    sMontage        = panel_montage('GetMontageAvgRef', [], ChannelMat.Channel, ChannelFlag , 0);
    %  Apply average reference operator on the gain matrix
    HeadModel.Gain  = sMontage.Matrix * HeadModel.Gain;
    % Apply average reference operator on both sides of the noise covariance matrix
    NoiseCovMat.NoiseCov = sMontage.Matrix * NoiseCovMat.NoiseCov * sMontage.Matrix';

end
