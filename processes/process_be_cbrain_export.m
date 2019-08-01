function varargout = process_be_cbrain_export(varargin) %#ok
% PROCESS_BE_CBRAIN_EXPORT

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok
% Process description
sProcess.Comment = 'BEst: CBRAIN export';
sProcess.Category = 'Custom';
sProcess.SubGroup = 'Extra';
sProcess.Index = 1;
sProcess.Description = '#link-to-tutorial';

% Inputs definition
sProcess.InputTypes = {'data'};
sProcess.OutputTypes = {''};
sProcess.nInputs = 1;
sProcess.nMinFiles = 1;

% [Options] Output directory
sProcess.options.outDir.Comment = 'Output directory: ';
sProcess.options.outDir.Type = 'filename';
sProcess.options.outDir.Value = {...
   '', ... % Filename
   '', ... % FileFormat
   'open', ... % Dialog type: {open,save}
   'Select output directory...', ... % Window title
   'ExportData', ... % LastUsedDir: {ImportData,ImportChannel,ImportAnat,ExportChannel,ExportData,ExportAnat,ExportProtocol,ExportImage,ExportScript}
   'single', ... % Selection mode: {single,multiple}
   'dirs', ... % Selection mode: {files,dirs,files_and_dirs}
   {{'.folder'}, 'Directory', ''}, ... % Available file formats
   'DataIn'}; % DefaultFormats: {ChannelIn,DataIn,DipolesIn,EventsIn,AnatIn,MriIn,NoiseCovIn,ResultsIn,SspIn,SurfaceIn,TimefreqIn}

% [Options] Compression
sProcess.options.compressFiles.Comment = 'Compress files';
sProcess.options.compressFiles.Type = 'checkbox';
sProcess.options.compressFiles.Value = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok
Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok
OutputFiles = [];

if isempty(sProcess.options.outDir.Value{1})
   error('Empty output directory')
end

if sProcess.options.compressFiles.Value
   tempDir = tempname(sProcess.options.outDir.Value{1});
   CreateDir(tempDir);
   files = cell(size(sInputs));
   for k = 1:size(sInputs, 2)
      files{k} = MakeCbrainFile(sInputs(k), tempDir);
   end
   tar([sProcess.options.outDir.Value{1}, filesep, 'cbrain_', ...
      datestr(datetime('now'), 'yymmddHHMMSSFFF')], files);
   RemoveDir(tempDir);
else
   oDir = [sProcess.options.outDir.Value{1}, filesep, 'cbrain_', ...
      datestr(datetime('now'), 'yymmddHHMMSSFFF')];
   CreateDir(oDir);
   for k = 1:size(sInputs, 2)
      MakeCbrainFile(sInputs(k), oDir);
   end
end
end


%% ===== MAKE CBRAIN FILE =====
function filePath = MakeCbrainFile(sInput, oDir)
S = db_template('resultsmat');


% Data
S.DataFile = sInput.FileName;
S.Options.Recording = getfield(load(file_fullpath(S.DataFile), 'F'), 'F');
S.Time = getfield(load(file_fullpath(S.DataFile), 'Time'), 'Time');


% Channels
Channels = getfield(load(file_fullpath(sInput.ChannelFile),...
   'Channel'), 'Channel');
S.Options.ChannelsType = {Channels.Type};
ChannelFlag = getfield(load(file_fullpath(S.DataFile),...
   'ChannelFlag'), 'ChannelFlag');
S.Options.eegChannels = good_channel(Channels, ChannelFlag, 'EEG');
S.Options.megChannels = good_channel(Channels, ChannelFlag, 'MEG');


% Head model
S.HeadModelFile = getfield(bst_get('HeadModelForStudy', ...
   sInput.iStudy), 'FileName');
headModel = in_bst_headmodel(S.HeadModelFile,1);
S.Options.Gain = headModel.Gain;
S.HeadModelType = headModel.HeadModelType;
S.Options.HeadModelSensorsType = cell(0);
if ~isempty(headModel.EEGMethod)
   S.Options.HeadModelSensorsType{end+1} = 'EEG';
end
if ~isempty(headModel.MEGMethod)
   S.Options.HeadModelSensorsType{end+1} = 'MEG';
end


% Cortical surface
S.SurfaceFile = headModel.SurfaceFile;
S.Options.VertConn = getfield(load(file_fullpath(S.SurfaceFile), ...
   'VertConn'), 'VertConn');


[~, name, ~] = fileparts(S.DataFile);
filePath = [oDir, filesep, sInput.SubjectName, '_s', ...
   int2str(sInput.iStudy), '_d', int2str(sInput.iItem),  '_', name, '.mat'];
save(filePath, '-struct', 'S', '-v7.3');
end


%% ===== CREATE A DIRECTORY =====
function CreateDir(dirPath)
if ~exist(dirPath, 'dir')
   [status, msg] = mkdir(dirPath);
   if ~status
      error('- Failed to create the directory:\n  %s\n  %s\n', dirPath, msg)
   end
end
end


%% ===== REMOVE A DIRECTORY =====
function RemoveDir(dirPath)
if exist(dirPath, 'dir')
   [status, msg] = rmdir(dirPath, 's');
   if ~status
      error('- Failed to remove the directory:\n  %s\n  %s\n', dirPath, msg)
   end
end
end