function [OPTIONS, FLAG] = be_initialize_options(OPTIONS)
% be_initialize_options Copy default options to OPTIONS structure (do not replace defined values)

    FLAG            = 0;

    % ==== Copy default options to OPTIONS structure (do not replace defined values)
    [stand_alone, process] = be_check_caller();
    if isfield(OPTIONS, 'MEMpaneloptions') && ~isempty(OPTIONS.MEMpaneloptions)
        OPTIONS = be_option_from_bst(OPTIONS);
    end

    DefaultOptions  = be_main(OPTIONS.mandatory.pipeline, OPTIONS.mandatory.DataTypes);
    OPTIONS         = be_struct_copy_fields(OPTIONS, DefaultOptions , [] , 0);

    if OPTIONS.optional.verbose
        fprintf('\n\n===== pipeline %s\n', OPTIONS.mandatory.pipeline);
    end      

    % Complete automatic options
    OPTIONS.automatic.stand_alone    = stand_alone;
    OPTIONS.automatic.process        = process;
    OPTIONS.automatic.sampling_rate  = round( 1 / diff( OPTIONS.mandatory.DataTime([1 2]) ) );

    % Initialize comment
    if isfield(OPTIONS.optional , 'Comment') && ~isempty(OPTIONS.optional.Comment)
        OPTIONS.automatic.Comment       =   OPTIONS.optional.Comment;
    else
        OPTIONS.automatic.Comment = 'MEM';
    end

    if length(OPTIONS.automatic.Comment) >= 3 && strcmpi(OPTIONS.automatic.Comment(1:3), 'MEM')
        OPTIONS.automatic.Comment   =   sprintf('%s%s%s', lower(OPTIONS.mandatory.pipeline(1)), ...
                                                           upper(OPTIONS.mandatory.pipeline(2:end)),...
                                                           OPTIONS.optional.Comment(4:end));
    end


    % Initialize time vector
    if isempty(OPTIONS.optional.TimeSegment)
        OPTIONS.optional.TimeSegment    =   OPTIONS.mandatory.DataTime([1 end]);
    end
    OPTIONS.optional.TimeSegment        =   be_closest( OPTIONS.optional.TimeSegment([1 end]), OPTIONS.mandatory.DataTime );
    OPTIONS.optional.TimeSegment        =   OPTIONS.mandatory.DataTime(OPTIONS.optional.TimeSegment(1):OPTIONS.optional.TimeSegment(end));
    
    % Noise covariance
    if OPTIONS.solver.NoiseCov_recompute
        OPTIONS.solver.NoiseCov = []; 
    end

    % Initlailize baseline
    OPTIONS.automatic.BaselineType  =   'independant';
    if isempty(OPTIONS.optional.Baseline) % within-file
        OPTIONS.optional.BaselineTime   =   OPTIONS.mandatory.DataTime;
        OPTIONS.optional.Baseline       =   OPTIONS.mandatory.Data;
        OPTIONS.optional.BaselineChannels = OPTIONS.optional.Channel;
        OPTIONS.automatic.BaselineType  =   'within';
    elseif ~isempty(OPTIONS.optional.Baseline) && ischar(OPTIONS.optional.Baseline) % from brainstorm -- to be removed
            OPTIONS.optional.BaselineTime    = getfield(load(OPTIONS.optional.Baseline, 'Time'), 'Time');
            OPTIONS.optional.Baseline        = getfield(load(OPTIONS.optional.Baseline, 'F'), 'F');
            OPTIONS.optional.BaselineChannels = load(OPTIONS.optional.BaselineChannels);
    end

    % Cut the baseline based on BaselineSegment
    if isempty(OPTIONS.optional.BaselineSegment)
        OPTIONS.optional.BaselineSegment    = OPTIONS.optional.BaselineTime;
        STb     = 1;
        NDb     = size(OPTIONS.optional.Baseline,2);
    else
        STb     = be_closest( OPTIONS.optional.BaselineSegment(1), OPTIONS.optional.BaselineTime );
        NDb     = be_closest( OPTIONS.optional.BaselineSegment(end), OPTIONS.optional.BaselineTime );
    end
    OPTIONS.optional.Baseline           = OPTIONS.optional.Baseline(:, STb:NDb);
    OPTIONS.optional.BaselineTime       = OPTIONS.optional.BaselineTime(STb : NDb);


    % Extract channels name from channel matrix
    if isfield(OPTIONS.optional, 'Channel') && isstruct(OPTIONS.optional.Channel) && ~isempty(OPTIONS.optional.BaselineChannels) && isfield(OPTIONS.optional.Channel(1), 'Name')
        OPTIONS.optional.Channel = {OPTIONS.optional.Channel.Name};
    end


    if isfield(OPTIONS.optional, 'BaselineChannels') && isstruct(OPTIONS.optional.BaselineChannels) && ~isempty(OPTIONS.optional.BaselineChannels) && isfield(OPTIONS.optional.BaselineChannels(1), 'Name')
        OPTIONS.optional.BaselineChannels = {OPTIONS.optional.BaselineChannels.Name}; 
    end

    % Reorder Baseline channels
    CH = 1 : size(OPTIONS.mandatory.Data,1);
    if isfield(OPTIONS.optional, 'BaselineChannels') && ~isempty(OPTIONS.optional.BaselineChannels)
        CH = nan(1, size( OPTIONS.mandatory.Data, 1 ));
        for iChannel = 1 : size( OPTIONS.mandatory.Data, 1 )
            iD  = strcmp(OPTIONS.optional.BaselineChannels, OPTIONS.optional.Channel{iChannel});
            if any(iD)
                CH(iChannel) = find(iD); 
            end
        end
    end
    
    if any(isnan(CH))
        error('Some channels were not found for the baseline: %s', strjoin(OPTIONS.optional.Channel(isnan(CH)), ', '));
    end

    OPTIONS.optional.Baseline           = OPTIONS.optional.Baseline(CH, :);
    OPTIONS.optional.BaselineChannels   = OPTIONS.optional.BaselineChannels(CH);


    % Initialize channel flag
    if isfield(OPTIONS.optional, 'ChannelFlag') && length(OPTIONS.optional.ChannelFlag) == size(OPTIONS.mandatory.Data, 1)      
        OPTIONS.automatic.GoodChannel = find(OPTIONS.optional.ChannelFlag);
    end
    

    % Load empty room recording
    % Check emptyroom data
    if ~isempty( OPTIONS.optional.EmptyRoom_data )
        ERch    =   OPTIONS.optional.EmptyRoom_channels;
        MNch    =   OPTIONS.optional.Channel;
        if isempty(ERch) && numel(MNch)==size(OPTIONS.optional.EmptyRoom_data,1)
            % same channels as data, assume same order
            OPTIONS.automatic.Emptyroom_data	= OPTIONS.optional.EmptyRoom_data; 
            
        elseif ~isempty(ERch)
            nERD    =   zeros( size(OPTIONS.mandatory.Data,1), size(OPTIONS.optional.EmptyRoom_data,2) );
            nFound  =   [];
            
            % assume only MEG has empty room data
            iMod    =   find(strcmp(OPTIONS.mandatory.ChannelTypes, 'MEG'));
            
            for ii  =   1 : numel(ERch)
                idE     =   find(strcmp(MNch, ERch{ii}));
                if ~isempty(idE)
                    nFound  =   [nFound ii]; 
                    nERD( idE,: )  =   OPTIONS.optional.EmptyRoom_data(ii,:);
                end
            end
            
            if nFound~=numel(iMod)
                FLAG = 1;
                fprintf('\nBEst error:\tInconsistent channels for emptyroom and data');         
            end
            OPTIONS.automatic.Emptyroom_data    =   nERD;            
                   
        else
            FLAG = 1;
            fprintf('\nBEst error:\tNo channels for emptyroom data');
            
        end
    end
        
    if isfield(OPTIONS.automatic, 'Emptyroom_data')
        OPTIONS.automatic.Emptyroom_time    =   (0:size(OPTIONS.automatic.Emptyroom_data,2)-1)/OPTIONS.automatic.sampling_rate;
    end 



end
