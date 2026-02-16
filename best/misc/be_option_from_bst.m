function MEMoptions = be_option_from_bst(OPTIONS)

    Def_OPTIONS = be_main();

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
    MEMoptions.automatic.GoodChannel                    =   OPTIONS.GoodChannel;
    MEMoptions.automatic.iProtocol                      =   bst_get('ProtocolInfo');
    MEMoptions.automatic.Comment                        =   OPTIONS.Comment;
    MEMoptions.automatic.iStudy                         =   be_get_id( MEMoptions );
    [~, MEMoptions.automatic.iItem]                     =   be_get_id( MEMoptions );
    MEMoptions.automatic.DataInfo                       =   load( be_fullfile(MEMoptions.automatic.iProtocol.STUDIES, OPTIONS.DataFile) );
    
    % Noise covariance
    if OPTIONS.MEMpaneloptions.solver.NoiseCov_recompute
        MEMoptions.solver.NoiseCov = []; 
    else
        if isfield(OPTIONS, 'NoiseCov') && ~isempty(OPTIONS.NoiseCov)
            MEMoptions.solver.NoiseCov                    	=   OPTIONS.NoiseCov;
        elseif isfield(OPTIONS, 'NoiseCovMat')  && isfield(OPTIONS.NoiseCovMat, 'NoiseCov') && ~isempty(OPTIONS.NoiseCovMat.NoiseCov)
            MEMoptions.solver.NoiseCov                      =   OPTIONS.NoiseCovMat.NoiseCov;
        else
            error('MEM: Cannot find noise covariance matrix in the OPTIONS');
        end
    end


end