function MEMoptions = be_initialize_options(OPTIONS)
% be_initialize_options Copy default options to OPTIONS structure (do not replace defined values)

    Def_OPTIONS     = be_main(); 

    % ==== Copy default options to OPTIONS structure (do not replace defined values)
    [stand_alone, process] = be_check_caller();
    if ~stand_alone && isfield( OPTIONS, 'MEMpaneloptions' )
        MEMoptions = be_option_from_bst(OPTIONS);
    else
        MEMoptions = be_struct_copy_fields( OPTIONS, Def_OPTIONS, [] );
    end


    MEMoptions.automatic.stand_alone    = stand_alone;
    MEMoptions.automatic.process        = process;

    MEMoptions  = be_check_data_pipeline( MEMoptions );   

end