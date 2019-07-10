function DEF = be_cmem_pipelineoptions()

        % clustering
        DEF.clustering.clusters_type         = 'static';
        DEF.clustering.MSP_window            = 1;
        DEF.clustering.MSP_scores_threshold  = 0.0;
        DEF.model.alpha_threshold            = 0.0;
        DEF.model.active_mean_method         = 2;
        
        % automatic 
        DEF.automatic.selected_samples       = [];
        
        % optional
        DEF.optional.Comment                 = 'cMEM : MEG';
        DEF.optional.normalization           = 'adaptive'; 

return