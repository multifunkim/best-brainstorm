function OPTIONS = be_cleanup_options(obj, OPTIONS)
%BE_MINIMIZE_OPTION Remove non essential field of OPTIONS
% This is usefull to reduce the space used by OPTIONS when saved in
% Brainstorm database

    % Set different options
    OPTIONS.ComputeKernel   = 0;
    OPTIONS.FunctionName    = OPTIONS.mandatory.pipeline;
    OPTIONS.Comment         = OPTIONS.automatic.Comment;
    OPTIONS.DataTypes       = unique(OPTIONS.mandatory.DataTypes);


    % 1. Clean OPTIONS.mandatory
    mandatory_field_to_remove = {'ChannelTypes',  'Data'};
    mandatory_field_to_remove = intersect(fieldnames(OPTIONS.mandatory), mandatory_field_to_remove);
    
    if ~isempty(mandatory_field_to_remove)
        OPTIONS.mandatory = rmfield(OPTIONS.mandatory, mandatory_field_to_remove);
    end

    % 2. Clean OPTIONS.automatic
    automatic = struct('Comment', OPTIONS.automatic.Comment);
    if OPTIONS.output.save_extra_information 
    
        automatic.entropy_drops     = OPTIONS.automatic.entropy_drops;
        automatic.initial_alpha     = obj.ALPHA;
        automatic.final_alpha       = {OPTIONS.automatic.final_alpha};
        automatic.clusters          = obj.CLS;
        automatic.MSP               = obj.SCR;     
        automatic.minimum_norm      = OPTIONS.automatic.Modality(1).Jmne;
           
    end
    
    if isfield( OPTIONS.automatic, 'selected_samples') && ~isempty(OPTIONS.automatic.selected_samples)
        automatic.selected_samples = OPTIONS.automatic.selected_samples;
    end

    if isfield( OPTIONS.automatic, 'info_extension') && ~isempty(OPTIONS.automatic.info_extension)
        automatic.info_extension = OPTIONS.automatic.info_extension;
    end    
    if isfield( OPTIONS.automatic, 'wActivation') && ~isempty(OPTIONS.automatic.wActivation)
        automatic.wActivation = OPTIONS.automatic.wActivation;
    end
    OPTIONS.automatic = automatic;

    % 3. Clean OPTIONS.optional
    OPTIONS.DataFile        = OPTIONS.optional.DataFile;
    
    if length(OPTIONS.optional.BaselineHistory) == 3
        OPTIONS.BaselineFile    = OPTIONS.optional.BaselineHistory{3};
    else
        OPTIONS.BaselineFile    = OPTIONS.optional.DataFile;
    end

    OPTIONS.BaselineSegment = OPTIONS.optional.BaselineSegment([1 end]);
    OPTIONS.TimeSegment     = OPTIONS.optional.TimeSegment([1,end]);
    OPTIONS.DataTime        = OPTIONS.mandatory.DataTime;

    OPTIONS.mandatory = rmfield(OPTIONS.mandatory, 'DataTime');
    OPTIONS = rmfield(OPTIONS,'optional');

end
