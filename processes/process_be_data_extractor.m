function varargout = process_be_data_extractor(varargin) %#ok
% PROCESS_BE_DATA_EXTRACTOR

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok

% Process description
sProcess.Comment = 'BEst - data extractor';
sProcess.Category = 'Custom';
sProcess.SubGroup = 'Extra';
sProcess.Index = 1;
sProcess.Description = '#link-to-tutorial';

% Inputs definition
sProcess.InputTypes = {'results'};
sProcess.OutputTypes = {'timefreq'};
sProcess.nInputs = 1;
sProcess.nMinFiles = 1;


% [Options] Description (label)
sProcess.options.labelDesc.Comment = 'Choose what to extract:';
sProcess.options.labelDesc.Type = 'label';

% [Options] MSP scores
sProcess.options.mspScores.Comment = 'MSP scores';
sProcess.options.mspScores.Type = 'checkbox';
sProcess.options.mspScores.Value = 1;

% [Options] Clusters
sProcess.options.clusters.Comment = 'Clusters';
sProcess.options.clusters.Type = 'checkbox';
sProcess.options.clusters.Value = 1;

% [Options] Initial active probability
sProcess.options.initActiveProba.Comment = 'Initial active proba';
sProcess.options.initActiveProba.Type = 'checkbox';
sProcess.options.initActiveProba.Value = 1;

% [Options] Final active probability
sProcess.options.finalActiveProba.Comment = 'Final active proba';
sProcess.options.finalActiveProba.Type = 'checkbox';
sProcess.options.finalActiveProba.Value = 1;

% [Options] Note (label)
sProcess.options.labelNote.Comment = ['<br>Notes:',...
   '<br>- cMEM: MSP scores are not saved by default.',...
   '<br>- wMEM: the time vector is the set of time-frequency boxes.'];
sProcess.options.labelNote.Type = 'label';
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok
Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok
OutputFiles = [];

for k = 1:numel(sInputs)
   sInputMat = in_bst_results(sInputs(k).FileName, 0, 'MEMoptions', ...
      'MEMdata', 'SurfaceFile', 'HeadModelFile', 'HeadModelType', 'DataType');
   
   if (sProcess.options.mspScores.Value == 1)
      OutputFiles = GetMspScores(sInputMat, sInputs(k), OutputFiles);
   end
   if (sProcess.options.clusters.Value == 1)
      OutputFiles = GetClusters(sInputMat, sInputs(k), OutputFiles);
   end
   if (sProcess.options.initActiveProba.Value == 1)
      OutputFiles = GetInitActiveProba(sInputMat, sInputs(k), OutputFiles);
   end
   if (sProcess.options.finalActiveProba.Value == 1)
      OutputFiles = GetFinalActiveProba(sInputMat, sInputs(k), OutputFiles);
   end
end
end


%% ===== MSP SCORES =====
function OutputFiles = GetMspScores(sInputMat, sInput, OutputFiles)
sOutputMat = db_template('timefreqmat');

if isempty(sInputMat.MEMoptions)
   warning('The file ''%s'' is not valid and was ignored', sInput.Condition)
   return
elseif strcmp(sInputMat.MEMoptions.mandatory.pipeline, 'cMEM')
   if ~isempty(sInputMat.MEMdata)
      sOutputMat.TF = sInputMat.MEMdata.SCR;
   else
      warning('No MSP scores for the file ''%s''', sInput.Condition)
      return
   end
   sOutputMat.Time = sInputMat.MEMoptions.optional.TimeSegment;
elseif strcmp(sInputMat.MEMoptions.mandatory.pipeline, 'wMEM')
   sOutputMat.TF = sInputMat.MEMdata.SCR;
   sOutputMat.Time = 1:size(sOutputMat.TF, 2);
   sOutputMat.boxesInfo = sInputMat.MEMoptions.automatic.selected_samples;
else
   warning('The file ''%s'' is not valid and was ignored', sInput.Condition)
   return
end

sOutputMat.Comment = 'MSP scores';
sOutputMat.DataFile = sInput.FileName;
sOutputMat.DataType = sInput.FileType;
sOutputMat.SurfaceFile = sInputMat.SurfaceFile;
sOutputMat.HeadModelFile = sInputMat.HeadModelFile;
sOutputMat.HeadModelType = sInputMat.HeadModelType;
sOutputMat.RowNames = 1:size(sOutputMat.TF,1);
sOutputMat.Method = '';
sOutputMat.Measure = 'other';

OutputFiles{end+1} = bst_process('GetNewFilename', ...
   bst_fileparts(sInput.FileName), 'timefreq_msp_scores');
SaveBsData(OutputFiles{end}, sOutputMat, sInput.iStudy);
end


%% ===== CLUSTERS =====
function OutputFiles = GetClusters(sInputMat, sInput, OutputFiles)
sOutputMat = db_template('timefreqmat');

if isempty(sInputMat.MEMoptions)
   warning('The file ''%s'' is not valid and was ignored', sInput.Condition)
   return
elseif strcmp(sInputMat.MEMoptions.mandatory.pipeline, 'cMEM')
   sOutputMat.TF = sInputMat.MEMoptions.automatic.clusters;
   sOutputMat.Time = sInputMat.MEMoptions.optional.TimeSegment;
elseif strcmp(sInputMat.MEMoptions.mandatory.pipeline, 'wMEM')
   sOutputMat.TF = sInputMat.MEMdata.CLS;
   sOutputMat.Time = 1:size(sOutputMat.TF, 2);
   sOutputMat.boxesInfo = sInputMat.MEMoptions.automatic.selected_samples;
else
   warning('The file ''%s'' is not valid and was ignored', sInput.Condition)
   return
end

sOutputMat.Comment = 'Clusters';
sOutputMat.DataFile = sInput.FileName;
sOutputMat.DataType = sInput.FileType;
sOutputMat.SurfaceFile = sInputMat.SurfaceFile;
sOutputMat.HeadModelFile = sInputMat.HeadModelFile;
sOutputMat.HeadModelType = sInputMat.HeadModelType;
sOutputMat.RowNames = 1:size(sOutputMat.TF,1);
sOutputMat.Method = '';
sOutputMat.Measure = 'other';

OutputFiles{end+1} = bst_process('GetNewFilename', ...
   bst_fileparts(sInput.FileName), 'timefreq_clusters');
SaveBsData(OutputFiles{end}, sOutputMat, sInput.iStudy);
end


%% ===== INITIAL ACTIVE PROBABILITIES =====
function OutputFiles = GetInitActiveProba(sInputMat, sInput, OutputFiles)
sOutputMat = db_template('timefreqmat');

if isempty(sInputMat.MEMoptions)
   warning('The file ''%s'' is not valid and was ignored', sInput.Condition)
   return
elseif strcmp(sInputMat.MEMoptions.mandatory.pipeline, 'cMEM')
   sOutputMat.TF = sInputMat.MEMoptions.automatic.initial_alpha;
   sOutputMat.Time = sInputMat.MEMoptions.optional.TimeSegment;
elseif strcmp(sInputMat.MEMoptions.mandatory.pipeline, 'wMEM')
   sOutputMat.TF = sInputMat.MEMdata.ALPHA;
   sOutputMat.Time = 1:size(sOutputMat.TF, 2);
   sOutputMat.boxesInfo = sInputMat.MEMoptions.automatic.selected_samples;
else
   warning('The file ''%s'' is not valid and was ignored', sInput.Condition)
   return
end

sOutputMat.Comment = 'Initial active probabilities';
sOutputMat.DataFile = sInput.FileName;
sOutputMat.DataType = sInput.FileType;
sOutputMat.SurfaceFile = sInputMat.SurfaceFile;
sOutputMat.HeadModelFile = sInputMat.HeadModelFile;
sOutputMat.HeadModelType = sInputMat.HeadModelType;
sOutputMat.RowNames = 1:size(sOutputMat.TF,1);
sOutputMat.Method = '';
sOutputMat.Measure = 'other';

OutputFiles{end+1} = bst_process('GetNewFilename', ...
   bst_fileparts(sInput.FileName), 'timefreq_init_active_proba');
SaveBsData(OutputFiles{end}, sOutputMat, sInput.iStudy);
end


%% ===== FINAL ACTIVE PROBABILITIES =====
function OutputFiles = GetFinalActiveProba(sInputMat, sInput, OutputFiles)
sOutputMat = db_template('timefreqmat');

if isempty(sInputMat.MEMoptions)
   warning('The file ''%s'' is not valid and was ignored', sInput.Condition)
   return
elseif strcmp(sInputMat.MEMoptions.mandatory.pipeline, 'cMEM')
   finalAlpha = sInputMat.MEMoptions.automatic.final_alpha;
   sOutputMat.TF = zeros(size(sInputMat.MEMoptions.automatic.clusters));
   for k = 1:size(sOutputMat.TF, 2)
      cls = sInputMat.MEMoptions.automatic.clusters(:, k);
      sOutputMat.TF(cls ~= 0, k) = finalAlpha{k}(cls(cls ~= 0));
   end
   sOutputMat.Time = sInputMat.MEMoptions.optional.TimeSegment;
elseif strcmp(sInputMat.MEMoptions.mandatory.pipeline, 'wMEM')
   finalAlpha = sInputMat.MEMoptions.automatic.final_alpha;
   sOutputMat.TF = zeros(size(sInputMat.MEMdata.CLS));
   for k = 1:size(sOutputMat.TF, 2)
      cls = sInputMat.MEMdata.CLS(:, k);
      sOutputMat.TF(cls ~= 0, k) = finalAlpha{k}(cls(cls ~= 0));
   end
   sOutputMat.Time = 1:size(sOutputMat.TF, 2);
   sOutputMat.boxesInfo = sInputMat.MEMoptions.automatic.selected_samples;
else
   warning('The file ''%s'' is not valid and was ignored', sInput.Condition)
   return
end

sOutputMat.Comment = 'Final active probabilities';
sOutputMat.DataFile = sInput.FileName;
sOutputMat.DataType = sInput.FileType;
sOutputMat.SurfaceFile = sInputMat.SurfaceFile;
sOutputMat.HeadModelFile = sInputMat.HeadModelFile;
sOutputMat.HeadModelType = sInputMat.HeadModelType;
sOutputMat.RowNames = 1:size(sOutputMat.TF,1);
sOutputMat.Method = '';
sOutputMat.Measure = 'other';

OutputFiles{end+1} = bst_process('GetNewFilename', ...
   bst_fileparts(sInput.FileName), 'timefreq_final_active_proba');
SaveBsData(OutputFiles{end}, sOutputMat, sInput.iStudy);
end


%% ===== SAVE TO DB =====
function SaveBsData(fileName, fileMat, iStudy)
bst_save(fileName, fileMat, 'v6');
db_add_data(iStudy, fileName, fileMat);
end