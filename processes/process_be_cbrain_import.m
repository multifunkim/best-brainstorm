function varargout = process_be_cbrain_export(varargin) %#ok
% PROCESS_BE_CBRAIN_EXPORT

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok
% Process description
sProcess.Comment = 'BEst: CBRAIN import';
sProcess.Category = 'Custom';
sProcess.SubGroup = 'Extra';
sProcess.Index = 1;
sProcess.Description = '#link-to-tutorial';

% Inputs definition
sProcess.InputTypes = {'import'};
sProcess.OutputTypes = {''};
sProcess.nInputs = 1;
sProcess.nMinFiles = 0;

% [Options] Input files
sProcess.options.inFiles.Comment = 'Input files: ';
sProcess.options.inFiles.Type = 'filename';
sProcess.options.inFiles.Value = {...
   '', ... % Filename
   '', ... % FileFormat
   'open', ... % Dialog type: {open,save}
   'Select input file...', ... % Window title
   'ImportData', ... % LastUsedDir: {ImportData,ImportChannel,ImportAnat,ExportChannel,ExportData,ExportAnat,ExportProtocol,ExportImage,ExportScript}
   'multiple', ... % Selection mode: {single,multiple}
   'files', ... % Selection mode: {files,dirs,files_and_dirs}
   {{'.mat', '.tar'}, '(*.mat; *.tar)', ''}, ... % Available file formats
   ''}; % DefaultFormats: {ChannelIn,DataIn,DipolesIn,EventsIn,AnatIn,MriIn,NoiseCovIn,ResultsIn,SspIn,SurfaceIn,TimefreqIn}
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok
Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok
if isempty(sProcess.options.inFiles.Value{1})
   error('Empty input files')
end

OutputFiles = {};

inFiles = sProcess.options.inFiles.Value{1};

tempDir = tempname(tempdir);
CreateDir(tempDir);

for k = 1:size(inFiles, 1)
   if strcmp(inFiles{k}(end-3:end), '.tar')
      files = untar(inFiles{k}, tempDir);
      for kk = 1:size(files, 2)
         OutputFiles{end+1} = AddToBs(files{kk}); %#ok
      end
   else
      OutputFiles{end+1} = AddToBs(inFiles{k}); %#ok
   end
end

RemoveDir(tempDir);
end


%% ===== ADD TO BRAINSTORM =====
function oFile = AddToBs(iFile)
S = load(iFile);
oDir = fileparts(S.DataFile);
[~, iStudy] = bst_get('StudyWithCondition', oDir);
oFile = bst_process('GetNewFilename', oDir, 'results_CBRAIN_MEM');
bst_save(oFile, S, 'v7.3');
db_add_data(iStudy, oFile, S);
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