function [HeadModel, OPTIONS, FLAG] = be_checkio( HeadModel, OPTIONS)
    
    FLAG = 0;
    
    % ==== Check mandatory fields
    MFs = {'DataTypes', 'ChannelTypes', 'pipeline', 'stand_alone','Data', 'DataTime'};
    if ~any( isfield(OPTIONS.mandatory, MFs) )
        idF = ~any( isfield(OPTIONS.mandatory, MFs)) ;
        fprintf('In be_main :\tmandatory field(s) %s undefined.\n', MFs{idF} );
        FLAG = 1;
    end
    
    % ==== Check data/time match
    if size(OPTIONS.mandatory.DataTime,2) ~= size(OPTIONS.mandatory.Data,2)
        fprintf('In be_main :\tData were found. \n');
        FLAG = 1;
    end

    % ==== Check Channel Definition
    nC1     =   numel(OPTIONS.mandatory.ChannelTypes);
    nC2     =   size(OPTIONS.mandatory.Data,1);
    if (nC1~=nC2)
        fprintf('In be_main :\tChannels definition does not match data size.\n');
        FLAG = 1;
    end 

    % ==== Check headmodel Definition
    nC1     =   size(HeadModel.Gain,1);
    nC2     =   size(OPTIONS.mandatory.Data,1);
    if (nC1~=nC2)
        fprintf('In be_main :\tGain matrix definition does not match data size.\n');
        FLAG = 1;
    end 

    % ==== Check manual clustering
    if isfield(OPTIONS.optional, 'clustering') && isfield(OPTIONS.optional.clustering, 'clusters') && ~isempty(OPTIONS.optional.clustering.clusters) 
        [FLAG, OPTIONS] = be_check_clustering(OPTIONS, HeadModel);    
    end


    % ==== Check if DATA is compatible with rMEM pipeline
    isRF = strcmpi(OPTIONS.mandatory.pipeline, 'rMEM');
    if isRF
        OPTIONS  = be_check_data_pipeline(OPTIONS);   
    end

    % Check time and baseline defintions
    [OPTIONS, FLAG_time]  = be_check_timedef(OPTIONS, isRF);
    FLAG = FLAG || FLAG_time;

    % Check additional options for rMEM
    if isRF 
        if isempty(MEMoptions.ridges.frequency_range) || isempty(MEMoptions.ridges.min_duration)
            FLAG = 1;
	        fprintf('\n\nIn be_main :\trMEMoptions are incomplete.\n\t\tFill OPTIONS.ridges.frequency_range and OPTIONS.ridges.min_duration\n\n');
        end
    end
            
end